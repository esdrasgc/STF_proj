from bs4 import BeautifulSoup
import pathlib
import json

def coletar_informacoes(html_source):
    """
    Coleta informações processuais da aba de informações de um processo.

    Args:
        html_source (str): String contendo o código fonte HTML da página de informações.

    Returns:
        dict: Dicionário estruturado com as informações do processo.
    """
    soup = BeautifulSoup(html_source, 'html.parser')
    informacoes_div = soup.find('div', id='informacoes-completas')
    
    if not informacoes_div:
        return {"informacoes": {}}
    
    informacoes = {}

    # Coleta o assunto do processo
    assunto_div = informacoes_div.find('div', class_='informacoes__assunto')
    if assunto_div:
        assunto_li = assunto_div.find('li')
        informacoes['assunto'] = assunto_li.get_text(strip=True) if assunto_li else None
    
    # Coleta os detalhes de procedência
    processo_div = informacoes_div.find('div', class_='processo-informacao__col')
    if processo_div:
        divs_chaves = processo_div.find_all('div', class_='col-md-7')
        divs_valores = processo_div.find_all('div', class_='col-md-5')
        for chave, valor in zip(divs_chaves, divs_valores):
            chave_text = chave.get_text(strip=True)
            valor_text = valor.get_text(strip=True)
            if chave_text == 'Data de Protocolo:':
                informacoes['data_protocolo'] = valor_text
            elif chave_text == 'Órgão de Origem:':
                informacoes['orgao_origem'] = valor_text
            elif chave_text == 'Origem:':
                informacoes['origem'] = valor_text
            elif chave_text == 'Número de Origem:':
                informacoes['numero_origem'] = valor_text
            else:
                informacoes[chave_text] = valor_text
                raise ValueError(f'Chave não mapeada: {chave_text}')
                # informacoes[chave_text] = valor_text
    
    # Coleta o número de volumes, folhas e apensos
    processo_quadro_divs = informacoes_div.find_all('div', class_='processo-quadro')
    for quadro in processo_quadro_divs:
        rotulo = quadro.find('div', class_='rotulo').get_text(strip=True)
        numero = quadro.find('div', class_='numero').get_text(strip=True)
        if rotulo == 'Volumes':
            informacoes['volumes'] = numero
        elif rotulo == 'Folhas':
            informacoes['folhas'] = numero
        elif rotulo == 'Apensos':
            informacoes['apensos'] = numero

    return {"informacoes": informacoes}

# Exemplo de uso
if __name__ == "__main__":
    andamentos_path = pathlib.Path.cwd() / 'paginas_html' #/ 'adpf54'
    with open(andamentos_path / 'info_test.html', 'r') as f:
        html_exemplo = f.read()
    
    resultado = coletar_informacoes(html_exemplo)
    with open('scrapping_codes/informacoes.json', 'w') as f:
        json.dump(resultado, f, indent=4)

