# STF Data Collector

Sistema de raspagem de dados do STF (Supremo Tribunal Federal) baseado em Docker Compose, com filas via RabbitMQ, workers Celery e armazenamento em MongoDB.

## Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                        Docker Compose                        │
│                                                             │
│  ┌──────────────┐    ┌───────────────────────────────────┐  │
│  │   RabbitMQ   │◄───│  celery_worker                    │  │
│  │  :5672       │    │  ├─ FastAPI (interface web) :8000  │  │
│  │  :15672 (UI) │    │  └─ Celery worker (raspagem STF)  │  │
│  └──────────────┘    └───────────────────────────────────┘  │
│                                        │                     │
│  ┌──────────────┐    ┌─────────────────▼─────────────────┐  │
│  │ mongo-express│    │          MongoDB :27017            │  │
│  │  :8081       │───►│  banco: stf_data                  │  │
│  └──────────────┘    └───────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Portas expostas no host:**

| Serviço        | Porta host | Descrição                              |
|----------------|-----------|----------------------------------------|
| FastAPI         | 80        | Interface para enfileirar processos    |
| RabbitMQ UI    | 15672     | Painel de monitoramento de filas       |
| RabbitMQ AMQP  | 5672      | Broker Celery (uso interno)            |
| MongoDB         | 27017     | Banco de dados (uso interno)           |
| mongo-express  | 8081      | Interface web do MongoDB               |

---

## Pré-requisitos

- Docker e Docker Compose instalados
- Git

---

## Para rodar na máquina local

### 1. Clone o repositório

```bash
git clone https://github.com/esdrasgc/STF_proj.git
cd STF_proj
```

### 2. Configure as variáveis de ambiente

Copie o arquivo de exemplo e ajuste as credenciais conforme necessário:

```bash
cp .env.example .env
```

Edite o `.env` com suas credenciais. Os valores do `.env.example` funcionam para desenvolvimento local.

> **Atenção:** Altere as senhas antes de subir em qualquer ambiente exposto à internet.

### 3. Suba os containers

```bash
docker compose up -d --build
```

Aguarde todos os serviços ficarem saudáveis (especialmente o RabbitMQ, que pode demorar alguns segundos).

### 4. Acesse a interface de coleta

Abra no navegador: [http://localhost:80](http://localhost:80)

Informe o intervalo de IDs de incidentes do STF que deseja raspar e clique em **Enviar para raspagem**. Os IDs serão enfileirados no RabbitMQ e processados pelos workers Celery.

### 5. Monitore o progresso

- **Filas RabbitMQ (terminal):**
  ```bash
  docker exec rabbitmq rabbitmqctl list_queues name messages
  ```
  Quando a coluna `messages` for `0` para todas as filas, a coleta terminou.

- **Painel RabbitMQ:** [http://localhost:15672](http://localhost:15672) (credenciais definidas no `.env`)

- **Dados coletados (mongo-express):** [http://localhost:8081](http://localhost:8081)

### 6. Exporte os dados

Após a coleta, use o script `download_stf_data.sh` adaptado para localhost, ou conecte diretamente ao MongoDB:

```bash
# Exemplo direto via mongoexport
docker exec mongo mongoexport \
  --username root --password example \
  --authenticationDatabase admin \
  --db stf_data --collection processos --quiet \
  | gzip > stf_data_processos.jsonl.gz
```

---

## Para rodar em uma máquina na AWS

> **Importante:** O STF bloqueia IPs de outras clouds (GCP, Azure, etc.). **Somente instâncias EC2 da AWS funcionam** para a raspagem.

### 1. Crie a instância EC2

- **AMI recomendada:** Ubuntu Server 22.04 LTS ou 24.04 LTS
- **Tipo:** `t3.medium` ou superior (a raspagem é intensiva em CPU/rede)
- **Armazenamento:** mínimo 20 GB (MongoDB pode crescer bastante dependendo do volume)
- **Par de chaves:** crie ou reutilize um par `.pem` para acesso SSH

### 2. Configure o Security Group

Adicione as seguintes regras de entrada (inbound) no Security Group da instância:

| Tipo       | Protocolo | Porta | Origem         | Descrição                        |
|------------|-----------|-------|----------------|----------------------------------|
| SSH        | TCP       | 22    | Seu IP         | Acesso SSH à instância           |
| HTTP       | TCP       | 80    | Seu IP         | Interface de enfileiramento      |
| Custom TCP | TCP       | 15672 | Seu IP         | Painel RabbitMQ (opcional)       |
| Custom TCP | TCP       | 8081  | Seu IP         | mongo-express (opcional)         |

> **Dica de segurança:** Restrinja a origem ao seu IP (`Meu IP` no console AWS) em vez de `0.0.0.0/0`. A porta 27017 (MongoDB) **não deve** ser exposta publicamente.

### 3. Conecte-se à instância via SSH

```bash
ssh -i "sua-chave.pem" ubuntu@<IP_PÚBLICO_DA_INSTÂNCIA>
```

### 4. Instale Docker na instância

```bash
sudo apt update && sudo apt install -y docker.io docker-compose-plugin
sudo usermod -aG docker ubuntu
# Reconecte o SSH para aplicar o grupo
exit
ssh -i "sua-chave.pem" ubuntu@<IP_PÚBLICO_DA_INSTÂNCIA>
```

### 5. Clone e configure o projeto

```bash
git clone https://github.com/esdrasgc/STF_proj.git
cd STF_proj
cp .env.example .env
```

Edite o `.env` com credenciais seguras:

```bash
nano .env
```

### 6. Suba os containers

```bash
docker compose up -d --build
```

### 7. Acesse a interface de coleta

Abra no navegador: `http://<IP_PÚBLICO_DA_INSTÂNCIA>:80`

> A porta 80 precisa estar liberada no Security Group (passo 2).

Informe o intervalo de IDs e clique em **Enviar para raspagem**.

### 8. Monitore e aguarde a conclusão

Conectado via SSH, verifique quando as filas estiverem vazias:

```bash
docker exec rabbitmq rabbitmqctl list_queues name messages
```

Exemplo de saída quando a coleta terminou:

```
Listing queues for vhost / ...
name     messages
abas     0
processo 0
```

### 9. Baixe os dados para sua máquina local

Com a coleta concluída, use o script `download_stf_data.sh` **a partir da sua máquina local**:

```bash
# Edite as variáveis no topo do script conforme necessário:
# KEY  → caminho para o arquivo .pem
# HOST → ubuntu@<IP_PÚBLICO_DA_INSTÂNCIA>
# USER/PASS → credenciais do MongoDB definidas no .env

./download_stf_data.sh
```

O script exporta cada coleção do banco `stf_data` via SSH e salva localmente como arquivos `.jsonl.gz`:

```
stf_data_deslocamentos.jsonl.gz
stf_data_recursos.jsonl.gz
stf_data_processos.jsonl.gz
stf_data_partes.jsonl.gz
stf_data_processos_unificados.jsonl.gz
stf_data_andamentos.jsonl.gz
stf_data_info.jsonl.gz
```

### 10. Encerre a instância após o uso

Lembre-se de **parar ou encerrar** a instância EC2 após a coleta para evitar custos desnecessários.

```bash
# Ou faça pelo console AWS
aws ec2 stop-instances --instance-ids <INSTANCE_ID>
```

---

## Variáveis de ambiente

| Variável                     | Descrição                                   | Padrão                    |
|------------------------------|---------------------------------------------|---------------------------|
| `MONGO_INITDB_ROOT_USERNAME` | Usuário root do MongoDB                     | `root`                    |
| `MONGO_INITDB_ROOT_PASSWORD` | Senha root do MongoDB                       | `example`                 |
| `MONGO_DB`                   | Nome do banco de dados                      | `stf_data`                |
| `CELERY_BROKER_URL`          | URL do broker RabbitMQ                      | `amqp://guest:guest@...`  |
| `CELERY_RESULT_BACKEND`      | URL do backend de resultados (MongoDB)      | `mongodb://root:...`      |
| `RABBITMQ_DEFAULT_USER`      | Usuário padrão do RabbitMQ                  | `guest`                   |
| `RABBITMQ_DEFAULT_PASS`      | Senha padrão do RabbitMQ                    | `guest`                   |
| `WORKER_CONCURRENCY`         | Número de workers Celery em paralelo        | `1`                       |
| `WORKER_PREFETCH_MULTIPLIER` | Prefetch de tarefas por worker              | `1`                       |
| `ME_CONFIG_BASICAUTH_USERNAME` | Usuário de acesso ao mongo-express        | `admin`                   |
| `ME_CONFIG_BASICAUTH_PASSWORD` | Senha de acesso ao mongo-express          | `admin`                   |
