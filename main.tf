terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1" # За потреби змініть на ваш регіон AWS
}

# 1. Оголошення змінної для публічного SSH-ключа
variable "public_key_content" {
  type        = string
  description = "Public SSH key content for EC2 instance"
}

# 2. Динамічний пошук найновішого AMI Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical (Ubuntu)
}

# 3. Створення SSH Key Pair у AWS (версія v6)
resource "aws_key_pair" "deployer" {
  key_name   = "dice-game-ec2-key-v6"
  public_key = var.public_key_content
}

# 4. Security Group (версія v6)
resource "aws_security_group" "dice_sg" {
  name        = "dice-game-sg-v6"
  description = "Allow SSH (22) and HTTP (80) traffic"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Web Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dice-game-security-group-v6"
  }
}

# 5. Створення EC2-інстансу (t3.micro, версія v6)
resource "aws_instance" "dice_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.dice_sg.id]

  # Надійне встановлення Docker через офіційний APT-репозиторій
  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -x

              apt-get update -y
              apt-get install -y ca-certificates curl gnupg lsb-release git

              # Налаштування офіційного ключа та репозиторію Docker
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "DiceGame-Production-Server-v6"
  }
}

# 6. Output публічної IP-адреси
output "public_ip" {
  value       = aws_instance.dice_server.public_ip
  description = "Public IP address of the newly deployed EC2 instance"
}
