terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "first" {
  id = tolist(data.aws_subnets.default.ids)[0]
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-${var.nome_aluno}"
  description = "Libera SSH e HTTP"
  vpc_id      = data.aws_vpc.default.id

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

  tags = {
    Name = "sg-${var.nome_aluno}"
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.first.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
#!/bin/bash
yum install -y docker nginx
systemctl start docker
systemctl enable docker

mkdir -p /var/www
echo '<html><body><h1>EC2 - Docker e NGINX ok</h1><p>Aluno: ${var.nome_aluno}</p></body></html>' > /var/www/index.html
docker run -d -p 80:80 -v /var/www:/usr/share/nginx/html:ro --name web nginx:alpine

systemctl enable nginx
usermod -aG docker ec2-user
EOF

  tags = {
    Name = "ec2-${var.nome_aluno}"
  }
}

resource "aws_s3_bucket" "main" {
  bucket = "ifpb-bucket-${lower(replace(var.nome_aluno, " ", "-"))}"

  tags = {
    Name = "ifpb-bucket-${var.nome_aluno}"
  }
}
