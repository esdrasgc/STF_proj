from bs4 import BeautifulSoup
import pathlib
import json
import requests
from fake_useragent import UserAgent


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
        elif 'Redator' in div.get_text(strip=True):
            central_info['redator'] = div.get_text(strip=True).split(':')[-1].strip()
        elif 'Origem:' in div.get_text(strip=True):
            continue
        else:
            raise ValueError(f'Chave não mapeada: {div.get_text(strip=True)}')

    return central_info

if __name__ == '__main__':
    url = 'https://portal.stf.jus.br/processos/verImpressao.asp?imprimir=true&incidente=2226954'
    ua = UserAgent()
    session = requests.Session()
    response = session.get(url, headers={"User-Agent": str(ua.random)})
    response.encoding = 'utf-8'
    central_info = coletar_central(response.text)
    print(json.dumps(central_info, indent=4, ensure_ascii=False))