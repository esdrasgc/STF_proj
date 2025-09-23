# STF Scraping - Documentação do Projeto

Este repositório implementa um pipeline de scrapping do portal do STF, com controle de taxa distribuído (rate limiting), filas de tarefas com Celery, armazenamento em MongoDB e uma interface mínima (FastAPI) para enfileirar intervalos de IDs de incidentes.


## Sumário

- Visão Geral e Arquitetura
- Estrutura do Projeto
- Serviços e Dependências
- Variáveis de Ambiente (.env)
- Como executar (Docker Compose)
- Interface Web (FastAPI) e Filas Celery
- Fluxo de Coleta (Workflow)
- Rate Limiting
- Persistência no MongoDB (Modelo de Dados)
- Como rodar localmente (sem Docker)
- Observabilidade e Logs
- Solução de Problemas


## Visão Geral e Arquitetura

Componentes principais:

- RabbitMQ: broker de mensagens para Celery.
- Celery Workers: executam as tarefas de coleta (`tasks_processo.*`, `tasks_abas.*`).
- Redis: coordena o rate limiter (janela deslizante) compartilhado entre processos/containers.
- MongoDB: armazena os dados coletados (coleções por entidade/aba e uma coleção unificada do processo).
- FastAPI: interface simples para enfileirar uma faixa de IDs de incidentes do STF.

```mermaid
flowchart LR
  UI[FastAPI /] -->|POST /produce| Celery[Broker RabbitMQ]
  Celery -->|tasks_processo.processar| Worker1[Celery Worker]
  Celery -->|tasks_abas.processar| Worker1
  Worker1 -->|HTTP requests| STF[(Portal STF)]
  Worker1 --> Redis[(Redis - Rate Limit)]
  Worker1 --> Mongo[(MongoDB)]
```


## Estrutura do Projeto

Arquivos e diretórios relevantes em `STF_proj/`:

- `docker-compose.yaml`: orquestra Mongo, RabbitMQ, Redis e o container do worker (expõe a interface FastAPI na porta 80).
- `celery_worker.Dockerfile`: imagem do worker (Celery + FastAPI).
- `celery_app.py`: configuração do Celery (broker, backend, filas/rotas e políticas padrão de retry/rate).
- `coletor_range_ids.py`: app FastAPI com HTML simples para enfileirar intervalos de incidentes.
- `coleta_processo.py`: tarefa principal que coleta a página central do processo e dispara as tarefas de abas.
- `coleta_aba.py`: tarefas que coletam cada aba (andamentos, deslocamentos, info, partes, recursos, sessão virtual).
- `scrapping_codes/`: parsers de HTML/JSON por aba (`andamentos.py`, `deslocamentos.py`, `informacoes.py`, `partes.py`, `recursos.py`, `sessao.py`).
- `rate_limiter.py`: limitador de taxa com Redis (janela deslizante) e utilitários.
- `config_rate_limit.py`: centraliza configuração de rate limiting, delays, retry e concorrência (lidos de .env).
- `connect_mongo.py`: inicializa connection pool e índices, expõe `MongoDBDatabase.get_db()`.
- `requirements.txt`: dependências do worker.
- `requirements_coletor_ids.txt`: dependências mínimas para rodar apenas o app FastAPI de enfileiramento.
- `README_RATE_LIMITING.md`: documentação detalhada do módulo de rate limiting.


## Serviços e Dependências

- Python 3.12+ (nos containers)
- RabbitMQ 3 (imagem `rabbitmq:3-management`)
- MongoDB (imagem `mongo:latest`) + Mongo Express opcional
- Redis 7 (imagem `redis:7-alpine`)
- Celery 5.3.x
- FastAPI + Uvicorn
- Requests, BeautifulSoup4, fake-useragent
- PyMongo e python-dotenv

As versões estão fixadas em `requirements.txt` e `requirements_coletor_ids.txt`.


## Variáveis de Ambiente (.env)

Crie um arquivo `.env` na raiz `STF_proj/` com, no mínimo:

```env
# RabbitMQ
RABBITMQ_DEFAULT_USER=guest
RABBITMQ_DEFAULT_PASS=guest
CELERY_BROKER_URL=amqp://guest:guest@rabbitmq:5672//

# MongoDB
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=example
MONGO_DB=stf
MONGO_HOST=mongo
MONGO_PORT=27017
CELERY_RESULT_BACKEND=mongodb://root:example@mongo:27017/celery_results?authSource=admin

# Redis (Rate Limiter)
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0

# Rate limiting e comportamento de tarefas
MAX_REQUESTS_PER_MINUTE=30
MIN_DELAY_PROCESSO=2.0
MAX_DELAY_PROCESSO=5.0
MIN_DELAY_ABA=1.0
MAX_DELAY_ABA=3.0
RETRY_COUNTDOWN_SECONDS=300
MAX_RETRIES=5
REQUEST_TIMEOUT=13
WORKER_CONCURRENCY=2
WORKER_PREFETCH_MULTIPLIER=1
RATE_LIMITER_MAX_WAIT=300

# Mongo Express (opcional)
ME_CONFIG_MONGODB_ADMINUSERNAME=root
ME_CONFIG_MONGODB_ADMINPASSWORD=example
ME_CONFIG_BASICAUTH_USERNAME=admin
ME_CONFIG_BASICAUTH_PASSWORD=admin
```

Observação: o `docker-compose.yaml` lê essas variáveis do `.env` automaticamente.


## Como executar (Docker Compose)

1. Construir e subir os serviços:

```bash
docker-compose up -d --build
```

2. Checar status:

```bash
docker-compose ps
```

3. Acessos úteis:

- FastAPI (UI simples): http://localhost:80
- RabbitMQ Management: http://localhost:15672 (guest/guest ou conforme .env)
- Mongo Express: http://localhost:8081 (credenciais do .env)

4. Logs do worker:

```bash
docker-compose logs -f celery_worker
```


## Interface Web (FastAPI) e Filas Celery

- A UI exposta em `coletor_range_ids.py` oferece um formulário para enviar um intervalo de IDs [start_id, end_id].
- Ao enviar, a função `enqueue_range_ids()` chama `celery_app.send_task('tasks_processo.processar', args=[str(i)])` para cada ID.
- O container do worker expõe a FastAPI na porta 8000, mapeada para 80 no host (`docker-compose.yaml`).

Endpoints:

- `GET /` (HTML) – formulário para intervalo de IDs.
- `POST /produce` – enfileira as tarefas para o intervalo informado.


## Fluxo de Coleta (Workflow)

1. Usuário enfileira IDs via UI (`/produce`) ou manualmente via Celery.
2. A tarefa `tasks_processo.processar` (em `coleta_processo.py`):
   - Aguarda slot no rate limiter (chave global `stf_global`).
   - Faz GET em `https://portal.stf.jus.br/processos/verImpressao.asp?imprimir=true&incidente={id}` com UA rotativo e timeout controlado.
   - Faz parse da página central via `coletar_central()` e salva no Mongo (`processos` e `processos_unificados`).
   - Dispara as tarefas de abas via `app.send_task('tasks_abas.processar', args=[id, aba])` para cada uma das abas.
3. A tarefa `tasks_abas.processar` (em `coleta_aba.py`):
   - Aguarda slot no rate limiter (chave global `stf_global`).
   - Monta a URL da aba e faz a requisição com delays aleatórios.
   - Para `sessao`, consome JSON de `https://sistemas.stf.jus.br/repgeral/votacao?oi={id}` e, para cada sessão, consome `...votacao?sessaoVirtual={sessao_virtual_id}`.
   - Para as demais abas, faz parse de HTML usando `scrapping_codes/*.py` e persiste no Mongo.

Filas/Rotas Celery:

- Em `celery_app.py`:
  - `tasks_processo.*` -> fila `processo`
  - `tasks_abas.*` -> fila `abas`

Políticas Celery (config padrão):

- `task_default_rate_limit = f"{config.MAX_REQUESTS_PER_MINUTE}/m"`
- `task_acks_late = True`
- `worker_prefetch_multiplier = 1`
- Retry com `RETRY_COUNTDOWN_SECONDS` e `MAX_RETRIES`.


## Rate Limiting

- Implementado em `rate_limiter.py` com Redis via algoritmo de janela deslizante.
- Chave global: `stf_global` (usada tanto em `tasks_processo` quanto em `tasks_abas`).
- Principais métodos:
  - `can_make_request(key)` – verifica e consome um slot.
  - `wait_for_available_slot(key, max_wait_time)` – aguarda até liberar slot.
  - `get_current_usage(key)` – métricas atuais da janela.
- Parâmetros são centralizados em `config_rate_limit.py` (lidos do `.env`).
- Há documentação adicional em `README_RATE_LIMITING.md`.


## Persistência no MongoDB (Modelo de Dados)

Conexão e índices:

- `connect_mongo.py` configura `MongoDBDatabase` com host/porta/DB do `.env` e cria índices `id_incidente` nas coleções `processos` e `processos_unificados`.

Coleções principais:

- `processos` – documento com os campos centrais do processo (ex.: `classe_numero`, `numero_unico`, `classe_processo`, `relator`, etc.) e `id_incidente`.
- `processos_unificados` – documento agregado por `id_incidente`:
  - Recebe os campos centrais (igual a `processos`).
  - Recebe `set` das estruturas de cada aba, por exemplo: `{"andamentos": [...], "deslocamentos": [...], "informacoes": {...}, "partes": [...], "recursos": [...], "sessoes_virtuais": [...]}`.
- Coleções por aba (conforme inserções de `coleta_aba.py`): `andamentos`, `deslocamentos`, `info`, `partes`, `recursos`, `sessao`.
  - Cada inserção guarda `{ id_incidente: <int>, dados: <dict-ou-list> }`.

Observações:

- Em `coleta_aba.salvar_dados_mongo()`, além de inserir na coleção específica, há um `update_one` em `processos_unificados` com `$set` do dicionário retornado pelo parser da aba.


## Como rodar localmente (sem Docker)

Pré-requisitos: RabbitMQ, Redis e MongoDB rodando localmente, e um arquivo `.env` populado.

1. Instalar dependências do worker:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

2. Iniciar o worker Celery (exemplo):

```bash
celery -A celery_app.app worker -Q processo,abas --loglevel=INFO
```

3. Rodar a interface de enfileiramento:

```bash
pip install -r requirements_coletor_ids.txt
uvicorn coletor_range_ids:app --host 0.0.0.0 --port 8000 --reload
```

4. Enfileirar um ID manualmente (shell Python):

```bash
python - <<'PY'
from celery_app import app
app.send_task('tasks_processo.processar', args=['123456'])
PY
```


## Observabilidade e Logs

- Celery/Worker: `docker-compose logs -f celery_worker`
- RabbitMQ: painel em `:15672` mostra filas `processo` e `abas`.
- Rate limiting: os workers logam eventos `[RateLimiter] ALLOW/DENY/SLOT ACQUIRED` e você pode consultar `config_rate_limit.py` para imprimir as configurações ativas (`python config_rate_limit.py`).


## Solução de Problemas

- Redis indisponível: o rate limiter se desativa com warning e permite requisições (comportamento fail-open). Verifique container/logs do Redis.
- Muitos 429/403/5xx do portal STF: reduza `MAX_REQUESTS_PER_MINUTE`, aumente `MIN/MAX_DELAY_*`, diminua `WORKER_CONCURRENCY` e aumente `RETRY_COUNTDOWN_SECONDS`.
- Timeouts: aumente `REQUEST_TIMEOUT` e/ou o countdown de retry.
- Conexão Mongo: valide `MONGO_*` no `.env`. O `connect_mongo.py` usa `MONGO_HOST`, `MONGO_PORT`, `MONGO_DB`, `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`.
- UA rotativo: depende de `fake-useragent`. Se ocorrerem erros de inicialização/seed, fixe uma UA manualmente temporariamente.


## Avisos Importantes

- Respeite as políticas de acesso do STF. Mantenha limites conservadores em produção.
- Teste em ambiente de desenvolvimento antes de alterar parâmetros agressivamente.
- Dados e formatos de HTML/JSON do STF podem mudar; trate parseadores com tolerância a mudanças.
