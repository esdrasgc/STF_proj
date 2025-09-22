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
COPY celery_app.py .
COPY rate_limiter.py /app/
COPY config_rate_limit.py /app/

# Exponha a porta que o FastAPI usará
EXPOSE 8000

# Comando para iniciar a aplicação FastAPI
CMD ["uvicorn", "coletor_range_ids:app", "--host", "0.0.0.0", "--port", "8000"]
