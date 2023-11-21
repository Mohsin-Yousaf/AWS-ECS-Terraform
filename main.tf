############

# AWS ECR

resource "aws_ecr_repository" "ecr_repo" {
  name                 = "${var.aws_resource_prefix}-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}


# ECS Task Definition

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "${var.aws_resource_prefix}-ecs_task_definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::${var.aws_account_id}:role/ecsTaskExecutionRole"
  cpu                      = 256
  memory                   = 512

  container_definitions = <<JSON
[
  {
    "name": "${var.aws_resource_prefix}-container",
    "image": "nginx",
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${var.container_port},
        "hostPort": ${var.container_port}
      }
    ]
  }
]
JSON

}


# ECS Cluster

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.aws_resource_prefix}-ecs_cluster"
}


# ECS Service

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.aws_resource_prefix}-ecs_service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = "${var.desired_task}"
  scheduling_strategy = "REPLICA"
  launch_type         = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = "${var.aws_resource_prefix}-container"
    container_port   = "${var.container_port}"
  }

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_security_group.id]
  }

  depends_on = [module.vpc, aws_ecs_service.ecs_service]

}

# ECS Autoscaling

resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity       = "${var.minimum_task}"
  max_capacity       = "${var.maximum_task}"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.ecs_service]
}

# ECS Autoscaling Policy

resource "aws_appautoscaling_policy" "ecs_scaling_policy" {
  name                   = "${var.aws_resource_prefix}-ecs-scaling-policy"
  policy_type            = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70
    scale_in_cooldown  = 120
    scale_out_cooldown = 120
  }
  depends_on = [aws_appautoscaling_target.ecs_target]
}
