# ── Lambda execution role ─────────────────────────────────────────────────────

resource "aws_iam_role" "lambda_role" {
  name = "${local.project}-lambda-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })

  tags = { Project = local.project }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-inline-${var.region}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DynamoDB"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.logs.arn
      },
      {
        Sid      = "SNSPublish"
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = var.sns_topic_arn
      },
      {
        Sid      = "ECSRunTask"
        Action   = ["ecs:RunTask", "ecs:DescribeTasks"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid    = "PassRole"
        Action = ["iam:PassRole"]
        Effect = "Allow"
        # PassRole scoped to both ECS roles
        Resource = [
          aws_iam_role.ecs_task_execution.arn,
          aws_iam_role.ecs_task_role.arn
        ]
      }
    ]
  })
}

# ── ECS task execution role (pull image, write logs) ──────────────────────────

resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.project}-ecs-exec-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Effect    = "Allow"
    }]
  })

  tags = { Project = local.project }
}

resource "aws_iam_role_policy_attachment" "ecs_exec_managed" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── ECS task role (what the container itself can do) ──────────────────────────

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.project}-ecs-task-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Effect    = "Allow"
    }]
  })

  tags = { Project = local.project }
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "ecs-task-inline-${var.region}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SNSPublish"
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = var.sns_topic_arn
      },
      {
        Sid    = "Logs"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
