# Security Group for ALB

resource "aws_security_group" "alb_security_group" {
  name   = "${var.aws_resource_prefix}-alb_security_group"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    description = "any"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   depends_on = [module.vpc]
}

# Define a security group for the ECS service

resource "aws_security_group" "ecs_security_group" {
  name        = "${var.aws_resource_prefix}-ecs_security_group"
  description = "Security group for ECS service"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_security_group.id]
    description     = "Allow traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   depends_on = [module.vpc]
}
