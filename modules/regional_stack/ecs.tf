# CloudWatch log group for ECS task output
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.project}-dispatcher-${var.region}"
  retention_in_days = 7

  tags = { Project = local.project }
}

resource "aws_ecs_cluster" "this" {
  name = "${local.project}-cluster-${var.region}"

  setting {
    name  = "containerInsights"
    value = "disabled" # keep costs low for assessment
  }

  tags = { Project = local.project }
}

resource "aws_ecs_task_definition" "dispatcher" {
  family                   = "${local.project}-dispatcher-${var.region}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  # Separate execution role (pull image) and task role (what container can do)
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "publisher"
      image     = "amazon/aws-cli:latest"
      essential = true

      # aws-cli command: publish SNS message then exit
      command = [
        "sns", "publish",
        "--region", "us-east-1",
        "--topic-arn", var.sns_topic_arn,
        "--message", jsonencode({
          email  = var.email
          source = "ECS"
          region = var.region
          repo   = var.github_repo
        })
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = { Project = local.project }
}
