# Variáveis para a configuração da rede e da região central.
variable "central_region" {
  description = "A região da AWS para hospedar os serviços centrais (Kafka, etc.)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto para nomear os recursos (ex: stf-coleta)."
  type        = string
  default     = "stf-coleta"
}

# Lista de regiões onde as instâncias coletoras de 'processo' serão implantadas.
variable "processo_collector_regions" {
  description = "Lista de regiões da AWS para os coletores de processo."
  type        = list(string)
  default     = ["us-west-1", "sa-east-1"]
}

# Lista de regiões onde as instâncias coletoras de 'aba' serão implantadas.
variable "aba_collector_regions" {
  description = "Lista de regiões da AWS para os coletores de aba."
  type        = list(string)
  default     = ["us-west-2", "us-east-2", "ca-central-1", "eu-west-1", "eu-west-2", "eu-central-1", "ap-southeast-1", "ap-northeast-1"]
}

# Variáveis para a configuração das instâncias EC2.
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

# Variáveis para as imagens Docker no ECR.
variable "coleta_processo_image_name" {
  description = "Nome do repositório ECR para a imagem 'coleta-processo'."
  type        = string
  default     = "coleta-processo"
}

variable "coleta_aba_image_name" {
  description = "Nome do repositório ECR para a imagem 'coleta-aba'."
  type        = string
  default     = "coleta-aba"
}
