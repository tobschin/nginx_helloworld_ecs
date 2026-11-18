output "ecr_repository_url" {
  description = "URL des ECR-Repositories, in das das Docker-Image gepusht werden muss"
  value       = aws_ecr_repository.this.repository_url
}

output "ecs_cluster_name" {
  description = "Name des ECS-Clusters"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Name des ECS-Service"
  value       = aws_ecs_service.this.name
}

output "aws_region" {
  description = "Verwendete AWS-Region"
  value       = var.aws_region
}

output "alb_dns_name" {
  description = "Feste DNS-URL des Application Load Balancers - nur gesetzt, wenn enable_load_balancer=true"
  value       = var.enable_load_balancer ? aws_lb.this[0].dns_name : null
}
