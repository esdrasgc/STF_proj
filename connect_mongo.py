import os
import pymongo
import logging
from pymongo.collection import Collection
from pymongo.database import Database

logger = logging.getLogger(__name__)

class MongoDBDatabase:
    client = None
    db = None

    @classmethod
    def init_client(cls):
        """Initialize MongoDB client with connection parameters from environment variables."""
        try:
            username = os.getenv('MONGO_INITDB_ROOT_USERNAME')
            password = os.getenv('MONGO_INITDB_ROOT_PASSWORD')
            host = os.getenv('MONGO_HOST', 'localhost')
            port = int(os.getenv('MONGO_PORT', '27017'))
            db_name = os.getenv('MONGO_DB', 'stf_data')
            
            # Connection string with authentication
            mongo_uri = f"mongodb://{username}:{password}@{host}:{port}"
            
            # Allow for retry logic for AWS environment where network might be unstable initially
            max_retries = 5
            retry_count = 0
            
            while retry_count < max_retries:
                try:
                    cls.client = pymongo.MongoClient(
                        mongo_uri,
                        serverSelectionTimeoutMS=5000,  # 5 second timeout
                        connectTimeoutMS=5000,
                        socketTimeoutMS=10000
                    )
                    # Force connection to verify it works
                    cls.client.server_info()
                    cls.db = cls.client[db_name]
                    logger.info(f"Successfully connected to MongoDB at {host}:{port}/{db_name}")
                    return cls.client
                except Exception as e:
                    retry_count += 1
                    logger.warning(f"MongoDB connection attempt {retry_count} failed: {e}")
                    if retry_count >= max_retries:
                        logger.error(f"Failed to connect to MongoDB after {max_retries} attempts")
                        raise
                    import time
                    time.sleep(5)  # Wait 5 seconds before retrying
        except Exception as e:
            logger.error(f"Error initializing MongoDB client: {e}")
            raise

    @classmethod
    def get_client(cls) -> pymongo.MongoClient:
        """Get MongoDB client instance, initializing if necessary."""
        if cls.client is None:
            cls.init_client()
        return cls.client

    @classmethod
    def get_db(cls) -> Database:
        """Get MongoDB database instance, initializing if necessary."""
        if cls.db is None:
            cls.init_client()
        return cls.db
        
    @classmethod
    def get_collection(cls, collection_name: str) -> Collection:
        """Get MongoDB collection by name."""
        return cls.get_db()[collection_name]
        
    @classmethod
    def close_connection(cls):
        """Close MongoDB connection."""
        if cls.client is not None:
            cls.client.close()
            cls.client = None
            cls.db = None