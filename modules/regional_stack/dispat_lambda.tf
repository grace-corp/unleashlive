resource "aws_lambda_function" "dispatcher" {
  function_name    = "${local.project}-dispatcher-${var.region}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "dispatcher.handler"
  runtime          = "python3.11"
  filename         = data.archive_file.dispatcher_zip.output_path
  source_code_hash = data.archive_file.dispatcher_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      CLUSTER_ARN  = aws_ecs_cluster.this.arn
      TASK_DEF_ARN = aws_ecs_task_definition.dispatcher.arn
      SUBNET_ID    = aws_subnet.public.id
      SG_ID        = aws_security_group.ecs_tasks.id
      REGION       = var.region
    }
  }

  depends_on = [aws_cloudwatch_log_group.dispatcher]
  tags       = { Project = local.project }
}
