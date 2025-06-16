#!/bin/bash
# Este script é executado na primeira inicialização da instância Kafka.

# --- 1. Instalação de Dependências ---
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

yum install -y python3-pip python3-devel gcc git
pip3 install docker-compose confluent-kafka

# --- 2. Configuração e Inicialização do Kafka via Docker Compose ---
# Obtém o IP privado da instância, que será anunciado pelo Kafka.
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Cria o arquivo docker-compose.yml dinamicamente.
cat << EOF > /home/ec2-user/docker-compose.yml
version: '2'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.3.0
    container_name: zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
  kafka:
    image: confluentinc/cp-kafka:7.3.0
    container_name: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://${PRIVATE_IP}:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "false" # Importante para criarmos os tópicos via script
EOF

chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml
cd /home/ec2-user
docker-compose up -d

# --- 3. Criação dos Tópicos Kafka ---
# Espera o Kafka ficar disponível na rede do docker.
echo "Waiting for Kafka to be ready..."
sleep 30 # Uma espera simples. Uma solução mais robusta faria um loop de verificação.

# Cria o script Python para criar os tópicos
cat << EOF_PYTHON > /home/ec2-user/create_topics.py
from confluent_kafka.admin import AdminClient, NewTopic
import time

def create_topics_with_retry(admin_client, topics, retries=5, delay=15):
    """Tenta criar tópicos com retentativas."""
    for i in range(retries):
        future = admin_client.create_topics(topics)
        all_succeeded = True
        for topic, f in future.items():
            try:
                f.result(timeout=10)
                print(f"Topic '{topic}' created successfully.")
            except Exception as e:
                # Se o tópico já existe, consideramos um sucesso.
                if 'TOPIC_ALREADY_EXISTS' in str(e):
                    print(f"Topic '{topic}' already exists.")
                else:
                    print(f"Failed to create topic '{topic}' on attempt {i+1}: {e}")
                    all_succeeded = False
        
        if all_succeeded:
            print("All topics are ready.")
            return
        
        print(f"Some topics failed to create. Retrying in {delay} seconds...")
        time.sleep(delay)

# O script roda dentro da instância, então 'localhost' aponta para o contêiner Kafka.
admin_client = AdminClient({"bootstrap.servers": "localhost:9092"})

topics_to_create = [
    NewTopic("ids_processo", num_particoes=1, fator_replicacao=1),
    NewTopic("abas", num_particoes=5, fator_replicacao=1)
]

create_topics_with_retry(admin_client, topics_to_create)
EOF_PYTHON

# Executa o script de criação de tópicos
python3 /home/ec2-user/create_topics.py
