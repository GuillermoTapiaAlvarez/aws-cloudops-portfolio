output "web_public_ip" {
  description = "Public IPv4 address of the Terraform web server"
  value       = aws_instance.web.public_ip
}

output "web_private_ip" {
  description = "Private IPv4 address of the Terraform web server"
  value       = aws_instance.web.private_ip
}

output "web_url" {
  description = "HTTP URL for the Terraform web server"
  value       = "http://${aws_instance.web.public_ip}"
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master credentials"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}