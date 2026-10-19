resource "aws_vpc" "cloudops" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "cloudops-vpc-tf"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.cloudops.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a-tf"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.cloudops.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "private-subnet-a-tf"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = "cloudops-web-key-2"

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install nginx -y
    systemctl enable nginx
    systemctl start nginx

    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head>
        <title>AWS CloudOps Portfolio</title>
    </head>
    <body>
        <h1>AWS CloudOps Portfolio - Terraform</h1>
        <p>This EC2 instance was provisioned using Terraform.</p>
        <p>Nginx was installed automatically using EC2 user data.</p>
    </body>
    </html>
    HTML
  EOF

  tags = {
    Name = "cloudops-web-01-tf"
  }

  depends_on = [
    aws_route_table_association.public_a
  ]
}

resource "aws_internet_gateway" "cloudops" {
  vpc_id = aws_vpc.cloudops.id

  tags = {
    Name = "cloudops-igw-tf"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cloudops.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudops.id
  }

  tags = {
    Name = "public-rt-tf"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.cloudops.id

  tags = {
    Name = "private-rt-tf"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "web" {
  name        = "cloudops-web-sg-tf"
  description = "Allow SSH from home and HTTP from the internet"
  vpc_id      = aws_vpc.cloudops.id

  ingress {
    description = "SSH from home"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "Allow public HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloudops-web-sg-tf"
  }
}