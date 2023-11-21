############
# Application Load Balancer 

resource "aws_lb" "alb" {
  name               = "${var.aws_resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = module.vpc.public_subnets
  depends_on = [module.vpc]

}

# Loadbalancer Target-group

resource "aws_lb_target_group" "alb_target_group" {
  name        = "${var.aws_resource_prefix}-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path = "${var.health_check_path}"

  }
  depends_on = [module.vpc]
}


# Loadbalancer Listener

resource "aws_lb_listener" "alb_target" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
  depends_on = [aws_lb.alb, aws_lb_target_group.alb_target_group]
}
