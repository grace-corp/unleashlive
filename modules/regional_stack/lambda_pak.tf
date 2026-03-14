# Archive zip files for Lambda deployment
data "archive_file" "greeter_zip" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/greeter.py"
  output_path = "${path.module}/greeter.zip"
}

data "archive_file" "dispatcher_zip" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/dispatcher.py"
  output_path = "${path.module}/dispatcher.zip"
}

# CloudWatch log groups (created before Lambda to avoid race condition)
resource "aws_cloudwatch_log_group" "greeter" {
  name              = "/aws/lambda/${local.project}-greeter-${var.region}"
  retention_in_days = 7
  tags              = { Project = local.project }
}

resource "aws_cloudwatch_log_group" "dispatcher" {
  name              = "/aws/lambda/${local.project}-dispatcher-${var.region}"
  retention_in_days = 7
  tags              = { Project = local.project }
}
