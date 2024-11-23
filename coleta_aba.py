from confluent_kafka import Consumer, Producer
import requests
from fake_useragent import UserAgent
from scrapping_codes.andamentos import coletar_andamentos
from scrapping_codes.deslocamentos import coletar_deslocamentos
from scrapping_codes.informacoes import coletar_informacoes
from scrapping_codes.partes import coletar_partes
from scrapping_codes.recursos import coletar_recursos
from scrapping_codes.sessao import coletar_sessao_virtual

from requests.exceptions import RequestException
import os
import time
from connect_mongo import MongoDBDatabase

import logging

logger = logging.getLogger(__name__)

class ProducerKafka:
    producer = None
    config = {
        'bootstrap.servers': f"{os.getenv('KAFKA_BROKER_HOST')}:{os.getenv('KAFKA_BROKER_PORT')}",
        'acks': '1'
    }

    @classmethod
    def init_producer(cls):
        cls.producer = Producer(cls.config)
        return cls.producer
    
    @classmethod
    def get_producer(cls):
        if cls.producer is None:
            cls.init_producer()
        return cls.producer

class ConsumerAbas:
    consumer = None
    topic = 'abas'
    config = {
        'bootstrap.servers': f"{os.getenv('KAFKA_BROKER_HOST')}:{os.getenv('KAFKA_BROKER_PORT')}",
        'group.id': 'coleta_abas',
        'auto.offset.reset': 'earliest'
    }

    @classmethod
    def init_consumer(cls):
        cls.consumer = Consumer(cls.config)
        cls.consumer.subscribe([cls.topic])
        return cls.consumer
    
    @classmethod
    def get_consumer(cls):
        if cls.consumer is None:
            cls.init_consumer()
        return cls.consumer
    
    @classmethod
    def close_consumer(cls):
        if cls.close_consumer is not None:
            cls.consumer.close()
            cls.consumer = None  

class FakeUserAgent:
    ua = None
    session = None

    @classmethod
    def init_ua(cls):
        cls.ua = UserAgent()
        return cls.ua

    @classmethod
    def get_ua(cls):
        if cls.ua is None:
            cls.init_ua()
        return cls.ua

aba_2_url_dict = {
    'andamentos' : 'https://portal.stf.jus.br/processos/abaAndamentos.asp?imprimir=&incidente=',
    'deslocamentos' : 'https://portal.stf.jus.br/processos/abaDeslocamentos.asp?incidente=',
    'info' : 'https://portal.stf.jus.br/processos/abaInformacoes.asp?incidente=',
    'partes' : "https://portal.stf.jus.br/processos/abaPartes.asp?incidente=",
    'recursos' : 'https://portal.stf.jus.br/processos/abaRecursos.asp?incidente=',
    'sessao' : 'https://sistemas.stf.jus.br/repgeral/votacao?oi='
}

def salvar_dados_mongo(dados, id, colecao):
    # Obtém a coleção
    col = MongoDBDatabase.get_db()[colecao]
    registro = list(dados.values())[0]
    # registro['id_incidente'] = int(id) 
    # Insere os dados no MongoDB
    col.insert_one({'id_incidente': int(id), 'dados' : registro})
    processos_unificado = MongoDBDatabase.get_db().processos_unificados
    processos_unificado.update_one({'id_incidente': int(id)}, {'$set': dados})

def processar_sessao_virtual_e_salvar(info_sessoes_virtuais, sessao_virtual_id):
    logger.info(f"Aba: sessao_virtual")
    lista_sessoes_virtuais = []
    for sessao_virtual in info_sessoes_virtuais:
        resultado_sessao_virtual = coletar_sessao_virtual(sessao_virtual["objetoIncidente"]['id'])
        dict_sessao = sessao_virtual | resultado_sessao_virtual
        dict_sessao['id'] = sessao_virtual["objetoIncidente"]['id']
        lista_sessoes_virtuais.append(dict_sessao)
    salvar_dados_mongo({'sessoes_virtuais': lista_sessoes_virtuais}, sessao_virtual_id, 'sessao')
    

def processar_html_aba_e_salvar(html, id, tipo_aba):
    logger.info(f"Aba: {tipo_aba}")
    if tipo_aba == 'andamentos':
        dados = coletar_andamentos(html)
    elif tipo_aba == 'deslocamentos':
        dados = coletar_deslocamentos(html)
    elif tipo_aba == 'info':
        dados = coletar_informacoes(html)
    elif tipo_aba == 'partes':
        dados = coletar_partes(html)
    elif tipo_aba == 'recursos':
        dados = coletar_recursos(html)
    else: 
        raise ValueError(f"Tipo de aba desconhecido: {tipo_aba}")
    salvar_dados_mongo(dados, id, tipo_aba)

def processar_mensagem_aba(msg):
    # Obtém o incidente do processo
    incidente = msg.key().decode('utf-8')
    
    # Obtém o valor da mensagem
    msg_value = msg.value().decode('utf-8')
    
    # Obtém a URL da aba
    url = aba_2_url_dict[msg_value]
    
    # Realiza a requisição HTTP
    session = requests.Session()
    realizando_request = True
    while realizando_request:
        try:
            response = session.get(url + incidente, headers={"User-Agent": str(FakeUserAgent.get_ua().random)}, timeout=13)
            realizando_request = False
        except RequestException as e:
            logger.warning(f'Falha {e} para o incidente {incidente}. Tentando novamente em 5 segundos...')
            time.sleep(5)
            realizando_request = True
    
    # Verifica se a requisição foi bem-sucedida
    if response.status_code == 200:
        response.encoding = 'utf-8'
        if msg_value == 'sessao':
            processar_sessao_virtual_e_salvar(response.json(), incidente)
        else:
            if len(response.text) > 0:
                processar_html_aba_e_salvar(response.text, incidente, msg_value)

    else:
        if response.status_code == 404 and msg_value == 'sessao':
            return
        logger.info(f"Status code {response.status_code} para o incidente {incidente} e a aba {msg_value}")
        ProducerKafka.get_producer().produce('abas', msg_value, incidente)
        ProducerKafka.get_producer().flush()
        time.sleep(60)

def main():
    consumer = ConsumerAbas.get_consumer()
    logger.info("Consumidor iniciado")
    while True:
        msg = consumer.poll(0.5)
        if msg is None:
            logger.info(".")
        elif msg.error():
            logger.error(f"{msg.error()}")
        else:
            logger.info(f"Processo: {msg.key().decode('utf-8')}")
            processar_mensagem_aba(msg)

if __name__ == '__main__':
    logging.basicConfig(filename='coleta_abas.log', encoding='utf-8', level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(funcName)s - %(message)s')
    try:
        logger.info("Iniciando o worker")
        main()
    except KeyboardInterrupt:
        logger.info("KeyboardInterrupt")
    finally:
        # Fecha o consumer e o producer ao finalizar
        logger.info("Encerrando o worker")
        ConsumerAbas.close_consumer()