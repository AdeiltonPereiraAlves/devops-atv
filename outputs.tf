# -----------------------------------------------------------------------------
# Outputs - Informações após o terraform apply
# -----------------------------------------------------------------------------

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.web.public_ip
}

output "ec2_public_dns" {
  description = "DNS público da instância EC2"
  value       = aws_instance.web.public_dns
}

output "nginx_url" {
  description = "URL para acessar o NGINX no navegador"
  value       = "http://${aws_instance.web.public_ip}"
}

output "s3_bucket_name" {
  description = "Nome do bucket S3 criado"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.main.arn
}
