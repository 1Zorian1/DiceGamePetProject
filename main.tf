provider "aws" {
  region = "eu-central-1"
}

resource "aws_security_group" "dice_sg" {
  name        = "dice_game_sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_instance" "dice_server" {
  ami           = "ami-008282f42a12260ff" # Ubuntu 22.04 LTS (eu-central-1)
  instance_type = "t2.micro"
  security_groups = [aws_security_group.dice_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io docker-compose git
              sudo systemctl start docker
              sudo systemctl enable docker
              EOF

  tags = {
    Name = "DiceGame-Server"
  }
}

output "public_ip" {
  value = aws_instance.dice_server.public_ip
}
