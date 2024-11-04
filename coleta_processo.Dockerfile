# Use uma imagem base com Python
FROM python:3.12.3

WORKDIR /app

# Copie o arquivo de dependências
COPY requirements.txt /app/

# Instale as dependências
RUN pip install -r requirements.txt

# Copie os arquivos necessários para o contêiner
COPY scrapping_codes /app/scrapping_codes
COPY coleta_processo.py /app/
COPY connect_mongo.py /app/

# Execute o script
CMD ["python", "coleta_processo.py"]
