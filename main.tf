terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.15.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "fsbano" {
  key_name   = "fsbano"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "sg-fsbano" {
  name        = "fsbano-sg"
  description = "Allow HTTP and SSH traffic via Terraform"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "fsbano" {
  ami                    = "ami-051f7e7f6c2f40dc1"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.fsbano.key_name
  vpc_security_group_ids = [aws_security_group.sg-fsbano.id]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cat /etc/os-release",
      "cat /etc/image-id",
      "/usr/bin/sudo yum update",
      "/usr/bin/sudo yum install -y nginx",
      "/usr/bin/sudo systemctl enable --now nginx"
    ]
  }

  provisioner "local-exec" {
    command = "curl http://${self.public_dns}"
  }

  tags = {
    Name = "fsbano"
  }
}
