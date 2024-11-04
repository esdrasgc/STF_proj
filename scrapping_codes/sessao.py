import requests
import json
import pathlib
import requests
from fake_useragent import UserAgent

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


def coletar_sessao_virtual(sessao_virtual_id):
    """
    Coleta informações das votações em uma sessão virtual a partir do ID ou de um JSON fornecido.

    Args:
        sessao_virtual_id (str, opcional): O ID da sessão virtual. Ignorado se `json_data` for fornecido.
        json_data (list, opcional): JSON fornecido diretamente, para evitar requisição HTTP.

    Returns:
        dict: Dicionário estruturado com as informações das votações na sessão virtual.
    """
    if sessao_virtual_id is not None:
        session = requests.Session()
        url = f"https://sistemas.stf.jus.br/repgeral/votacao?sessaoVirtual={sessao_virtual_id}"
        response = session.get(url, headers={"User-Agent": str(FakeUserAgent.get_ua().random)})
        
        if response.status_code != 200:
            return {"error": f"Erro ao acessar a URL: {url}"}
        
        response.encoding = 'utf-8'
        data = response.json()
    else:
        raise ValueError("O ID da sessão virtual deve ser fornecido.")
    
    resultado = []
    
    for item in data:
        objeto_incidente = item.get('objetoIncidente', {})
        listas_julgamento = item.get('listasJulgamento', [])
        sustentacoes_orais = item.get('sustentacoesOrais', [])
        
        votacao = {
            "identificacao": objeto_incidente.get('identificacaoCompleta'),
            "processo": objeto_incidente.get('identificacao'),
            "sustentacoes_orais": [
                {
                    "advogado": sust.get('pessoaRepresentante', {}).get('descricao'),
                    "parte": sust.get('pessoaRepresentada', {}).get('descricao'),
                    "link": sust.get('link')
                }
                for sust in sustentacoes_orais
            ],
            "listas_julgamento": []
        }
        
        for lista in listas_julgamento:
            lista_info = {
                "data_prevista_inicio": lista.get('sessao', {}).get('dataPrevistaInicio'),
                "relator": lista.get('ministroRelator', {}).get('descricao'),
                "orgao_julgador": lista.get('sessao', {}).get('colegiado', {}).get('descricao'),
                "nome_lista": lista.get('nomeLista'),
                "texto_decisao": lista.get('textoDecisao'),
                "votos": [
                    {
                        "ministro": voto.get('ministro', {}).get('descricao'),
                        "tipo_voto": voto.get('tipoVoto', {}).get('descricao'),
                        "voto_antecipado": voto.get('votoAntecipado'),
                        "acompanhando_ministro": voto.get('acompanhandoMinistro', {}).get('descricao') if voto.get('acompanhandoMinistro') else None,
                        "link_voto": [
                            {
                                "descricao": texto.get('descricao'),
                                "link": texto.get('link')
                            }
                            for texto in voto.get('textos', [])
                        ]
                    }
                    for voto in lista.get('votos', [])
                ]
            }
            votacao["listas_julgamento"].append(lista_info)
        
        resultado.append(votacao)

    return {"votacoes": resultado}

if __name__ == "__main__":
    ## coletar os ids de sessao virtual
    # Realiza a requisição HTTP
    incidente = '5651823'
    url = 'https://sistemas.stf.jus.br/repgeral/votacao?oi='
    session = requests.Session()
    response = session.get(url + incidente, headers={"User-Agent": str(FakeUserAgent.get_ua().random)})
    
    # Verifica se a requisição foi bem-sucedida
    if response.status_code == 200:
        response.encoding = 'utf-8'
        info_sessoes_virtuais = response.json()
    else:
        raise Exception(f"Status code {response.status_code} ao acessar a URL {url + incidente}")
    
    lista_sessoes_virtuais = []
    for sessao_virtual in info_sessoes_virtuais:
        resultado_sessao_virtual = coletar_sessao_virtual(sessao_virtual["objetoIncidente"]['id'])
        dict_sessao = sessao_virtual | resultado_sessao_virtual
        dict_sessao['id'] = sessao_virtual["objetoIncidente"]['id']
        dict_sessao['id_incidente'] = incidente
        lista_sessoes_virtuais.append(dict_sessao)

    # print(lista_sessoes_virtuais)
    with open('sessoes_virtuais.json', 'w') as f:
        json.dump(lista_sessoes_virtuais, f, indent=4)