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

  # Credenciais via variáveis de ambiente: AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY
  # Ou via arquivo ~/.aws/credentials
}

# -----------------------------------------------------------------------------
# DADOS - VPC e Subnet padrão
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# SECURITY GROUP para a EC2
# -----------------------------------------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-nginx-docker-${var.nome_aluno}"
  description = "Allows SSH and HTTP for EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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
    Name = "sg-ec2-${var.nome_aluno}"
  }
}

# -----------------------------------------------------------------------------
# USER DATA - Instalação do Docker e NGINX na EC2
# -----------------------------------------------------------------------------
locals {
  user_data = <<-EOF
#!/bin/bash
exec > /var/log/user-data.log 2>&1

# Instala Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Pasta com pagina customizada
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'PAGE'
<!DOCTYPE html>
<html>
<head><title>EC2 - Docker + NGINX</title></head>
<body>
  <h1>Servidor EC2 - Docker e NGINX instalados com sucesso!</h1>
  <p>Aluno: ${var.nome_aluno}</p>
</body>
</html>
PAGE

# NGINX via Docker (porta 80) - mais confiavel que instalacao nativa
docker run -d -p 80:80 -v /var/www/html:/usr/share/nginx/html:ro --name web --restart unless-stopped nginx:alpine

# NGINX nativo instalado (requisito da atividade)
yum install -y nginx
systemctl enable nginx
# NAO inicia nginx nativo - porta 80 ja usada pelo Docker

# Docker Compose
curl -sL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose || true
usermod -aG docker ec2-user 2>/dev/null || true
EOF
}

# -----------------------------------------------------------------------------
# INSTÂNCIA EC2 - t3.micro
# -----------------------------------------------------------------------------
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.first.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.key_name != "" ? var.key_name : null

  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "ec2-${var.nome_aluno}"
  }
}

# -----------------------------------------------------------------------------
# AMI Amazon Linux 2 mais recente
# -----------------------------------------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# -----------------------------------------------------------------------------
# BUCKET S3 - ifpb-bucket-<nome-do-aluno>
# Nome S3: apenas minúsculas, números e hífens
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "main" {
  bucket = "ifpb-bucket-${lower(replace(var.nome_aluno, " ", "-"))}"

  tags = {
    Name = "ifpb-bucket-${lower(replace(var.nome_aluno, " ", "-"))}"
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}
