output "kafka_instance_id" {
  description = "ID of the Kafka EC2 instance"
  value       = aws_instance.kafka_zookeeper.id
}

output "kafka_private_ip" {
  description = "Private IP address of the Kafka instance"
  value       = aws_instance.kafka_zookeeper.private_ip
}

output "kafka_endpoint" {
  description = "Endpoint for Kafka clients to connect to"
  value       = aws_instance.kafka_zookeeper.private_ip
}
