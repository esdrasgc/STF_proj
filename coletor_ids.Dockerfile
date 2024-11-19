# Use uma imagem base oficial do Python
FROM python:3.12.3-slim

# Defina o diretório de trabalho
WORKDIR /app

# Copie o arquivo de dependências para o contêiner
COPY requirements_coletor_ids.txt .

# Instale as dependências
RUN pip install --no-cache-dir -r requirements_coletor_ids.txt

# Copie o código da aplicação para o contêiner
COPY coletor_range_ids.py .

# Exponha a porta que o FastAPI usará
EXPOSE 8000

# Defina as variáveis de ambiente do Kafka (caso necessário)
ENV KAFKA_BROKER_HOST=kafka_broker
ENV KAFKA_BROKER_PORT=29092

# Comando para iniciar a aplicação FastAPI
CMD ["uvicorn", "coletor_range_ids:app", "--host", "0.0.0.0", "--port", "8000"]
