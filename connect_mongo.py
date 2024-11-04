from pymongo import MongoClient
from dotenv import load_dotenv
import os

# Carregar as variáveis do .env
load_dotenv()

class MongoDBDatabase:
    # Obter as variáveis de ambiente
    username = os.getenv("MONGO_INITDB_ROOT_USERNAME")
    password = os.getenv("MONGO_INITDB_ROOT_PASSWORD")
    host = os.getenv("MONGO_HOST")
    port = os.getenv("MONGO_PORT")
    database = os.getenv("MONGO_DB")

    client = None
    db = None

    @classmethod
    def init_db(cls):
        cls.client = MongoClient(f"mongodb://{cls.username}:{cls.password}@{cls.host}:{cls.port}/")
        cls.db = cls.client[cls.database]
        return cls.db

    @classmethod
    def get_db(cls):
        if cls.db is None:
            cls.init_db()
        return cls.db