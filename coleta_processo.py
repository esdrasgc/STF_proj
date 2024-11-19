from confluent_kafka import Consumer, Producer
from bs4 import BeautifulSoup
import json
import requests
from requests import Response
from fake_useragent import UserAgent
from connect_mongo import MongoDBDatabase
import time
import os
from requests.exceptions import RequestException
# from dotenv import load_dotenv

# load_dotenv()

class ConsumerIds:
    consumer = None
    topic = 'ids_processo'
    config = {
        'bootstrap.servers': f'{os.getenv('KAFKA_BROKER_HOST')}:{os.getenv('KAFKA_BROKER_PORT')}',
        'group.id': 'coleta_processos',
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
    

def coletar_central(html_source):
    """
    Coleta informações centrais do processo da página principal.

    Args:
        html_source (str): String contendo o código fonte HTML da página principal.

    Returns:
        dict: Dicionário estruturado com as informações centrais do processo.
    """
    soup = BeautifulSoup(html_source, 'html.parser')
    central_info = {}

    # Coletar a classe do processo (ADPF 54)
    classe_numero = soup.find('input', {'id': 'classe-numero-processo'})
    if classe_numero['value'].strip() != '':
        central_info['classe_numero'] = classe_numero['value']
    else:
        return None
    
    # Coletar badges (Processo Físico, Público, Medida Liminar)
    badges = soup.find_all('span', class_='badge')
    central_info['badges'] = [badge.get_text(strip=True) for badge in badges]
    
    # Coletar número único do processo
    numero_unico_div = soup.find('div', class_='processo-rotulo')
    central_info['numero_unico'] = numero_unico_div.get_text(strip=True) if numero_unico_div else None
    
    # Coletar o título da classe processual (Arguição de Descumprimento de Preceito Fundamental)
    classe_processo_div = soup.find('div', class_='processo-classe')
    central_info['classe_processo'] = classe_processo_div.get_text(strip=True) if classe_processo_div else None
    
    # Coletar o relator do processo
    processo_dados_divs = soup.find_all('div', class_='processo-dados')
    for div in processo_dados_divs:
        if 'Relator' in div.get_text(strip=True):
            if 'incidente' in div.get_text(strip=True):
                central_info['relator_ultimo_incidente'] = div.get_text(strip=True).split(':')[-1].strip()
            else:
                central_info['relator'] = div.get_text(strip=True).split(':')[-1].strip()
        elif 'Apenso' in div.get_text(strip=True):
            central_info['apenso'] = div.find('a')['href']
        elif 'Apensado' in div.get_text(strip=True):
            central_info['processo_apensado'] = div.find('a')['href']
        elif 'Redator' in div.get_text(strip=True):
            central_info['redator'] = div.get_text(strip=True).split(':')[-1].strip()
        elif 'Origem:' in div.get_text(strip=True):
            continue
        else:
            raise ValueError(f'Chave não mapeada: {div.get_text(strip=True)}')

    return central_info


def produzir_msgs_abas(id): 
    producer = ProducerKafka.get_producer()
    topic = 'abas'
    id = str(id)
    producer.produce(topic, 'andamentos', id)
    producer.produce(topic, 'deslocamentos', id)
    producer.produce(topic, 'info', id)
    producer.produce(topic, 'partes',  id)
    producer.produce(topic, 'recursos', id)
    producer.produce(topic, 'sessao', id)
    producer.flush()


def processar_mensagem(msg):
    id = msg.key().decode('utf-8')
    url = f'https://portal.stf.jus.br/processos/verImpressao.asp?imprimir=true&incidente={id}'
    session = requests.Session()
    realizando_request = True
    while realizando_request:
        try:
            response = session.get(url, headers={"User-Agent": str(FakeUserAgent.get_ua().random)}, timeout=13)
            realizando_request = False
        except RequestException as e:
            print(f'Falha {e} para o incidente {id}. Tentando novamente em 5 segundos...')
            time.sleep(5)
            realizando_request = True
    producer = ProducerKafka.get_producer()
    if response.status_code != 200:
        producer.produce('ids_processo', None, str(id))
        producer.flush()
        print(f"Status code {response.status_code} para o incidente {id}")
        time.sleep(60)
    else:
        response.encoding = 'utf-8'
        central_info = coletar_central(response.text)
        if central_info is None:
            print(f'Id invalido {id}')
            return
        produzir_msgs_abas(id)
        salvar_processo_mongo(central_info, id)


def salvar_processo_mongo(processo, id):
    db = MongoDBDatabase.get_db()
    colecao = db.processos
    processo['id_incidente'] = int(id)
    colecao.insert_one(processo)
    colecao = db.processos_unificados
    colecao.insert_one(processo)

def main():
    print("Iniciando o worker...")
    consumer = ConsumerIds.get_consumer()
    print("Consumidor iniciado...")
    while True:
        msg = consumer.poll(0.5)
        if msg is None:
            print("Em espera...")
        elif msg.error():
            print("ERROR: %s".format(msg.error()))
        else:
            print(msg.key().decode('utf-8'))
            processar_mensagem(msg)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("Encerrando o worker...")
    finally:
        # Fecha o consumer e o producer ao finalizar
        ConsumerIds.close_consumer()
        ProducerKafka.get_producer().flush()
        