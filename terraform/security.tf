resource "aws_security_group" "service" {
  name        = "${var.project_name}-service-sg"
  description = "Container Security Group - Ingress-Regeln je nach enable_load_balancer separat definiert"
  vpc_id      = local.vpc_id

  egress {
    description = "Ausgehend alles erlauben (z. B. Image-Pull von ECR, Logs an CloudWatch)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-service-sg"
  }

  lifecycle {
    precondition {
      condition     = var.vpc_id == null || length(var.public_subnet_ids) > 0
      error_message = "public_subnet_ids muss gesetzt werden, wenn vpc_id angegeben ist."
    }
  }
}

# Ohne Load Balancer: Container direkt aus dem Internet erreichbar
resource "aws_security_group_rule" "service_ingress_public" {
  count             = var.enable_load_balancer ? 0 : 1
  type              = "ingress"
  description       = "HTTP direkt von ueberall - kein Load Balanceryes"
  from_port         = var.container_port
  to_port           = var.container_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.service.id
}

# Mit Load Balancer: Container nur noch vom ALB erreichbar, nicht mehr direkt aus dem Internet
resource "aws_security_group_rule" "service_ingress_from_alb" {
  count                    = var.enable_load_balancer ? 1 : 0
  type                     = "ingress"
  description              = "HTTP nur vom Application Load Balancer"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb[0].id
  security_group_id        = aws_security_group.service.id
}
