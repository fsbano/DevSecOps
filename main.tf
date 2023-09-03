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

resource "aws_security_group_rule" "public_in_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-094c45235b94d848e"
}

resource "aws_security_group_rule" "public_in_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "sg-094c45235b94d848e"
}

resource "aws_instance" "fsbano" {
  ami           = "ami-051f7e7f6c2f40dc1"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.fsbano.key_name

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${file("~/.ssh/id_rsa")}"
    host     = self.public_ip
  }

  provisioner "remote-exec" {
   inline = [
    "date"
   ]
  }

  provisioner "local-exec" {
    command = "echo ${self.public_dns}"
  }

  tags = {
    Name = "fsbano"
  }
}
