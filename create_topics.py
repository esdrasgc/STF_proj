from confluent_kafka.admin import AdminClient, NewTopic
import os

def criar_topico(topico_nome, num_particoes, fator_replicacao):
    # Configura o cliente de administração
    admin_client = AdminClient({
        "bootstrap.servers": f"{os.getenv('KAFKA_BROKER_HOST')}:{os.getenv('KAFKA_BROKER_PORT')}"  # substitua pelo seu servidor Kafka
    })
    
    # Define o novo tópico
    topico = NewTopic(topico_nome, num_particoes, fator_replicacao)
    
    # Tenta criar o tópico
    future = admin_client.create_topics([topico])

    # Verifica o resultado da criação do tópico
    for topico, f in future.items():
        try:
            f.result()  # Se não houver exceções, o tópico foi criado
            print(f"Tópico '{topico}' criado com sucesso.")
        except Exception as e:
            print(f"Falha ao criar o tópico '{topico}': {e}")

# Exemplo de uso
criar_topico("ids_processo", num_particoes=1, fator_replicacao=1)
criar_topico("abas", num_particoes=5, fator_replicacao=1)