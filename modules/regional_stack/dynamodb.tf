resource "aws_dynamodb_table" "logs" {
  name         = "${local.project}-logs-${var.region}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name    = "${local.project}-logs-${var.region}"
    Project = local.project
  }
}
