from bs4 import BeautifulSoup
import pathlib
import json

def coletar_recursos(html_source):
    """
    Coleta informações dos recursos de um processo.

    Args:
        html_source (str): String contendo o código fonte HTML da página de recursos.

    Returns:
        dict: Dicionário estruturado com os recursos do processo.
    """
    soup = BeautifulSoup(html_source, 'html.parser')
    recursos_divs = soup.find_all('div', class_='col-md-12 lista-dados')
    
    if not recursos_divs:
        return {"recursos": []}
    
    recursos_list = []
    
    for div in recursos_divs:
        recurso = {}
        
        # Coleta o nome ou título do recurso
        recurso_span = div.find('span', class_='processo-detalhes-bold')
        recurso['titulo'] = recurso_span.get_text(strip=True) if recurso_span else None
        
        recursos_list.append(recurso)
    
    return {"recursos": recursos_list}

if __name__ == '__main__':
    recursos_path = pathlib.Path.cwd() / 'paginas_html' / 'adpf54'
    with open(recursos_path / 'recursos.html', 'r') as f:
        html_source = f.read()
    
    recursos = coletar_recursos(html_source)
    with open('scrapping_codes/recursos.json', 'w') as f:
        json.dump(recursos, f, indent=4)