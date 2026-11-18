# Optionaler Application Load Balancer fuer eine feste, dauerhafte URL (statt wechselnder Task-Public-IP)
resource "aws_security_group" "alb" {
  count       = var.enable_load_balancer ? 1 : 0
  name        = "${var.project_name}-alb-sg"
  description = "Erlaubt eingehenden HTTP-Traffic aus dem Internet auf den Load Balancer"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP von ueberall"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Ausgehend alles erlauben"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_lb" "this" {
  count              = var.enable_load_balancer ? 1 : 0
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = local.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }

  lifecycle {
    precondition {
      condition     = length(local.public_subnet_ids) >= 2
      error_message = "Für einen Application Load Balancer werden mindestens 2 Subnetze in unterschiedlichen Availability Zones benötigt (public_subnet_cidrs bzw. public_subnet_ids)."
    }
  }
}

resource "aws_lb_target_group" "this" {
  count       = var.enable_load_balancer ? 1 : 0
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

resource "aws_lb_listener" "http" {
  count             = var.enable_load_balancer ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }
}
