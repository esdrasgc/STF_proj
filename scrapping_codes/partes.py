from bs4 import BeautifulSoup
import pathlib
import json

def coletar_partes(html_source):
    """
    Coleta informações das partes de um processo a partir do código fonte HTML.

    Args:
        html_source (str): String contendo o código fonte HTML da página de partes.

    Returns:
        dict: Dicionário estruturado com as partes envolvidas no processo.
    """
    soup = BeautifulSoup(html_source, 'html.parser')
    partes_div = soup.find('div', id='todas-partes')
    
    if not partes_div:
        return {"partes": []}
    
    partes_list = []
    divs_partes = partes_div.select('div.processo-partes.lista-dados')
    
    for div in divs_partes:
        parte = {}
        # Extrai o tipo de parte (ex: REQTE, ADV, INTDO)
        tipo_parte_div = div.find('div', class_='detalhe-parte')
        parte['tipo'] = tipo_parte_div.get_text(strip=True) if tipo_parte_div else None
        
        # Extrai o nome da parte
        nome_parte_div = div.find('div', class_='nome-parte')
        parte['nome'] = nome_parte_div.get_text(strip=True) if nome_parte_div else None
        
        partes_list.append(parte)
    
    return {"partes": partes_list}

# Exemplo de uso
if __name__ == "__main__":
    andamentos_path = pathlib.Path.cwd() / 'paginas_html' / 'adpf54'
    with open(andamentos_path / 'partes.html', 'r') as f:
        html_exemplo = f.read()
    
    resultado = coletar_partes(html_exemplo)
    with open('scrapping_codes/partes.json', 'w') as f:
        json.dump(resultado, f, indent=4)
