from bs4 import BeautifulSoup
import pathlib
import json

def coletar_andamentos(html_source):
    """
    Coleta informações dos andamentos a partir do código fonte HTML.

    Args:
        html_source (str): String contendo o código fonte HTML da requisição.

    Returns:
        dict: Dicionário estruturado com os andamentos.
    """
    soup = BeautifulSoup(html_source, 'html.parser')
    andamentos_div = soup.find('div', class_='processo-andamentos')
    
    if not andamentos_div:
        return {"andamentos": []}
    
    andamentos_list = []
    lis = andamentos_div.find_all('li')
    
    for li in lis:
        andamento = {}
        detalhe = li.find('div', class_='andamento-detalhe')
        
        if detalhe:
            # Extrai a data
            data_div = detalhe.find('div', class_='andamento-data')
            andamento['data'] = data_div.get_text(strip=True) if data_div else None
            
            # Extrai o nome do andamento
            nome_h5 = detalhe.find('h5', class_='andamento-nome')
            andamento['nome'] = nome_h5.get_text(strip=True) if nome_h5 else None
            
            # Extrai documentos, se houver
            docs_div = detalhe.find('div', class_='andamento-docs')
            if docs_div:
                links = docs_div.find_all('a')
                docs = [a['href'] for a in links if a.has_attr('href')]
                andamento['docs'] = docs
            else:
                andamento['docs'] = []
            
            # Extrai o órgão (ministro, turma, plenário)
            orgao_span = detalhe.find('span', class_='andamento-julgador')
            andamento['orgao'] = orgao_span.get_text(strip=True) if orgao_span else None
            
            # Extrai informações adicionais
            extra_divs = detalhe.find_all('div', class_='col-md-9 p-0')
            extras = [div.get_text(strip=True) for div in extra_divs]
            andamento['informacoes_adicionais'] = extras if extras else []
        
        andamentos_list.append(andamento)
    
    return {"andamentos": andamentos_list}

# Exemplo de uso
if __name__ == "__main__":
    andamentos_path = pathlib.Path.cwd() / 'paginas_html' / 'adpf54'
    with open(andamentos_path / 'andamentos.html', 'r') as f:
        html_exemplo = f.read()
    
    resultado = coletar_andamentos(html_exemplo)
    with open('scrapping_codes/andamentos.json', 'w') as f:
        json.dump(resultado, f, indent=4)
