output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.network.vpc_id
}

output "kafka_endpoint" {
  description = "Kafka broker endpoint"
  value       = module.kafka.kafka_endpoint
}

output "mongodb_endpoint" {
  description = "MongoDB public endpoint"
  value       = module.mongodb.mongodb_endpoint
}

output "process_regions" {
  description = "Regions where coleta_processo is actively deployed"
  value       = var.active_process_regions
}

output "tabs_regions" {
  description = "Regions where coleta_aba is actively deployed"
  value       = var.active_tabs_regions
}

output "process_instances" {
  description = "Number of coleta_processo instances per region"
  value       = var.process_replicas_per_region
}

output "tabs_instances" {
  description = "Number of coleta_aba instances per region"
  value       = var.tabs_replicas_per_region
}

output "ssh_command_kafka" {
  description = "SSH command to connect to Kafka instance"
  value       = "ssh -i ${var.ssh_key_name}.pem ec2-user@${module.kafka.kafka_endpoint}"
}

output "ssh_command_mongodb" {
  description = "SSH command to connect to MongoDB instance"
  value       = "ssh -i ${var.ssh_key_name}.pem ec2-user@${module.mongodb.mongodb_endpoint}"
}
