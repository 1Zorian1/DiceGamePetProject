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
  region = "eu-central-1" # Зміни за потреби на свій регіон AWS
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

  owners = ["099720109477"] # Офіційний Owner ID Canonical (Ubuntu)
}

# 3. Створення SSH Key Pair у AWS
resource "aws_key_pair" "deployer" {
  key_name   = "dice-game-ec2-key"
  public_key = var.public_key_content
}

# 4. Security Group (Правила брандмауера: SSH + HTTP)
resource "aws_security_group" "dice_sg" {
  name        = "dice-game-sg"
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
    Name = "dice-game-security-group"
  }
}

# 5. Створення EC2-інстансу
resource "aws_instance" "dice_server" {
  ami           = data.aws_ami.ubuntu.id # Динамічний AMI замість статичного ID
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.dice_sg.id]

  # Автоматичне встановлення Docker, Docker Compose та Git під час запуску
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io docker-compose-plugin git
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "DiceGame-Production-Server"
  }
}

# 6. Output публічної IP-адреси
output "public_ip" {
  value       = aws_instance.dice_server.public_ip
  description = "Public IP address of the newly deployed EC2 instance"
}
