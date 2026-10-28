variable "aws_region" {
  description = "AWS region for the CloudOps environment"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.10.11.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for the subnets"
  type        = string
  default     = "us-east-2a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the web server"
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for the second private subnet"
  type        = string
  default     = "10.10.12.0/24"
}

variable "availability_zone_b" {
  description = "Second Availability Zone for database subnet placement"
  type        = string
  default     = "us-east-2b"
}

variable "ami_id" {
  description = "Pinned Amazon Linux 2023 AMI ID"
  type        = string
  default     = "ami-01cb65bdf4b589c2d"
}
