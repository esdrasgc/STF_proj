#!/usr/bin/env python3
"""
Script para monitorar o rate limiting do sistema de scrapping STF.
Mostra estatísticas em tempo real sobre o uso das requisições.
"""

import time
import os
from rate_limiter import RateLimiter
from datetime import datetime
import json

def main():
    print("🚀 Monitor de Rate Limiting - Sistema STF Scrapping")
    print("=" * 60)
    
    # Inicializa o rate limiter
    rate_limiter = RateLimiter()
    
    if not rate_limiter.redis_client:
        print("❌ Erro: Redis não está disponível!")
        return
    
    print("✅ Conectado ao Redis com sucesso!")
    print(f"📊 Limite configurado: {rate_limiter.max_requests_per_minute} requisições/minuto")
    print("=" * 60)
    
    try:
        while True:
            # Limpa a tela (funciona no Linux/Mac)
            os.system('clear' if os.name == 'posix' else 'cls')
            
            print("🚀 Monitor de Rate Limiting - Sistema STF Scrapping")
            print("=" * 60)
            print(f"⏰ Atualizado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            print()
            
            # Estatísticas gerais
            usage = rate_limiter.get_current_usage()
            if 'error' not in usage:
                print("📈 ESTATÍSTICAS GERAIS:")
                print(f"   • Requisições atuais: {usage['current_requests']}")
                print(f"   • Limite máximo: {usage['max_requests']}")
                print(f"   • Slots disponíveis: {usage['remaining_requests']}")
                
                # Calcula porcentagem de uso
                percent_used = (usage['current_requests'] / usage['max_requests']) * 100
                print(f"   • Uso atual: {percent_used:.1f}%")
                
                # Barra de progresso visual
                bar_length = 30
                filled_length = int(bar_length * percent_used / 100)
                bar = '█' * filled_length + '░' * (bar_length - filled_length)
                print(f"   • [{bar}] {percent_used:.1f}%")
                
                # Status baseado no uso
                if percent_used < 50:
                    status = "🟢 NORMAL"
                elif percent_used < 80:
                    status = "🟡 MODERADO"
                else:
                    status = "🔴 ALTO"
                print(f"   • Status: {status}")
            else:
                print(f"❌ Erro ao obter estatísticas: {usage['error']}")
            
            print()
            print("🔍 CHAVES ATIVAS NO REDIS:")
            
            # Lista todas as chaves relacionadas ao STF
            try:
                keys = rate_limiter.redis_client.keys("stf_*")
                if keys:
                    for key in sorted(keys):
                        count = rate_limiter.redis_client.zcard(key)
                        print(f"   • {key}: {count} requisições")
                else:
                    print("   • Nenhuma chave ativa encontrada")
            except Exception as e:
                print(f"   • Erro ao listar chaves: {e}")
            
            print()
            print("⚙️  CONFIGURAÇÕES:")
            print(f"   • Redis Host: {rate_limiter.redis_host}")
            print(f"   • Redis Port: {rate_limiter.redis_port}")
            print(f"   • Redis DB: {rate_limiter.redis_db}")
            print(f"   • Limite: {rate_limiter.max_requests_per_minute} req/min")
            
            print()
            print("📝 COMANDOS:")
            print("   • Ctrl+C: Sair do monitor")
            print("   • O monitor atualiza a cada 5 segundos")
            
            print("=" * 60)
            
            # Aguarda 5 segundos antes da próxima atualização
            time.sleep(5)
            
    except KeyboardInterrupt:
        print("\n\n👋 Monitor finalizado pelo usuário.")
    except Exception as e:
        print(f"\n\n❌ Erro no monitor: {e}")

if __name__ == "__main__":
    main()
