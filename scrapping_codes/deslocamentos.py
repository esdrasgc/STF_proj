from bs4 import BeautifulSoup
import pathlib
import json

def coletar_deslocamentos(html_source):
    """
    Coleta informações dos deslocamentos de um processo.

    Args:
        html_source (str): String contendo o código fonte HTML da página de deslocamentos.

    Returns:
        dict: Dicionário estruturado com os deslocamentos do processo.
    """
    soup = BeautifulSoup(html_source, 'html.parser')
    deslocamentos_divs = soup.find_all('div', class_='col-md-12 lista-dados p-r-0 p-l-0')
    
    if not deslocamentos_divs:
        return {"deslocamentos": []}
    
    deslocamentos_list = []
    
    for div in deslocamentos_divs:
        deslocamento = {}
        
        # Coleta a localização (destino do deslocamento)
        local_destino_span = div.find('span', class_='processo-detalhes-bold')
        deslocamento['destino'] = local_destino_span.get_text(strip=True) if local_destino_span else None
        
        # Coleta o remetente e data de envio
        detalhes_envio_span = div.find('span', class_='processo-detalhes')
        deslocamento['envio'] = detalhes_envio_span.get_text(strip=True) if detalhes_envio_span else None
        
        # Coleta o número da guia
        guia_span = div.find('span', class_='processo-detalhes', string=lambda x: 'Guia' in x)
        deslocamento['guia'] = guia_span.get_text(strip=True) if guia_span else None
        
        # Coleta o status de recebimento (se existir)
        recebido_span = div.find('span', class_='processo-detalhes bg-font-success')
        deslocamento['recebido'] = recebido_span.get_text(strip=True) if recebido_span else None
        
        deslocamentos_list.append(deslocamento)
    
    return {"deslocamentos": deslocamentos_list}

if __name__ == '__main__':
    deslocamentos_path = pathlib.Path.cwd() / 'paginas_html' / 'adi5389'
    with open(deslocamentos_path / 'deslocamentos.html', 'r') as f:
        html_source = f.read()
    
    deslocamentos = coletar_deslocamentos(html_source)
    with open('scrapping_codes/deslocamentos.json', 'w') as f:
        json.dump(deslocamentos, f, indent=4)