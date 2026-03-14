terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

resource "aws_cognito_user_pool" "this" {
  name = "${var.project_name}-user-pool"

  # Sign in with email
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  tags = { Project = var.project_name }
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  # USER_PASSWORD_AUTH is required for the test script
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

resource "aws_cognito_user" "candidate" {
  user_pool_id = aws_cognito_user_pool.this.id
  username     = var.email

  attributes = {
    email          = var.email
    email_verified = "true"
  }

  temporary_password   = var.temp_password
  message_action       = "SUPPRESS"
  force_alias_creation = false
}
