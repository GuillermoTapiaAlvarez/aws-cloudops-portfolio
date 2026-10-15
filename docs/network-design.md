# Phase 1 Network Design

## VPC

CIDR:

10.10.0.0/16

## Subnets

| Subnet | CIDR | Purpose |
|---|---|---|
| Public Subnet A | 10.10.1.0/24 | Public-facing resources |
| Private Subnet A | 10.10.11.0/24 | Internal resources |

## Planned Resources

- VPC
- Internet Gateway
- Public route table
- Private route table
- Security group
- EC2 Linux instance
- Nginx web server

## Architecture

Internet  
↓  
Internet Gateway  
↓  
VPC 10.10.0.0/16  
├── Public Subnet — 10.10.1.0/24  
│   └── EC2 Linux + Nginx  
└── Private Subnet — 10.10.11.0/24  

## Notes

The public subnet will have a route to the Internet Gateway.

The private subnet will not initially have direct internet access.

This environment will first be created manually in AWS and later recreated using Terraform.

## Implemented Resources

- VPC: `cloudops-vpc`
- VPC CIDR: `10.10.0.0/16`
- Public subnet: `10.10.1.0/24`
- Private subnet: `10.10.11.0/24`
- Internet Gateway: `cloudops-igw`
- Public route table:
  - `10.10.0.0/16 -> local`
  - `0.0.0.0/0 -> Internet Gateway`
- Private route table:
  - `10.10.0.0/16 -> local`

## Networking Notes

A subnet is considered public when its route table contains a default route to an Internet Gateway.

The private subnet does not have a default route to the Internet Gateway.