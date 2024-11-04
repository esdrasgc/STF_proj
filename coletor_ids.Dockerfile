FROM python:3.12.3

WORKDIR /app

# install dependencies
RUN pip install confluent-kafka

COPY coletor_range_ids.py /app/

CMD ["python", "coletor_range_ids.py"]
