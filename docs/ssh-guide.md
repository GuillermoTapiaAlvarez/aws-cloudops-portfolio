# SSH Guide: GitHub and AWS EC2

This guide documents the SSH setup used in the AWS CloudOps Portfolio project.

---

## 1. What SSH Is

SSH stands for **Secure Shell**. It provides an encrypted connection between a client and a remote system.

SSH commonly uses **public-key authentication**:

- **Private key**: stays on your computer and must be protected.
- **Public key**: can be shared with the remote service or server.
- The remote side verifies that you possess the matching private key without requiring you to send the private key over the network.

There are two different SSH relationships in this project:

1. Laptop → GitHub
2. Laptop → AWS EC2

They use separate keys and serve different purposes.

---

# Part 1: SSH to GitHub

## Purpose

SSH lets Git authenticate to GitHub without repeatedly entering a username and Personal Access Token.

## Step 1: Check for existing SSH keys

```bash
ls -al ~/.ssh
```

Common SSH key files:

```text
id_ed25519
id_ed25519.pub
```

The file ending in `.pub` is the public key.

Never share the private key.

## Step 2: Create a new SSH key

```bash
ssh-keygen -t ed25519 -C "your-github-email@example.com"
```

Explanation:

- `ssh-keygen` creates SSH key pairs.
- `-t ed25519` selects the ED25519 key algorithm.
- `-C` adds a comment, commonly an email address, to help identify the key.

When asked where to save the key, pressing Enter accepts the default:

```text
~/.ssh/id_ed25519
```

## Step 3: Start the SSH agent

```bash
eval "$(ssh-agent -s)"
```

The SSH agent holds private keys in memory so SSH clients can use them.

## Step 4: Add the key to the SSH agent

```bash
ssh-add ~/.ssh/id_ed25519
```

## Step 5: Display the public key

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire line, including the optional email/comment at the end.

## Step 6: Add the public key to GitHub

In GitHub:

Settings → SSH and GPG keys → New SSH key

Paste the public key and save it as an Authentication Key.

## Step 7: Test GitHub authentication

```bash
ssh -T git@github.com
```

The first connection may display a host fingerprint and ask whether you trust the server.

SSH is asking whether you trust that the remote server is really GitHub.

After accepting it, SSH records GitHub's host key in:

```text
~/.ssh/known_hosts
```

## Step 8: Configure a Git repository to use SSH

Example:

```bash
git remote set-url origin git@github.com:USERNAME/aws-cloudops-portfolio.git
```

Verify:

```bash
git remote -v
```

Push:

```bash
git push -u origin main
```

After the upstream branch is configured, later pushes usually require only:

```bash
git push
```

---

# Part 2: SSH to AWS EC2

## Purpose

SSH allows remote administration of a Linux EC2 instance.

In this project, AWS created an EC2 key pair. AWS stores the public key on the EC2 instance, while the downloaded `.pem` file contains the private key.

## Step 1: Create an EC2 key pair

Example settings:

```text
Name: cloudops-web-key-2
Type: ED25519
Format: .pem
```

`.pem` works with OpenSSH, including Git Bash.

The private key should be stored securely. AWS does not provide the same private key for download again.

Example location:

```text
C:\Users\memot\.ssh\cloudops-web-key-2.pem
```

Git Bash equivalent:

```text
/c/Users/memot/.ssh/cloudops-web-key-2.pem
```

or:

```text
~/.ssh/cloudops-web-key-2.pem
```

## Step 2: Restrict private-key permissions

On Linux, private SSH keys commonly use:

```bash
chmod 600 ~/.ssh/cloudops-web-key-2.pem
```

This represents:

```text
Owner: read + write
Group: no access
Others: no access
```

On Windows, NTFS ACLs determine the actual permissions.

Example check:

```bash
powershell.exe -Command "icacls 'C:\Users\memot\.ssh\cloudops-web-key-2.pem'"
```

## Step 3: Security group access

The EC2 security group should permit SSH only from a trusted source.

Example:

```text
SSH
TCP port 22
Source: home public IP /32
```

A `/32` IPv4 CIDR represents one IPv4 address.

Avoid allowing SSH from:

```text
0.0.0.0/0
```

unless there is a specific reason, because that exposes port 22 to the entire IPv4 internet.

## Step 4: Connect to EC2

Example:

```bash
ssh -i ~/.ssh/cloudops-web-key-2.pem ec2-user@PUBLIC_IP
```

Explanation:

- `ssh` starts the Secure Shell client.
- `-i` specifies the identity/private-key file.
- `~/.ssh/cloudops-web-key-2.pem` is the EC2 private key.
- `ec2-user` is the default Amazon Linux user.
- `PUBLIC_IP` is the EC2 instance's internet-facing IPv4 address.

## Step 5: Understand the first-connection fingerprint

On the first connection, SSH may display:

```text
The authenticity of host 'PUBLIC_IP' can't be established.
ED25519 key fingerprint is SHA256:...
Are you sure you want to continue connecting?
```

This fingerprint represents the **server's SSH host key**.

There are two identity checks:

```text
Your private EC2 key → proves your identity to the EC2 server
Server host key      → helps prove the server's identity to your SSH client
```

After accepting the server key, SSH records it in:

```text
~/.ssh/known_hosts
```

If the host key unexpectedly changes later, SSH may display a warning.

## Step 6: Public versus private EC2 IP addresses

The laptop connects using the EC2 instance's public IP:

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
EC2
```

Inside the VPC, the instance has a private IP such as:

```text
10.10.1.134
```

That address belongs to the project's subnet:

```text
public-subnet-a
10.10.1.0/24
```

Amazon Linux may use the private IP in its hostname:

```text
ec2-user@ip-10-10-1-134
```

This does not mean the public address changed. It is simply the Linux hostname showing the instance's private VPC identity.

## Step 7: Useful system-identification commands

```bash
uname -a
```

Displays information about the kernel and CPU architecture.

```bash
cat /etc/os-release
```

Displays Linux distribution and version information.

For this project, these commands confirmed:

```text
Amazon Linux 2023
x86_64
```

---

# GitHub SSH vs EC2 SSH

| Item | GitHub SSH | EC2 SSH |
|---|---|---|
| Purpose | Git authentication | Linux server administration |
| Remote identity | `git@github.com` | `ec2-user@PUBLIC_IP` |
| Private key | GitHub SSH key | EC2 `.pem` key |
| Public key stored by | GitHub | EC2 instance/AWS |
| Typical command | `ssh -T git@github.com` | `ssh -i key.pem ec2-user@IP` |
| Server fingerprint | GitHub host key | EC2 host key |
| Main use | clone/pull/push | remote Linux shell |

---

# Security Notes

- Never commit private SSH keys to Git.
- Never upload `.pem` private keys to GitHub.
- Keep private keys under restrictive operating-system permissions.
- Limit EC2 SSH security-group rules to trusted IP addresses.
- Treat an unexpected SSH host-key change as something to investigate rather than automatically accepting it.
