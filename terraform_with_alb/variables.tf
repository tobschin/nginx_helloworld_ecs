variable "aws_region" {
  description = "Die AWS Region, in der deployed werden soll"
  type        = string
  default     = "eu-central-1" # Frankfurt
}

variable "ecr_image_uri" {
  description = "Die vollständige URI des ECR Images (z.B. <account>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>)"
  type        = string
}

variable "app_name" {
  description = "Name der Anwendung (Prefix für Cluster, Task, Service, Container, ...)"
  type        = string
  default     = "nginx-hello-world"
}
