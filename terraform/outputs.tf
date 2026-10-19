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