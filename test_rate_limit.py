#!/usr/bin/env python3
"""
Script de teste para validar o sistema de rate limiting.
Executa testes básicos para garantir que tudo está funcionando corretamente.
"""

import time
import sys
from rate_limiter import rate_limiter
from config_rate_limit import config
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def test_redis_connection():
    """Testa a conexão com o Redis."""
    print("🔗 Testando conexão com Redis...")
    
    if not rate_limiter.redis_client:
        print("❌ Falha: Redis não está disponível!")
        return False
    
    try:
        rate_limiter.redis_client.ping()
        print("✅ Sucesso: Conexão com Redis estabelecida!")
        return True
    except Exception as e:
        print(f"❌ Falha: Erro ao conectar com Redis: {e}")
        return False

def test_rate_limiter_basic():
    """Testa funcionalidade básica do rate limiter."""
    print("\n🚦 Testando funcionalidade básica do rate limiter...")
    
    test_key = "test_rate_limit"
    
    # Limpa qualquer estado anterior
    try:
        rate_limiter.redis_client.delete(test_key)
    except:
        pass
    
    # Testa se pode fazer requisições
    can_request = rate_limiter.can_make_request(test_key)
    if can_request:
        print("✅ Sucesso: Primeira requisição permitida!")
    else:
        print("❌ Falha: Primeira requisição negada!")
        return False
    
    # Testa estatísticas
    usage = rate_limiter.get_current_usage(test_key)
    if 'error' not in usage:
        print(f"✅ Sucesso: Estatísticas obtidas - {usage['current_requests']}/{usage['max_requests']}")
    else:
        print(f"❌ Falha: Erro ao obter estatísticas: {usage['error']}")
        return False
    
    return True

def test_rate_limit_enforcement():
    """Testa se o rate limiting está sendo aplicado corretamente."""
    print("\n⚡ Testando aplicação do rate limiting...")
    
    test_key = "test_enforcement"
    
    # Limpa estado anterior
    try:
        rate_limiter.redis_client.delete(test_key)
    except:
        pass
    
    # Cria um rate limiter com limite baixo para teste
    test_limiter = rate_limiter.__class__(max_requests_per_minute=3)
    
    successful_requests = 0
    
    # Tenta fazer mais requisições do que o limite
    for i in range(5):
        if test_limiter.can_make_request(test_key):
            successful_requests += 1
        time.sleep(0.1)  # Pequeno delay
    
    if successful_requests == 3:
        print(f"✅ Sucesso: Rate limiting funcionando! {successful_requests}/5 requisições permitidas")
        return True
    else:
        print(f"❌ Falha: Rate limiting não está funcionando! {successful_requests}/5 requisições permitidas")
        return False

def test_configuration_loading():
    """Testa se as configurações estão sendo carregadas corretamente."""
    print("\n⚙️ Testando carregamento de configurações...")
    
    try:
        # Testa se as configurações estão acessíveis
        print(f"   • Redis Host: {config.REDIS_HOST}")
        print(f"   • Redis Port: {config.REDIS_PORT}")
        print(f"   • Max Requests/min: {config.MAX_REQUESTS_PER_MINUTE}")
        print(f"   • Worker Concurrency: {config.WORKER_CONCURRENCY}")
        print(f"   • Retry Countdown: {config.RETRY_COUNTDOWN_SECONDS}s")
        
        # Verifica se os valores são válidos
        if (config.MAX_REQUESTS_PER_MINUTE > 0 and 
            config.WORKER_CONCURRENCY > 0 and 
            config.RETRY_COUNTDOWN_SECONDS > 0):
            print("✅ Sucesso: Configurações carregadas e válidas!")
            return True
        else:
            print("❌ Falha: Configurações inválidas!")
            return False
            
    except Exception as e:
        print(f"❌ Falha: Erro ao carregar configurações: {e}")
        return False

def test_delay_ranges():
    """Testa se os ranges de delay estão configurados corretamente."""
    print("\n⏱️ Testando configurações de delay...")
    
    try:
        if (config.MIN_DELAY_PROCESSO < config.MAX_DELAY_PROCESSO and
            config.MIN_DELAY_ABA < config.MAX_DELAY_ABA and
            config.MIN_DELAY_PROCESSO > 0 and
            config.MIN_DELAY_ABA > 0):
            print(f"   • Delay Processo: {config.MIN_DELAY_PROCESSO}-{config.MAX_DELAY_PROCESSO}s")
            print(f"   • Delay Aba: {config.MIN_DELAY_ABA}-{config.MAX_DELAY_ABA}s")
            print("✅ Sucesso: Configurações de delay válidas!")
            return True
        else:
            print("❌ Falha: Configurações de delay inválidas!")
            return False
    except Exception as e:
        print(f"❌ Falha: Erro ao verificar delays: {e}")
        return False

def run_all_tests():
    """Executa todos os testes."""
    print("🧪 INICIANDO TESTES DO SISTEMA DE RATE LIMITING")
    print("=" * 60)
    
    tests = [
        ("Conexão Redis", test_redis_connection),
        ("Rate Limiter Básico", test_rate_limiter_basic),
        ("Aplicação Rate Limiting", test_rate_limit_enforcement),
        ("Carregamento Configurações", test_configuration_loading),
        ("Configurações Delay", test_delay_ranges)
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ Erro no teste '{test_name}': {e}")
            results.append((test_name, False))
    
    # Resumo dos resultados
    print("\n" + "=" * 60)
    print("📊 RESUMO DOS TESTES:")
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASSOU" if result else "❌ FALHOU"
        print(f"   • {test_name}: {status}")
        if result:
            passed += 1
    
    print(f"\n🏆 RESULTADO FINAL: {passed}/{total} testes passaram")
    
    if passed == total:
        print("🎉 Todos os testes passaram! Sistema pronto para uso.")
        return True
    else:
        print("⚠️  Alguns testes falharam. Verifique as configurações.")
        return False

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
