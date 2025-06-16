# --- Variáveis Gerais ---
variable "aws_region" {
  description = "A única região da AWS onde toda a infraestrutura será criada."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto para nomear os recursos (ex: stf-coleta)."
  type        = string
  default     = "stf-coleta"
}

# --- Variáveis das Instâncias ---
variable "processo_collector_count" {
  description = "Número de instâncias para a 'coleta-processo'."
  type        = number
  default     = 2
}

variable "aba_collector_count" {
  description = "Número de instâncias para a 'coleta-aba'."
  type        = number
  default     = 8
}

variable "kafka_instance_type" {
  description = "Tipo da instância EC2 para o Kafka."
  type        = string
  default     = "t3.small"
}

variable "collector_instance_type" {
  description = "Tipo da instância EC2 para os coletores."
  type        = string
  default     = "t3.micro"
}


# --- Variáveis do MongoDB (para o Secrets Manager) ---
variable "mongo_user" {
  description = "Usuário do banco de dados MongoDB."
  type        = string
  sensitive   = true
}

variable "mongo_password" {
  description = "Senha do banco de dados MongoDB."
  type        = string
  sensitive   = true
}

variable "mongo_cluster_url" {
  description = "URL do cluster MongoDB (ex: cluster.abcde.mongodb.net)."
  type        = string
}

variable "mongo_database_name" {
  description = "Nome do banco de dados a ser usado."
  type        = string
}
