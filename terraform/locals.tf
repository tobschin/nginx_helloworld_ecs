locals {
  create_vpc        = var.vpc_id == null
  vpc_id            = local.create_vpc ? aws_vpc.this[0].id : var.vpc_id
  public_subnet_ids = local.create_vpc ? aws_subnet.public[*].id : var.public_subnet_ids
}
