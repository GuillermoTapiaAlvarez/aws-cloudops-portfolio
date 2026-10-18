# EC2 and Nginx Web Server

## Overview

This lab deploys an Amazon Linux 2023 EC2 instance inside the custom AWS VPC created for the CloudOps portfolio.

The instance is placed in the public subnet and configured as a simple Nginx web server.

The goal of this lab is to practice:

- EC2 instance deployment
- Security groups
- SSH authentication
- Linux administration
- systemd service management
- Nginx installation and configuration
- Public vs private IP addressing
- Basic web-server troubleshooting

---

## EC2 Configuration

### Instance

- Name: `cloudops-web-01`
- Operating system: Amazon Linux 2023
- Architecture: x86_64
- Instance type: `t3.micro`
- VPC: `cloudops-vpc`
- Subnet: `public-subnet-a`
- Auto-assigned public IPv4: Enabled

The instance also receives a private IP address from the public subnet CIDR:

```text
10.10.1.0/24