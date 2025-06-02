from confluent_kafka import Producer
import sys

def delivery_report(err, msg):
    if err is not None:
        print(f'Message delivery failed: {err}')
    else:
        print(f'Message delivered to {msg.topic()} [{msg.partition()}] at offset {msg.offset()}')

def main():
    if len(sys.argv) != 4:
        print("Usage: python send_ids_to_kafka.py <kafka_endpoint> <start_id> <end_id>")
        sys.exit(1)
    
    kafka_endpoint = sys.argv[1]  # Get from terraform output
    start_id = int(sys.argv[2])
    end_id = int(sys.argv[3])
    
    # Configure Kafka producer
    producer = Producer({
        'bootstrap.servers': kafka_endpoint,
        'client.id': 'id_sender_script'
    })
    
    print(f"Sending IDs {start_id} to {end_id} to Kafka at {kafka_endpoint}")
    
    # Send each ID as a message
    for id_num in range(start_id, end_id + 1):
        id_str = str(id_num)
        producer.produce('ids_processo', key=id_str, value=id_str, callback=delivery_report)
        if id_num % 100 == 0:  # Flush every 100 messages
            producer.flush()
            print(f"Sent {id_num - start_id + 1} of {end_id - start_id + 1} messages")
    
    # Flush any remaining messages
    producer.flush()
    print("All messages sent to Kafka")

if __name__ == "__main__":
    main()
