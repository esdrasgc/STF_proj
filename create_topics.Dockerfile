FROM python:3.12.3-slim

WORKDIR /app

# Copie o arquivo de requisitos e o script de criação de tópicos
COPY create_topics.py /app/

# Instale as dependências
RUN pip install confluent-kafka

# Execute o script
CMD ["python", "create_topics.py"]
