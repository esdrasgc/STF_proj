# STF Scraper – Arquitetura, Execução e Operação

Este documento descreve o pipeline de raspagem do portal do STF implementado neste repositório. Ele cobre a visão geral, arquitetura, configuração, execução, uso, monitoramento, solução de problemas e observações operacionais.

## Visão Geral

O sistema realiza a coleta de páginas do portal do STF de forma assíncrona com Celery, enviando tarefas para filas distintas, controlando a taxa de requisições com Redis e persistindo os resultados em MongoDB. Opcionalmente, quando executado em AWS EC2, pode rotacionar o Elastic IP ao detectar respostas 403, reduzindo bloqueios prolongados.

Principais características:
- Filas Celery separadas para processamento do processo principal (`processo`) e das abas (`abas`).
- Rate limiting em dois níveis:
  - Cadência de despacho com tasks periódicas no `rate_limit_dispatcher.py`.
  - Janela deslizante com Redis (`rate_limiter.py`) disponível para políticas adicionais.
- Requisições robustas com retry e backoff configuráveis (`config_rate_limit.py`).
- Persistência em MongoDB com índices e coleção unificada para agregação.
- API simples (FastAPI) para enfileirar intervalos de incidentes (`coletor_range_ids.py`).
- Opção de rotação de EIP em AWS em caso de 403 (`aws_ip_rotator.py`).

## Arquitetura

Componentes principais:
- `celery_app.py`: Configura a aplicação Celery (broker, backend, rotas de tarefas, filas e include dos módulos de tarefas).
- `coleta_processo.py`: Tarefa `tasks_processo.processar` que coleta a página principal do processo, extrai dados centrais e enfileira as abas.
- `coleta_aba.py`: Tarefa `tasks_abas.processar` que coleta e persiste dados de cada aba (andamentos, deslocamentos, informações, partes, recursos e sessão virtual).
- `rate_limit_dispatcher.py`: Despacha tarefas das filas de holding para as filas ativas respeitando a cadência configurada e o bloqueio global.
- `rate_limiter.py`: Rate limiter baseado em Redis com janela deslizante (utilitário opcional para controle extra).
- `config_rate_limit.py`: Centraliza variáveis de rate limit, delays, retry e configuração de workers.
- `coletor_range_ids.py`: API FastAPI para enfileirar intervalos de incidentes.
- `connect_mongo.py`: Conexão MongoDB e criação de índices.
- `scrapping_codes/`: Parsers de HTML/JSON por aba e exemplos de saída (`*.json`).
- `start_worker.sh`: Sobe a API (Uvicorn) e o worker Celery (com beat) dentro do container.
- `celery_worker.Dockerfile`: Dockerfile do worker/API.

Serviços (via `docker-compose.yaml`):
- `rabbitmq`: Broker Celery.
- `mongo`: Banco de dados; `mongo-express` para visualização.
- `redis`: Rate limiting e bloqueio global.
- `celery_worker`: Container com a API (porta interna 8000, exposta como 80) e o worker Celery + beat.

### Filas e Roteamento
- Queue `processo`: tarefas `tasks_processo.*`.
- Queue `abas`: tarefas `tasks_abas.*`.
- Filas de holding: `rate_limited_processo`, `rate_limited_abas` (producers publicam aqui; o dispatcher libera conforme cadência).

### Cadência e Bloqueio Global
- Tarefas periódicas movem mensagens das filas de holding para as filas de consumo a cada `SECS_PER_TASK_PROCESSO` e `SECS_PER_TASK_ABAS`.
- Em 403, aplica-se bloqueio global curto para desacelerar o cluster; opcionalmente rotaciona-se o EIP se habilitado.

## Fluxo de Processamento
1. Enfileiramento de IDs via API (`coletor_range_ids.py`):
   - `POST /produce` com `start_id` e `end_id`.
   - Cada ID é publicado na fila de holding `rate_limited_processo`.
2. Dispatcher periódico move mensagens de `rate_limited_*` para `processo`/`abas` respeitando `SECS_PER_TASK_*`.
3. `tasks_processo.processar` baixa a página principal, extrai dados centrais e publica tarefas de abas na `rate_limited_abas`.
4. `tasks_abas.processar` baixa a aba, processa com `scrapping_codes/*` e persiste no MongoDB.
5. Em 403, define bloqueio global e (se habilitado) tenta rotação de EIP antes de re-tentar.

## Configuração (.env)
Consulte `STF_proj/.env.example` para valores padrão. Principais chaves:
- MongoDB: `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`, `MONGO_HOST`, `MONGO_PORT`, `MONGO_DB`.
- Celery: `CELERY_BROKER_URL` (RabbitMQ), `CELERY_RESULT_BACKEND` (MongoDB).
- Redis: `REDIS_HOST`, `REDIS_PORT`, `REDIS_DB`.
- Rate limiting e tarefas:
  - `MAX_REQUESTS_PER_MINUTE`, `RETRY_COUNTDOWN_SECONDS`, `MAX_RETRIES`, `REQUEST_TIMEOUT`.
  - `WORKER_CONCURRENCY`, `WORKER_PREFETCH_MULTIPLIER`.
  - `SECS_PER_TASK_PROCESSO`, `SECS_PER_TASK_ABAS`.
- AWS (opcional): `EIP_ROTATION_ENABLED`, `EIP_RELEASE_OLD`, `EIP_ROTATION_COOLDOWN_SECS`, `EIP_ROTATION_LOCK_TTL_SECS`, `AWS_REGION`.

## Como Executar

Pré-requisitos: Docker e Docker Compose.

1. Copie `STF_proj/.env.example` para `STF_proj/.env` e ajuste variáveis conforme necessário.
2. Construa e suba os serviços:
   ```bash
   docker compose up -d --build
   ```
3. Acesso rápido:
   - API de enfileiramento: `http://localhost/` (Formulário simples para intervalo de IDs).
   - RabbitMQ Management: `http://localhost:15672` (credenciais do `.env`).
   - Mongo Express: `http://localhost:8081` (credenciais do `.env`).
   - Redis: `localhost:6379`.

Execução local (sem Docker):
- Inicie RabbitMQ, MongoDB e Redis localmente.
- Instale dependências:
  ```bash
  pip install -r STF_proj/requirements.txt
  # ou para ambiente mínimo do enfileirador
  pip install -r STF_proj/requirements_coletor_ids.txt
  ```
- API:
  ```bash
  uvicorn coletor_range_ids:app --host 0.0.0.0 --port 8000
  ```
- Worker Celery (com beat):
  ```bash
  sh start_worker.sh
  # ou equivalente
  celery -A celery_app worker -Q processo,abas --loglevel=INFO \
    -c ${WORKER_CONCURRENCY} --prefetch-multiplier=${WORKER_PREFETCH_MULTIPLIER} -Ofair --beat
  ```

## Uso
- Navegue até `http://localhost/`, informe `start_id` e `end_id` e envie.
- Acompanhe as filas no RabbitMQ Management e a persistência no Mongo Express.
- Dados são gravados nas coleções MongoDB:
  - `processos`, `processos_unificados` e coleções por aba (`andamentos`, `deslocamentos`, `informacoes`, `partes`, `recursos`, `sessao`).

## Estrutura de Diretórios (resumo)
```
STF_proj/
  docker-compose.yaml
  celery_worker.Dockerfile
  start_worker.sh
  celery_app.py
  coleta_processo.py
  coleta_aba.py
  coletor_range_ids.py
  connect_mongo.py
  rate_limiter.py
  rate_limit_dispatcher.py
  config_rate_limit.py
  scrapping_codes/
    andamentos.py, deslocamentos.py, informacoes.py, partes.py, recursos.py, sessao.py
    *.json (exemplos)
  paginas_html/
  requirements.txt
  requirements_coletor_ids.txt
  .env.example
  README.md (foco em EIP rotation)
  README.projeto.md (este arquivo)
```

## Monitoramento e Logs
- Celery: logs do worker em INFO/WARNING com eventos de rate limit e bloqueio global.
- Rate limiter: logs `[RateLimiter]` (allow/deny e esperas).
- Dispatcher: logs `[Dispatcher]` ao despachar e aplicar bloqueios.
- EIP: logs `[EIP]` (consulte `README.md`).

## Solução de Problemas
- 429/403 recorrentes:
  - Aumente espaçamento entre tarefas via `SECS_PER_TASK_*` ou reduza `WORKER_CONCURRENCY`.
  - Aumente `RETRY_COUNTDOWN_SECONDS` e ajuste `MAX_REQUESTS_PER_MINUTE`.
- Redis indisponível:
  - A janela deslizante fica inativa, mas a cadência via dispatcher continua. Corrija conexão Redis.
- Mensagens acumuladas em `rate_limited_*`:
  - Verifique se o beat está ativo e valores `SECS_PER_TASK_*`.
- Duplicidade no Mongo:
  - Existem índices em `id_incidente`; ajuste upserts conforme sua necessidade.

## Observações Operacionais e Custos
- Uso responsável: respeite termos de uso do portal e políticas de acesso.
- AWS: rotação de EIP pode incorrer custos se IPs ficarem alocados sem associação.
