variable "aws_region" {
  description = "AWS-Region, in der alle Ressourcen erstellt werden"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Prefix für alle Ressourcennamen (ECR-Repo, Cluster, Service, ...)"
  type        = string
  default     = "nginx-hello-world"
}

variable "vpc_cidr" {
  description = "CIDR-Block der VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR-Blöcke der öffentlichen Subnetze (mindestens 2 für unterschiedliche Availability Zones). Wird ignoriert, wenn vpc_id gesetzt ist."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_id" {
  description = "ID einer bereits vorhandenen VPC, die genutzt werden soll. Bei null wird eine neue VPC erstellt."
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = "IDs der zu nutzenden öffentlichen Subnetze der bestehenden VPC (müssen eine Route zu einem Internet Gateway und 'Auto-assign public IP' haben). Erforderlich, wenn vpc_id gesetzt ist."
  type        = list(string)
  default     = []
}

variable "container_port" {
  description = "Port, auf dem der Container (nginx) lauscht"
  type        = number
  default     = 80
}

variable "image_tag" {
  description = "Tag des Docker-Images in ECR, das deployed werden soll"
  type        = string
  default     = "latest"
}

variable "task_cpu" {
  description = "CPU-Einheiten der Fargate-Task (256 = 0.25 vCPU, kleinste und günstigste Fargate-Größe)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Arbeitsspeicher (MB) der Fargate-Task (kleinste zulässige Größe für 256 CPU-Einheiten)"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Anzahl der gewünschten laufenden Tasks"
  type        = number
  default     = 1
}

variable "enable_load_balancer" {
  description = "Wenn true, wird ein Application Load Balancer mit fester DNS-URL vorgeschaltet (zusätzliche Kosten, ca. 20+ USD/Monat). Wenn false, wird direkt die wechselnde Public IP der Task verwendet."
  type        = bool
  default     = false
}
