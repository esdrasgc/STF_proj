from confluent_kafka import Consumer
import os
from dotenv import load_dotenv

load_dotenv()

class ConsumerIds:
    consumer = None
    topic = 'ids_processo'
    config = {
        'bootstrap.servers': f'{os.getenv('KAFKA_BROKER_HOST')}:{os.getenv('KAFKA_BROKER_PORT')}',
        'group.id': 'coleta_processos',
        'auto.offset.reset': 'earliest'
    }

    @classmethod
    def init_consumer(cls):
        cls.consumer = Consumer(cls.config)
        cls.consumer.subscribe([cls.topic])
        return cls.consumer
    
    @classmethod
    def get_consumer(cls):
        if cls.consumer is None:
            cls.init_consumer()
        return cls.consumer
    
    @classmethod
    def close_consumer(cls):
        if cls.close_consumer is not None:
            cls.consumer.close()
            cls.consumer = None     

if __name__ == '__main__':
    consumer = ConsumerIds.get_consumer()
    print("Iniciando o consumidor...")
    print(ConsumerIds.config)
    while True:
        try:
            print("Consumindo mensagens...")
            msg = consumer.poll(timeout=1.0)
            if msg is None:
                continue
            if msg.error():
                print(f"Consumer error: {msg.error()}")
                continue
            print(f"Consumed message: {msg.value().decode('utf-8')}")
        except KeyboardInterrupt:
            print("Encerrando o consumidor...")
            break