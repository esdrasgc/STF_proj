"""
Configurações do Rate Limiting para o sistema de scrapping STF.
Centralize todas as configurações relacionadas ao controle de taxa aqui.
"""

import os

class RateLimitConfig:
    """Configurações centralizadas para rate limiting."""
    
    # Configurações do Redis
    REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
    REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
    REDIS_DB = int(os.getenv('REDIS_DB', 0))
    
    # Configurações de Rate Limiting
    MAX_REQUESTS_PER_MINUTE = int(os.getenv('MAX_REQUESTS_PER_MINUTE', 30))
    
    # Delays entre requisições (em segundos)
    MIN_DELAY_PROCESSO = float(os.getenv('MIN_DELAY_PROCESSO', 2.0))
    MAX_DELAY_PROCESSO = float(os.getenv('MAX_DELAY_PROCESSO', 5.0))
    MIN_DELAY_ABA = float(os.getenv('MIN_DELAY_ABA', 1.0))
    MAX_DELAY_ABA = float(os.getenv('MAX_DELAY_ABA', 3.0))
    
    # Configurações de Retry
    RETRY_COUNTDOWN_SECONDS = int(os.getenv('RETRY_COUNTDOWN_SECONDS', 300))  # 5 minutos
    MAX_RETRIES = int(os.getenv('MAX_RETRIES', 5))
    REQUEST_TIMEOUT = int(os.getenv('REQUEST_TIMEOUT', 13))
    
    # Configurações do Celery
    WORKER_CONCURRENCY = int(os.getenv('WORKER_CONCURRENCY', 2))
    WORKER_PREFETCH_MULTIPLIER = int(os.getenv('WORKER_PREFETCH_MULTIPLIER', 1))
    
    # Timeouts
    RATE_LIMITER_MAX_WAIT = int(os.getenv('RATE_LIMITER_MAX_WAIT', 300))  # 5 minutos

    # Cadências de despacho por fila (em segundos por tarefa)
    SECS_PER_TASK_PROCESSO = float(os.getenv('SECS_PER_TASK_PROCESSO', 2.0))
    SECS_PER_TASK_ABAS = float(os.getenv('SECS_PER_TASK_ABAS', 1.0))
    
    @classmethod
    def get_config_summary(cls):
        """Retorna um resumo das configurações atuais."""
        return {
            'redis': {
                'host': cls.REDIS_HOST,
                'port': cls.REDIS_PORT,
                'db': cls.REDIS_DB
            },
            'rate_limiting': {
                'max_requests_per_minute': cls.MAX_REQUESTS_PER_MINUTE,
                'max_wait_time': cls.RATE_LIMITER_MAX_WAIT
            },
            'delays': {
                'processo_min': cls.MIN_DELAY_PROCESSO,
                'processo_max': cls.MAX_DELAY_PROCESSO,
                'aba_min': cls.MIN_DELAY_ABA,
                'aba_max': cls.MAX_DELAY_ABA
            },
            'retry': {
                'countdown_seconds': cls.RETRY_COUNTDOWN_SECONDS,
                'max_retries': cls.MAX_RETRIES,
                'request_timeout': cls.REQUEST_TIMEOUT
            },
            'celery': {
                'worker_concurrency': cls.WORKER_CONCURRENCY,
                'worker_prefetch_multiplier': cls.WORKER_PREFETCH_MULTIPLIER
            }
        }
    
    @classmethod
    def print_config(cls):
        """Imprime as configurações atuais de forma legível."""
        print("🔧 CONFIGURAÇÕES DO RATE LIMITING")
        print("=" * 50)
        
        config = cls.get_config_summary()
        
        print("📡 Redis:")
        print(f"   Host: {config['redis']['host']}")
        print(f"   Port: {config['redis']['port']}")
        print(f"   DB: {config['redis']['db']}")
        
        print("\n🚦 Rate Limiting:")
        print(f"   Máx req/min: {config['rate_limiting']['max_requests_per_minute']}")
        print(f"   Tempo máx espera: {config['rate_limiting']['max_wait_time']}s")
        
        print("\n⏱️  Delays:")
        print(f"   Processo: {config['delays']['processo_min']}-{config['delays']['processo_max']}s")
        print(f"   Aba: {config['delays']['aba_min']}-{config['delays']['aba_max']}s")
        
        print("\n🔄 Retry:")
        print(f"   Countdown: {config['retry']['countdown_seconds']}s")
        print(f"   Máx tentativas: {config['retry']['max_retries']}")
        print(f"   Timeout req: {config['retry']['request_timeout']}s")
        
        print("\n⚙️  Celery:")
        print(f"   Concorrência: {config['celery']['worker_concurrency']}")
        print(f"   Prefetch: {config['celery']['worker_prefetch_multiplier']}")
        
        print("=" * 50)

# Instância global das configurações
config = RateLimitConfig()

if __name__ == "__main__":
    # Executa este arquivo para ver as configurações atuais
    RateLimitConfig.print_config()
