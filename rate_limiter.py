import redis
import time
import os
from typing import Optional
import logging
from config_rate_limit import config
import uuid

logger = logging.getLogger(__name__)
# Garanta que mensagens INFO sejam emitidas mesmo se root estiver padrão WARNING
if not logger.handlers:
    logger.setLevel(logging.INFO)

class RateLimiter:
    """
    Rate limiter usando Redis com algoritmo de sliding window.
    Controla a quantidade de requisições por minuto para evitar sobrecarga do servidor STF.
    """
    
    def __init__(self, 
                 redis_host: str = None, 
                 redis_port: int = None, 
                 redis_db: int = None,
                 max_requests_per_minute: int = None):
        """
        Inicializa o rate limiter.
        
        Args:
            redis_host: Host do Redis (padrão: variável de ambiente REDIS_HOST)
            redis_port: Porta do Redis (padrão: variável de ambiente REDIS_PORT)
            redis_db: Database do Redis (padrão: variável de ambiente REDIS_DB)
            max_requests_per_minute: Máximo de requisições por minuto (padrão: 30)
        """
        self.redis_host = redis_host or config.REDIS_HOST
        self.redis_port = int(redis_port or config.REDIS_PORT)
        self.redis_db = int(redis_db or config.REDIS_DB)
        self.max_requests_per_minute = max_requests_per_minute or config.MAX_REQUESTS_PER_MINUTE
        
        # Conecta ao Redis
        try:
            self.redis_client = redis.Redis(
                host=self.redis_host,
                port=self.redis_port,
                db=self.redis_db,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5
            )
            # Testa a conexão
            self.redis_client.ping()
            logger.info(f"Conectado ao Redis em {self.redis_host}:{self.redis_port}")
        except Exception as e:
            logger.error(f"Erro ao conectar ao Redis: {e}")
            self.redis_client = None
    
    def can_make_request(self, key: str = "stf_scraper") -> bool:
        """
        Verifica se é possível fazer uma requisição baseado no rate limit.
        
        Args:
            key: Chave para identificar o rate limit (padrão: "stf_scraper")
            
        Returns:
            bool: True se pode fazer a requisição, False caso contrário
        """
        if not self.redis_client:
            # Se Redis não estiver disponível, permite a requisição mas com warning
            logger.warning("Redis não disponível, rate limiting desabilitado")
            return True
        
        try:
            # Usa timestamp de alta resolução (float) para score
            now = time.time()
            window_start = now - 60.0  # Janela de 1 minuto
            
            # Remove requisições antigas (fora da janela de 1 minuto)
            self.redis_client.zremrangebyscore(key, 0, window_start)
            
            # Conta requisições na janela atual
            current_requests = self.redis_client.zcard(key)
            
            if current_requests < self.max_requests_per_minute:
                # Adiciona a requisição atual com member único para evitar sobrescrita
                member = f"{now}-{uuid.uuid4()}"
                self.redis_client.zadd(key, {member: now})
                # Define expiração da chave para limpeza automática
                self.redis_client.expire(key, 120)  # 2 minutos
                logger.info(
                    f"[RateLimiter] ALLOW key={key} current={current_requests+1} max={self.max_requests_per_minute}"
                )
                return True
            else:
                logger.warning(
                    f"[RateLimiter] DENY key={key} current={current_requests} max={self.max_requests_per_minute}"
                )
                return False
                
        except Exception as e:
            logger.error(f"Erro no rate limiter: {e}")
            # Em caso de erro, permite a requisição
            return True
    
    def wait_for_available_slot(self, key: str = "stf_scraper", max_wait_time: int = 300) -> bool:
        """
        Aguarda até que uma slot esteja disponível para fazer uma requisição.
        
        Args:
            key: Chave para identificar o rate limit
            max_wait_time: Tempo máximo de espera em segundos (padrão: 5 minutos)
            
        Returns:
            bool: True se conseguiu uma slot, False se timeout
        """
        start_time = time.time()
        
        while time.time() - start_time < max_wait_time:
            if self.can_make_request(key):
                logger.info(f"[RateLimiter] SLOT ACQUIRED key={key}")
                return True
            
            # Calcula tempo de espera inteligente
            if self.redis_client:
                try:
                    # Pega a requisição mais antiga na janela
                    oldest_request = self.redis_client.zrange(key, 0, 0, withscores=True)
                    if oldest_request:
                        oldest_time = oldest_request[0][1]
                        wait_time = max(1, int(oldest_time + 60 - time.time()))
                        wait_time = min(wait_time, 10)  # Máximo 10 segundos de espera
                    else:
                        wait_time = 1
                except Exception:
                    wait_time = 2
            else:
                wait_time = 2
            
            logger.info(f"Rate limit atingido, aguardando {wait_time} segundos...")
            time.sleep(wait_time)
        
        logger.error(f"Timeout no rate limiter após {max_wait_time} segundos")
        return False
    
    def get_current_usage(self, key: str = "stf_scraper") -> dict:
        """
        Retorna informações sobre o uso atual do rate limiter.
        
        Args:
            key: Chave para identificar o rate limit
            
        Returns:
            dict: Informações sobre uso atual
        """
        if not self.redis_client:
            return {"error": "Redis não disponível"}
        
        try:
            now = time.time()
            window_start = now - 60.0
            
            # Remove requisições antigas
            self.redis_client.zremrangebyscore(key, 0, window_start)
            
            # Conta requisições atuais
            current_requests = self.redis_client.zcard(key)
            
            return {
                "current_requests": current_requests,
                "max_requests": self.max_requests_per_minute,
                "remaining_requests": max(0, self.max_requests_per_minute - current_requests),
                "window_start": window_start,
                "current_time": now
            }
        except Exception as e:
            return {"error": str(e)}

# Instância global do rate limiter
rate_limiter = RateLimiter()
