# -----------------------------------------------------------------------------
# Variáveis - Substitua os valores em terraform.tfvars
# -----------------------------------------------------------------------------

variable "nome_aluno" {
  description = "Nome do aluno para identificar recursos (usado no S3: ifpb-bucket-<nome>)"
  type        = string
}

variable "aws_region" {
  description = "Região AWS para criar os recursos"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Nome do par de chaves SSH existente na AWS (opcional - deixe vazio se não tiver)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}
