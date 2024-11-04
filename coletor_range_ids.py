from fastapi import FastAPI, Form, HTTPException
from fastapi.responses import HTMLResponse
from confluent_kafka import Producer
import os

app = FastAPI()

# Configuração e criação do produtor Kafka
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

# Função que envia o intervalo de IDs ao tópico
def save_range_ids_to_topic(start_id: int, end_id: int):
    producer = ProducerKafka.get_producer()
    for i in range(start_id, end_id + 1):
        producer.produce('ids_processo', str(i), str(i))
        if i % 1000 == 0:
            producer.flush()
    producer.flush()

# Rota GET para servir o HTML da interface
@app.get("/", response_class=HTMLResponse)
async def get_form():
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Ids incidentes</title>
    </head>
    <body>
        <h1>Selecione o intervalo de ids incidentes a serem pesquisados</h1>
        <form action="/produce" method="post">
            <label for="start_id">ID Inicial:</label><br>
            <input type="number" id="start_id" name="start_id" required><br><br>
            <label for="end_id">ID Final:</label><br>
            <input type="number" id="end_id" name="end_id" required><br><br>
            <input type="submit" value="Enviar para raspagem">
        </form>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)

# Rota POST para processar os IDs
@app.post("/produce")
async def produce_ids(start_id: int = Form(...), end_id: int = Form(...)):
    if start_id > end_id:
        raise HTTPException(status_code=400, detail="O ID inicial deve ser menor ou igual ao ID final.")
    
    save_range_ids_to_topic(start_id, end_id)
    # HTML de confirmação com botão para voltar
    html_response = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Produção de IDs</title>
    </head>
    <body>
        <h1>IDs incidentes {start_id} até {end_id} enviados para processo de raspagem!</h1>
        <button onclick="window.location.href='/'">Voltar</button>
    </body>
    </html>
    """
    return HTMLResponse(content=html_response)

# Para rodar o servidor, execute:
# uvicorn nome_do_arquivo:app --reload

if __name__ == "__main__":
    ProducerKafka.init_producer()
    import uvicorn
    uvicorn.run("coletor_range_ids:app", host="127.0.0.1", port=8000, reload=True)