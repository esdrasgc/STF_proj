from celery_app import app
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
try:
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
except Exception:
    pass

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

@app.task(name='tasks_abas.processar', bind=True, autoretry_for=(RequestException,), retry_backoff=True, retry_jitter=True, retry_kwargs={'max_retries': 12})
def processar(self, id: str, aba: str):
    # Obtém a URL da aba
    url = aba_2_url_dict[aba]
    
    # Realiza a requisição HTTP
    session = requests.Session()
    realizando_request = True
    while realizando_request:
        try:
            response = session.get(
                url + id,
                headers={"User-Agent": str(FakeUserAgent.get_ua().random)},
                timeout=13,
                verify=False,
            )
            realizando_request = False
        except RequestException as e:
            logger.warning(f'Falha {e} para o incidente {id}. Tentando novamente em 5 segundos...')
            time.sleep(5)
            realizando_request = True
    
    # Verifica se a requisição foi bem-sucedida
    if response.status_code == 200:
        response.encoding = 'utf-8'
        if aba == 'sessao':
            processar_sessao_virtual_e_salvar(response.json(), id)
        else:
            if len(response.text) > 0:
                processar_html_aba_e_salvar(response.text, id, aba)

    else:
        if response.status_code == 404 and aba == 'sessao':
            return
        logger.info(f"Status code {response.status_code} para o incidente {id} e a aba {aba}")
        # Retry later due to possible temporary block
        raise self.retry(countdown=60)

if __name__ == '__main__':
    logging.basicConfig(filename='coleta_abas.log', encoding='utf-8', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(funcName)s - %(message)s')
    logger.info("Módulo de tarefas Celery carregado: tasks_abas.processar")