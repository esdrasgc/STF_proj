# 🚦 Sistema de Rate Limiting - STF Scrapping

## 📋 Visão Geral

Este sistema implementa um controle robusto de taxa de requisições para evitar sobrecarga do servidor STF e possíveis bloqueios. O sistema utiliza Redis para coordenação distribuída e Celery para gerenciamento de filas.

## 🏗️ Arquitetura

### Componentes Principais:
- **Redis**: Armazenamento para controle de rate limiting
- **RabbitMQ**: Broker de mensagens do Celery
- **MongoDB**: Armazenamento dos dados coletados
- **Celery Workers**: Processamento das tarefas de scrapping

### Melhorias Implementadas:
1. **Rate Limiter com Redis**: Controle distribuído de requisições
2. **Delays Aleatórios**: Entre 2-5s para processos, 1-3s para abas
3. **Configurações Centralizadas**: Fácil ajuste de parâmetros
4. **Retry Inteligente**: 5 minutos entre tentativas
5. **Monitoramento**: Scripts para acompanhar o status
6. **Concorrência Limitada**: Máximo 2 workers por container

## ⚙️ Configurações

### Variáveis de Ambiente (Opcionais)

```bash
# Rate Limiting
MAX_REQUESTS_PER_MINUTE=30        # Requisições por minuto (padrão: 30)
MIN_DELAY_PROCESSO=2.0            # Delay mínimo processos (padrão: 2s)
MAX_DELAY_PROCESSO=5.0            # Delay máximo processos (padrão: 5s)
MIN_DELAY_ABA=1.0                 # Delay mínimo abas (padrão: 1s)
MAX_DELAY_ABA=3.0                 # Delay máximo abas (padrão: 3s)

# Retry e Timeout
RETRY_COUNTDOWN_SECONDS=300       # Tempo entre retries (padrão: 5min)
MAX_RETRIES=5                     # Máximo de tentativas (padrão: 5)
REQUEST_TIMEOUT=13                # Timeout das requisições (padrão: 13s)

# Celery
WORKER_CONCURRENCY=2              # Workers por container (padrão: 2)
RATE_LIMITER_MAX_WAIT=300         # Tempo máx espera slot (padrão: 5min)

# Redis
REDIS_HOST=redis                  # Host do Redis (padrão: redis)
REDIS_PORT=6379                   # Porta do Redis (padrão: 6379)
REDIS_DB=0                        # Database Redis (padrão: 0)
```

## 🚀 Como Usar

### 1. Iniciar o Sistema

```bash
# Subir todos os serviços
docker-compose up -d

# Verificar se todos os containers estão rodando
docker-compose ps
```

### 2. Testar o Rate Limiting

```bash
# Executar testes de validação
python test_rate_limit.py

# Monitorar rate limiting em tempo real
python monitor_rate_limit.py

# Ver configurações atuais
python config_rate_limit.py
```

### 3. Iniciar Coleta de Dados

```bash
# Acessar interface web (se disponível)
http://localhost:80

# Ou enviar tarefas diretamente via Celery
python -c "
from celery_app import app
app.send_task('tasks_processo.processar', args=['123456'])
"
```

## 📊 Monitoramento

### Script de Monitoramento
```bash
python monitor_rate_limit.py
```

Mostra em tempo real:
- Requisições atuais vs limite
- Slots disponíveis
- Status das chaves Redis
- Configurações ativas

### Logs do Sistema
```bash
# Logs do Celery Worker
docker-compose logs -f celery_worker

# Logs específicos de rate limiting
grep "Rate limiter" logs/celery_worker.log
```

## 🔧 Ajustes Recomendados

### Para Reduzir Ainda Mais a Carga:
```bash
# Reduzir requisições por minuto
MAX_REQUESTS_PER_MINUTE=15

# Aumentar delays
MIN_DELAY_PROCESSO=3.0
MAX_DELAY_PROCESSO=8.0

# Reduzir concorrência
WORKER_CONCURRENCY=1
```

### Para Ambientes de Desenvolvimento:
```bash
# Aumentar velocidade (use com cuidado!)
MAX_REQUESTS_PER_MINUTE=60
MIN_DELAY_PROCESSO=1.0
MAX_DELAY_PROCESSO=2.0
```

## 🛠️ Solução de Problemas

### Redis Não Conecta
```bash
# Verificar se Redis está rodando
docker-compose ps redis

# Reiniciar Redis
docker-compose restart redis

# Verificar logs
docker-compose logs redis
```

### Rate Limiting Muito Restritivo
```bash
# Verificar configurações atuais
python config_rate_limit.py

# Ajustar via variáveis de ambiente
export MAX_REQUESTS_PER_MINUTE=50
docker-compose restart celery_worker
```

### Tarefas Falhando Muito
```bash
# Verificar logs detalhados
docker-compose logs -f celery_worker | grep ERROR

# Aumentar timeouts
export RETRY_COUNTDOWN_SECONDS=600  # 10 minutos
export REQUEST_TIMEOUT=20           # 20 segundos
```

## 📈 Métricas de Performance

### Antes das Melhorias:
- ❌ Requisições descontroladas
- ❌ Bloqueios frequentes do STF
- ❌ Retry imediato (60s)
- ❌ Sem controle de concorrência

### Depois das Melhorias:
- ✅ Máximo 30 req/min controladas
- ✅ Delays aleatórios (2-5s)
- ✅ Retry inteligente (5min)
- ✅ Concorrência limitada (2 workers)
- ✅ Monitoramento em tempo real

## 🔒 Configurações de Segurança

### Rate Limiting Conservador:
```bash
MAX_REQUESTS_PER_MINUTE=20
MIN_DELAY_PROCESSO=4.0
MAX_DELAY_PROCESSO=8.0
RETRY_COUNTDOWN_SECONDS=600  # 10 minutos
```

### User-Agents Rotativos:
O sistema já utiliza `fake-useragent` para rotacionar User-Agents automaticamente.

## 📝 Arquivos Importantes

- `rate_limiter.py`: Implementação do rate limiting
- `config_rate_limit.py`: Configurações centralizadas
- `monitor_rate_limit.py`: Monitoramento em tempo real
- `test_rate_limit.py`: Testes de validação
- `docker-compose.yaml`: Configuração dos serviços
- `celery_app.py`: Configuração do Celery
- `coleta_processo.py`: Coleta de dados principais
- `coleta_aba.py`: Coleta de dados das abas

## 🎯 Próximos Passos

1. **Monitorar Performance**: Use o script de monitoramento
2. **Ajustar Configurações**: Baseado nos logs e performance
3. **Implementar Alertas**: Para bloqueios ou falhas
4. **Backup de Configurações**: Salvar configurações que funcionam bem

---

**⚠️ Importante**: Sempre teste as configurações em um ambiente de desenvolvimento antes de aplicar em produção!
