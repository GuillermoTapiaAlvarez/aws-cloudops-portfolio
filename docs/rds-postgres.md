# Private RDS PostgreSQL Integration

## Overview

The next phase of the CloudOps portfolio added a private PostgreSQL database using Amazon RDS.

The goal was to build a more realistic application architecture where:

- The EC2 web server remains publicly reachable
- The database remains private
- PostgreSQL is reachable only from the EC2 application tier
- Database credentials are generated and managed by AWS
- The EC2 instance retrieves credentials using its IAM role
- No database password is stored in Terraform or GitHub

The resulting architecture is:

```text
Internet
   |
   | HTTP 80
   v
Public EC2 / Nginx
   |
   | PostgreSQL 5432
   v
Private RDS PostgreSQL
```

---

# 1. Add a Second Private Subnet

The original VPC contained:

```text
VPC:               10.10.0.0/16
public-subnet-a:    10.10.1.0/24    us-east-2a
private-subnet-a:   10.10.11.0/24   us-east-2a
```

A second private subnet was added:

```text
private-subnet-b:   10.10.12.0/24   us-east-2b
```

This allows the RDS subnet group to span multiple Availability Zones.

The following variables were added to `variables.tf`:

```hcl
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
```

The second private subnet was added to `main.tf`:

```hcl
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.cloudops.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = var.availability_zone_b

  tags = {
    Name = "private-subnet-b-tf"
  }
}
```

It was associated with the existing private route table:

```hcl
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
```

---

# 2. Create the RDS Subnet Group

RDS requires a DB subnet group to define which subnets may host database resources.

The subnet group contains both private subnets:

```hcl
resource "aws_db_subnet_group" "cloudops" {
  name = "cloudops-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "cloudops-db-subnet-group"
  }
}
```

This allows RDS to use private subnets across:

```text
us-east-2a
us-east-2b
```

---

# 3. Create the Database Security Group

A dedicated security group was created for the PostgreSQL database:

```hcl
resource "aws_security_group" "database" {
  name        = "cloudops-db-sg-tf"
  description = "Allow PostgreSQL from the web server only"
  vpc_id      = aws_vpc.cloudops.id

  ingress {
    description     = "PostgreSQL from web server"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloudops-db-sg-tf"
  }
}
```

The important security rule is:

```hcl
security_groups = [aws_security_group.web.id]
```

Instead of allowing PostgreSQL from an IP range, the rule allows traffic only from resources using the EC2 web-server security group.

The database is therefore not exposed to the public internet.

The network path is:

```text
Internet
   |
   | TCP 80
   v
Web Security Group
   |
EC2
   |
   | TCP 5432
   v
Database Security Group
   |
RDS PostgreSQL
```

---

# 4. Pin the EC2 AMI

While preparing the database changes, Terraform unexpectedly planned to replace the EC2 instance.

The plan showed:

```text
aws_instance.web must be replaced
```

and:

```text
ami = "ami-OLD" -> "ami-NEW" # forces replacement
```

The EC2 configuration was using an AMI data source with:

```hcl
most_recent = true
```

Because AWS had released a newer Amazon Linux 2023 AMI, Terraform automatically selected the newer image.

Changing the AMI on an existing EC2 instance requires replacement.

This demonstrated an important Infrastructure-as-Code issue:

```text
Dynamic "latest" dependency
        |
New AMI released
        |
Terraform detects change
        |
Unexpected EC2 replacement
```

To make upgrades intentional, the AMI was pinned.

The currently running AMI was identified with:

```bash
terraform state show aws_instance.web | grep -E "^[[:space:]]*ami"
```

A variable was added:

```hcl
variable "ami_id" {
  description = "Pinned Amazon Linux 2023 AMI ID"
  type        = string
  default     = "CURRENT_TESTED_AMI_ID"
}
```

The EC2 resource was changed from:

```hcl
ami = data.aws_ami.amazon_linux.id
```

to:

```hcl
ami = var.ami_id
```

The old dynamic AMI data source was removed.

After the change:

```bash
terraform fmt
terraform validate
terraform plan
```

returned a clean plan without EC2 replacement.

This means future AMI upgrades must be intentional and reviewed before deployment.

---

# 5. Create the PostgreSQL RDS Instance

A PostgreSQL RDS instance was added:

```hcl
resource "aws_db_instance" "postgres" {
  identifier = "cloudops-postgres-tf"

  engine         = "postgres"
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 25
  storage_type          = "gp3"

  db_name  = "cloudops"
  username = "cloudopsadmin"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.cloudops.name
  vpc_security_group_ids = [aws_security_group.database.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "cloudops-postgres-tf"
  }
}
```

Important settings include:

```hcl
publicly_accessible = false
```

This prevents the RDS instance from being publicly exposed.

```hcl
manage_master_user_password = true
```

This instructs AWS to generate and manage the database master password using Secrets Manager.

The password is therefore not stored directly in Terraform configuration.

```hcl
multi_az = false
```

Multi-AZ deployment was disabled to reduce cost for this lab environment.

The subnet group still spans multiple Availability Zones.

---

# 6. Add Database Outputs

Terraform outputs were added:

```hcl
output "db_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "db_address" {
  description = "RDS PostgreSQL hostname"
  value       = aws_db_instance.postgres.address
}
```

After deployment:

```bash
terraform output
```

returned the RDS hostname and endpoint.

Example structure:

```text
db_address  = cloudops-postgres-tf.xxxxx.us-east-2.rds.amazonaws.com
db_endpoint = cloudops-postgres-tf.xxxxx.us-east-2.rds.amazonaws.com:5432
```

---

# 7. Verify Private Database Connectivity

The Terraform EC2 instance was accessed through AWS Systems Manager Session Manager.

Network connectivity to PostgreSQL was tested with:

```bash
nc -zv cloudops-postgres-tf.xxxxx.us-east-2.rds.amazonaws.com 5432
```

The test returned:

```text
Ncat: Connected to 10.10.11.197:5432.
```

This confirmed:

- RDS DNS resolution worked
- The hostname resolved to a private VPC IP
- The EC2 instance could reach RDS
- TCP port 5432 was reachable
- The database security group allowed traffic from the EC2 security group

The database endpoint resolving to:

```text
10.10.11.197
```

confirmed that communication remained inside the VPC.

---

# 8. Allow EC2 to Retrieve the Database Secret

The EC2 IAM role already had permissions for:

```text
AmazonSSMManagedInstanceCore
CloudWatchAgentServerPolicy
```

A new inline IAM policy was added so the EC2 instance could retrieve only the RDS-managed secret.

```hcl
resource "aws_iam_role_policy" "rds_secret_access" {
  name = "cloudops-rds-secret-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_db_instance.postgres.master_user_secret[0].secret_arn
      }
    ]
  })
}
```

This follows least-privilege principles.

The EC2 instance can retrieve:

```text
Only the PostgreSQL RDS master secret
```

instead of:

```text
Every secret in the AWS account
```

---

# 9. Output the Secret ARN

The RDS secret ARN was added as a Terraform output:

```hcl
output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master credentials"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}
```

The ARN was retrieved with:

```bash
terraform output db_secret_arn
```

The ARN identifies the secret but does not expose the password itself.

---

# 10. Install the PostgreSQL Client

The PostgreSQL client was installed on the EC2 instance:

```bash
sudo dnf install postgresql15 -y
```

The installation was verified:

```bash
psql --version
```

---

# 11. Retrieve Credentials from Secrets Manager

From the EC2 Session Manager shell:

```bash
aws secretsmanager get-secret-value \
  --secret-id SECRET_ARN \
  --query SecretString \
  --output text
```

The EC2 instance was able to retrieve the secret using its IAM role.

The returned JSON contained information such as:

```json
{
  "username": "cloudopsadmin",
  "password": "REDACTED",
  "engine": "postgres",
  "host": "RDS_ENDPOINT",
  "port": 5432,
  "dbname": "cloudops"
}
```

The database password was not stored in:

```text
Terraform source code
GitHub
EC2 user data
Local configuration files
```

---

# 12. Connect to PostgreSQL

The PostgreSQL client was used to connect to RDS:

```bash
psql \
  -h cloudops-postgres-tf.xxxxx.us-east-2.rds.amazonaws.com \
  -U cloudopsadmin \
  -d cloudops
```

The password retrieved from Secrets Manager was entered when prompted.

A successful connection changed the shell prompt to:

```text
cloudops=>
```

The database was verified with:

```sql
SELECT current_database();
```

The authenticated user was verified with:

```sql
SELECT current_user;
```

The connection was exited with:

```text
\q
```

---

# 13. End-to-End Validation

The completed authentication path is:

```text
EC2 instance
   |
   | IAM instance role
   v
AWS Secrets Manager
   |
   | GetSecretValue
   v
RDS-managed credentials
   |
   v
PostgreSQL client
   |
   | TCP 5432
   v
Database security group
   |
   v
Private RDS PostgreSQL
```

This successfully validated:

- Private RDS deployment
- Private DNS resolution
- Security-group-to-security-group access
- PostgreSQL connectivity
- IAM instance-role permissions
- Secrets Manager integration
- Least-privilege access
- Secure credential retrieval
- Actual authenticated database login

---

# 14. Security Improvements

The database design avoids several insecure patterns.

The project does not use:

```text
Public RDS access
0.0.0.0/0 access to PostgreSQL
Hard-coded database passwords
Passwords committed to GitHub
AWS access keys stored on EC2
Direct SSH administration
```

Instead, it uses:

```text
Private RDS networking
Security-group references
IAM instance roles
Secrets Manager
Systems Manager Session Manager
Terraform
```

---

# 15. Current Architecture

```text
                        Internet
                           |
                           | TCP 80
                           v
                 +-------------------+
                 | Public EC2        |
                 | Amazon Linux 2023 |
                 | Nginx             |
                 +-------------------+
                           |
                           | TCP 5432
                           |
                           v
                 +-------------------+
                 | RDS PostgreSQL    |
                 | Private subnet    |
                 | No public access  |
                 +-------------------+


Administrative access:

AWS authenticated identity
        |
        v
Systems Manager
        |
        v
EC2


Credential access:

EC2 IAM role
     |
     v
Secrets Manager
     |
     v
RDS credentials
```

---

# 16. Skills Demonstrated

This phase demonstrates:

- Amazon RDS
- PostgreSQL
- Private database architecture
- Multi-AZ subnet design
- DB subnet groups
- Security-group references
- Private DNS
- TCP connectivity testing
- IAM instance roles
- IAM inline policies
- Least privilege
- AWS Secrets Manager
- RDS-managed passwords
- PostgreSQL client administration
- Terraform RDS provisioning
- Terraform outputs
- AMI version pinning
- Terraform replacement troubleshooting
- Infrastructure security design