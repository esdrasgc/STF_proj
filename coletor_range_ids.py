from confluent_kafka import Producer
import os
# from dotenv import load_dotenv

# load_dotenv()

class ProducerKafka:
    producer = None
    config = {
        'bootstrap.servers': f"{os.getenv('KAFKA_BROKER_HOST')}:{os.getenv('KAFKA_BROKER_PORT')}",
        'acks': '1'
    }

    @classmethod
    def init_producer(cls):
        cls.producer = Producer(cls.config)
        return cls.producer
    
    @classmethod
    def get_producer(cls):
        if cls.producer is None:
            cls.init_producer()
        return cls.producer

def save_range_ids_to_topic(start_id, end_id):
    producer = ProducerKafka.get_producer()
    for i in range(start_id, end_id + 1):
        producer.produce('ids_processo', str(i), str(i))
        if i % 1000 == 0:
            producer.flush()
    producer.flush()

if __name__ == '__main__':
    print("Iniciando a produção de ids")
    start = 4853700
    save_range_ids_to_topic(start, start + 200)
    print("Finalizando a produção de ids")


