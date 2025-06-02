output "mongodb_instance_id" {
  description = "ID of the MongoDB EC2 instance"
  value       = aws_instance.mongodb.id
}

output "mongodb_private_ip" {
  description = "Private IP address of the MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}

output "mongodb_endpoint" {
  description = "Public IP of the MongoDB instance"
  value       = aws_eip.mongodb_eip.public_ip
}
