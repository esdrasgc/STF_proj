FROM python:3.12.3

WORKDIR /app

COPY requirements.txt /app/
RUN pip install -r requirements.txt

COPY scrapping_codes /app/scrapping_codes
COPY coleta_aba.py /app/
COPY connect_mongo.py /app/

CMD ["python", "coleta_aba.py"]
