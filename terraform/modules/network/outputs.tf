output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "kafka_sg_id" {
  value = aws_security_group.kafka.id
}

output "mongodb_sg_id" {
  value = aws_security_group.mongodb.id
}

output "app_sg_id" {
  value = aws_security_group.app.id
}
