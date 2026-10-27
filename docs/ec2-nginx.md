# EC2 and Nginx Web Server

## Overview

This lab deploys and configures an Amazon Linux 2023 EC2 instance inside the custom AWS VPC created for the CloudOps portfolio.

The server begins as a manually configured public web server and is later improved with:

- Nginx
- Custom web content
- CloudWatch monitoring
- CloudWatch Agent
- SNS alerting
- Centralized Nginx logs
- AWS Systems Manager Session Manager
- IAM-based instance access
- Terraform automation

The goal of this lab is to practice:

- EC2 deployment
- Security groups
- SSH
- Linux administration
- Nginx administration
- CloudWatch monitoring
- Centralized logging
- IAM roles
- Systems Manager
- Infrastructure as Code
- Troubleshooting

---

# 1. EC2 Instance Configuration

The EC2 instance was launched inside the previously created AWS network.

## Instance Settings

```text
Name: cloudops-web-01
Operating system: Amazon Linux 2023
Architecture: x86_64
Instance type: t3.micro
VPC: cloudops-vpc
Subnet: public-subnet-a
Auto-assigned public IPv4: Enabled
```

The instance receives a private IPv4 address from:

```text
10.10.1.0/24
```

An example private address used by the instance was:

```text
10.10.1.134
```

---

# 2. EC2 Key Pair

An EC2 key pair was created for initial SSH administration.

```text
Key pair: cloudops-web-key-2
Type: ED25519
Format: .pem
```

The private key was stored locally:

```text
~/.ssh/cloudops-web-key-2.pem
```

On Windows, the file was also protected using NTFS permissions so ordinary users could not read the private key.

The `.pem` file contains the private SSH key.

AWS stores the matching public key for the EC2 key pair.

The private key must never be committed to GitHub.

---

# 3. Security Group

A security group named:

```text
cloudops-web-sg
```

was created.

Initial inbound rules:

| Type | Protocol | Port | Source | Purpose |
|---|---|---:|---|---|
| SSH | TCP | 22 | Home public IP `/32` | Remote administration |
| HTTP | TCP | 80 | `0.0.0.0/0` | Public web access |

SSH access was restricted to one public IP using `/32`.

HTTP was intentionally open to the internet because the EC2 instance was acting as a public web server.

Security groups are stateful, so response traffic for established allowed connections is automatically permitted.

---

# 4. SSH Connection

The instance was initially administered through SSH.

```bash
ssh -i ~/.ssh/cloudops-web-key-2.pem ec2-user@PUBLIC_IP
```

Where:

- `ssh` starts the Secure Shell client
- `-i` specifies the private key
- `ec2-user` is the default Amazon Linux username
- `PUBLIC_IP` is the EC2 instance's current public IPv4 address

The first connection displayed an SSH host fingerprint.

This fingerprint identifies the server.

After accepting it, SSH stored the server identity in:

```text
~/.ssh/known_hosts
```

The EC2 private key proves the client's identity to the server.

The SSH host key helps prove the server's identity to the client.

---

# 5. Public and Private IP Addresses

The EC2 instance has both a public and a private IPv4 address.

The public IP is used by clients on the internet.

The private IP is used inside the AWS VPC.

```text
Laptop
   |
Internet
   |
Public IPv4
   |
AWS networking
   |
Private IPv4
   |
EC2 instance
```

Inside the server, the hostname reflected the private IP:

```text
ec2-user@ip-10-10-1-134
```

Stopping and restarting the EC2 instance can cause the auto-assigned public IPv4 address to change.

---

# 6. Verify the Operating System

The system was inspected after connecting.

```bash
uname -a
```

This displays information about:

- Linux kernel
- CPU architecture
- system platform

The Linux distribution was checked with:

```bash
cat /etc/os-release
```

The instance confirmed:

```text
Amazon Linux 2023
x86_64
```

---

# 7. Update Packages

The server packages were checked and updated with:

```bash
sudo dnf update -y
```

Where:

- `sudo` runs the command with elevated privileges
- `dnf` is the Amazon Linux package manager
- `update` checks for available package updates
- `-y` automatically confirms prompts

---

# 8. Install Nginx

Nginx was installed with:

```bash
sudo dnf install nginx -y
```

The service was started:

```bash
sudo systemctl start nginx
```

Nginx was enabled to start automatically during boot:

```bash
sudo systemctl enable nginx
```

The service status was checked with:

```bash
systemctl status nginx
```

Successful output showed:

```text
Active: active (running)
```

The `systemctl status` command opened output in a pager.

Pressing:

```text
q
```

returned to the normal shell prompt.

---

# 9. Verify Public Web Access

The EC2 instance was opened in a browser using:

```text
http://PUBLIC_IP
```

The default Nginx page confirmed that the following were working together:

```text
Browser
   |
EC2 public IPv4
   |
Security Group TCP 80
   |
Public subnet
   |
Public route table
   |
Internet Gateway
   |
Nginx
```

This validated the networking and web-server configuration end to end.

---

# 10. Identify the Nginx Web Root

The active Nginx web root was found using:

```bash
sudo nginx -T | grep root
```

The active web root was:

```text
/usr/share/nginx/html
```

The directory contents were inspected with:

```bash
ls -l /usr/share/nginx/html
```

---

# 11. Back Up the Default Page

Before modifying the default page, it was backed up:

```bash
sudo cp /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.bak
```

This provided a simple recovery option.

---

# 12. Create the Custom Portfolio Page

The main page was edited with:

```bash
sudo nano /usr/share/nginx/html/index.html
```

Example content:

```html
<!DOCTYPE html>
<html>
<head>
    <title>AWS CloudOps Portfolio</title>
</head>
<body>
    <h1>AWS CloudOps Portfolio</h1>
    <p>This web server is running on Amazon Linux 2023 in AWS EC2.</p>
    <p>Infrastructure includes a custom VPC, public and private subnets, route tables, an Internet Gateway, and security groups.</p>
</body>
</html>
```

Nano commands used:

```text
Ctrl+O   Save
Enter    Confirm filename
Ctrl+X   Exit
```

---

# 13. Compare the Custom Page to the Original

The modified page was compared to the backup:

```bash
diff /usr/share/nginx/html/index.html.bak /usr/share/nginx/html/index.html
```

In `diff` output:

```text
<   content from the first file
>   content from the second file
```

This confirmed that the original Nginx page had been replaced.

---

# 14. Local Web Server Test

The web server was also tested directly from the EC2 instance:

```bash
curl http://localhost
```

This verifies Nginx independently of the external network path.

---

# 15. Terraform Implementation

The manually built AWS environment was later recreated using Terraform.

Terraform provisioned:

- VPC
- Public subnet
- Private subnet
- Internet Gateway
- Public route table
- Private route table
- Route-table associations
- Security group
- Amazon Linux EC2 instance
- Nginx web server
- Terraform outputs

The EC2 instance was configured automatically with `user_data`.

Example:

```hcl
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
```

This changed the workflow from:

```text
Terraform creates EC2
   |
Human logs in
   |
Human installs/configures Nginx
```

to:

```text
Terraform creates EC2
   |
EC2 user data runs automatically
   |
Nginx installed
   |
Web page created
```

---

# 16. Terraform Destroy and Rebuild Test

The Terraform-managed infrastructure was intentionally destroyed:

```bash
terraform destroy
```

Terraform removed the managed resources.

The same environment was then rebuilt with:

```bash
terraform apply
```

The Nginx website successfully returned after the rebuild.

This demonstrated that the infrastructure was reproducible from code.

---

# 17. CloudWatch CPU Monitoring

CloudWatch was used to monitor EC2 CPU utilization.

A CloudWatch alarm was created using:

```text
Metric: CPUUtilization
Statistic: Average
Threshold: Greater than 70%
```

The alarm published notifications to:

```text
SNS topic: cloudops-alerts
```

---

# 18. CPU Load Testing

CPU load was generated with:

```bash
yes > /dev/null &
```

Where:

- `yes` generates continuous output
- `> /dev/null` discards the output
- `&` runs the process in the background

A `t3.micro` has two vCPUs.

One `yes` process primarily saturated one vCPU, resulting in approximately 50% total CPU utilization.

Two processes were used:

```bash
yes > /dev/null &
yes > /dev/null &
```

Processes were monitored with:

```bash
top
```

The load was stopped with:

```bash
pkill yes
```

Verification:

```bash
pgrep yes
```

No output confirmed that the load processes were stopped.

The CloudWatch alarm successfully transitioned into the alarm state and SNS delivered an email.

---

# 19. IAM Role for CloudWatch Agent

The EC2 instance required permissions to publish OS-level metrics and logs.

An IAM role was created:

```text
cloudops-ec2-cloudwatch-role
```

The role included:

```text
CloudWatchAgentServerPolicy
```

The role allowed the EC2 instance to call CloudWatch APIs using temporary credentials.

No long-lived AWS access keys were stored on the server.

---

# 20. Install CloudWatch Agent

The agent was installed with:

```bash
sudo dnf install amazon-cloudwatch-agent -y
```

Installation was verified:

```bash
rpm -qa | grep amazon-cloudwatch-agent
```

---

# 21. CloudWatch Agent Configuration

The configuration file was stored at:

```text
/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent.json
```

Final configuration:

```json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },

  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}",
      "InstanceType": "${aws:InstanceType}"
    },

    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },

      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      }
    }
  },

  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/cloudops/nginx/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/cloudops/nginx/error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
```

The agent collects:

```text
Memory utilization
Disk utilization
Nginx access logs
Nginx error logs
```

---

# 22. Start the CloudWatch Agent

The configuration was loaded and the agent started with:

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent.json
```

Agent status was checked:

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -m ec2 \
  -a status
```

Successful output showed:

```text
"status": "running"
```

---

# 23. Memory Monitoring

The CloudWatch Agent published:

```text
CWAgent
└── mem_used_percent
```

A memory alarm was created from the real `mem_used_percent` metric.

During troubleshooting, an incorrectly configured alarm remained in:

```text
Insufficient data
```

The following were checked:

- CloudWatch Agent status
- JSON configuration
- IAM role
- agent logs
- actual CWAgent metric
- recent datapoints

The alarm was recreated directly from the real `mem_used_percent` metric.

It then transitioned to:

```text
OK
```

---

# 24. Memory Load Testing

Memory pressure was generated with:

```bash
stress-ng --vm 1 --vm-bytes 75% --timeout 5m
```

and later:

```bash
stress-ng --vm 1 --vm-bytes 85% --vm-keep --timeout 5m
```

A Python test was also used to allocate memory in chunks.

The Linux kernel eventually terminated the process due to low memory.

The terminal displayed:

```text
Killed
```

CloudWatch captured memory utilization near 80% before Linux's OOM protection terminated the process.

This demonstrated the Linux Out-Of-Memory protection mechanism.

For safer testing, the alarm threshold was temporarily reduced.

The alarm successfully entered:

```text
In alarm
```

and SNS delivered an email notification.

---

# 25. Nginx Log Files

The Nginx logs were inspected:

```bash
sudo ls -l /var/log/nginx
```

Active logs:

```text
/var/log/nginx/access.log
/var/log/nginx/error.log
```

Older logs were automatically rotated and compressed into `.gz` files.

Access logs were inspected with:

```bash
sudo tail -n 20 /var/log/nginx/access.log
```

Error logs:

```bash
sudo tail -n 20 /var/log/nginx/error.log
```

---

# 26. Centralized CloudWatch Logs

The CloudWatch Agent sent Nginx logs to:

```text
/cloudops/nginx/access
/cloudops/nginx/error
```

The log stream was identified using the EC2 instance ID.

This centralized the web-server logs in CloudWatch.

---

# 27. Nginx Access Log Information

Nginx access logs included information such as:

```text
Client public IP
Timestamp
HTTP method
Requested path
HTTP protocol
Status code
User-Agent
```

Example:

```text
GET / HTTP/1.1
```

means the browser requested the website root.

A `304` status means:

```text
Not Modified
```

which usually means the browser can use its cached copy.

The browser also automatically requested:

```text
/favicon.ico
```

A favicon is the small icon displayed in browser tabs and bookmarks.

---

# 28. CloudWatch Logs Insights

CloudWatch Logs Insights was used to query Nginx logs.

## Latest Events

```sql
fields @timestamp, @message
| sort @timestamp desc
| limit 20
```

## Parse Nginx Logs

```sql
fields @timestamp, @message
| parse @message '* - - [*] "* * *" * * "*" "*"' 
    as client_ip, nginx_time, method, path, protocol, status, bytes, referrer, user_agent
| display @timestamp, client_ip, method, path, status, user_agent
| sort @timestamp desc
| limit 20
```

## Requests by HTTP Status Code

```sql
fields @message
| parse @message '* - - [*] "* * *" * * "*" "*"' 
    as client_ip, nginx_time, method, path, protocol, status, bytes, referrer, user_agent
| stats count() as requests by status
| sort requests desc
```

## Top Requested Paths

```sql
fields @message
| parse @message '* - - [*] "* * *" * * "*" "*"' 
    as client_ip, nginx_time, method, path, protocol, status, bytes, referrer, user_agent
| stats count() as requests by path
| sort requests desc
| limit 20
```

## HTTP Errors Only

```sql
fields @timestamp, @message
| parse @message '* - - [*] "* * *" * * "*" "*"' 
    as client_ip, nginx_time, method, path, protocol, status, bytes, referrer, user_agent
| filter status >= 400
| sort @timestamp desc
```

---

# 29. Logs Insights Cost Awareness

Logs Insights charges are based primarily on the amount of log data scanned.

A query estimate was tested using:

```sql
fields @timestamp, @message
| estimate
```

The lab only scanned a few kilobytes, so the cost was negligible.

Useful cost-control habits include:

- Narrow the query time range
- Query only the required log groups
- Avoid unnecessary repeated queries
- Use `estimate` when unsure

---

# 30. Systems Manager and IAM Hardening

The EC2 instance was initially administered through SSH.

The management approach was later hardened using AWS Systems Manager Session Manager.

The existing EC2 IAM role was updated to include:

```text
CloudWatchAgentServerPolicy
AmazonSSMManagedInstanceCore
```

One IAM role can have multiple policies that grant different capabilities.

---

# 31. Verify the SSM Agent

Amazon Linux 2023 includes the SSM Agent.

The agent status was checked with:

```bash
sudo systemctl status amazon-ssm-agent
```

Successful output showed:

```text
Active: active (running)
```

---

# 32. Connect Through Session Manager

The instance was accessed through:

```text
EC2
→ Instances
→ cloudops-web-01
→ Connect
→ Session Manager
```

Inside the session:

```bash
whoami
```

returned:

```text
ssm-user
```

The hostname was checked:

```bash
hostname
```

Session Manager worked without requiring:

```text
.pem private key
SSH username
Inbound TCP port 22
```

---

# 33. Remove Inbound SSH

After Session Manager was verified, the SSH inbound rule was removed from the security group.

The remaining public inbound rule was:

```text
HTTP
TCP 80
Source: 0.0.0.0/0
```

The old SSH command was tested again:

```bash
ssh -i ~/.ssh/cloudops-web-key-2.pem ec2-user@PUBLIC_IP
```

The connection timed out.

This confirmed that inbound SSH was blocked.

Session Manager continued to work.

---

# 34. Terraform IAM and SSM Implementation

The security improvement was also added to Terraform.

Terraform now creates:

- EC2 IAM role
- IAM instance profile
- `AmazonSSMManagedInstanceCore` attachment
- `CloudWatchAgentServerPolicy` attachment
- EC2 instance using the instance profile
- Security group without SSH ingress

Example:

```hcl
resource "aws_iam_role" "ec2_role" {
  name = "cloudops-ec2-role-tf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}
```

SSM policy:

```hcl
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

CloudWatch policy:

```hcl
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
```

Instance profile:

```hcl
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "cloudops-ec2-profile-tf"
  role = aws_iam_role.ec2_role.name
}
```

The EC2 resource references the profile:

```hcl
iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
```

---

# 35. SSH Key Pair Note

The Terraform EC2 resource still includes:

```hcl
key_name = "cloudops-web-key-2"
```

The key pair is no longer required for normal administration because Session Manager is used instead.

Removing the `key_name` value from the existing EC2 resource caused Terraform to report:

```text
aws_instance.web must be replaced
```

Because removing the key would force instance replacement, the key reference was temporarily retained.

Port 22 remains blocked, so the instance cannot be reached through SSH from the internet.

The next full instance rebuild can remove the key-pair dependency entirely.

---

# 36. Final Administrative Access Architecture

Initial architecture:

```text
Laptop
   |
Internet
   |
TCP 22
   |
Security Group
   |
EC2
```

Hardened architecture:

```text
AWS authenticated identity
   |
AWS Systems Manager
   |
IAM permissions
   |
SSM Agent
   |
EC2
```

This reduces direct network exposure and eliminates the need for internet-facing SSH administration.

---

# 37. Skills Demonstrated

This phase of the project demonstrates:

- EC2 provisioning
- Amazon Linux administration
- SSH authentication
- Linux package management
- Nginx installation
- systemd service management
- HTTP troubleshooting
- Security groups
- Public/private IP concepts
- Terraform
- EC2 user data
- Infrastructure destroy/rebuild testing
- CloudWatch metrics
- CloudWatch alarms
- SNS notifications
- CloudWatch Agent
- Custom memory and disk metrics
- IAM instance roles
- CloudWatch Logs
- Nginx log centralization
- Logs Insights
- Linux stress testing
- Linux OOM behavior
- AWS Systems Manager
- Session Manager
- Removal of inbound SSH
- Terraform IAM automation
- Cloud security hardening

---

# 38. Current Result

The project now has:

```text
Custom AWS VPC
   |
Public subnet
   |
EC2 / Amazon Linux / Nginx
   |
   +--> CloudWatch metrics
   +--> CloudWatch Agent
   +--> CloudWatch Logs
   +--> SNS alerts
   +--> IAM role
   +--> Systems Manager Session Manager
   |
No inbound SSH required
```

Infrastructure is also reproducible through Terraform.