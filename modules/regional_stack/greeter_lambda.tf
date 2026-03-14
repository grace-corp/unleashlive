resource "aws_lambda_function" "greeter" {
  function_name    = "${local.project}-greeter-${var.region}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "greeter.handler"
  runtime          = "python3.11"
  filename         = data.archive_file.greeter_zip.output_path
  source_code_hash = data.archive_file.greeter_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME    = aws_dynamodb_table.logs.name
      REGION        = var.region
      EMAIL         = var.email
      REPO          = var.github_repo
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.greeter]
  tags       = { Project = local.project }
}
