variable "region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "cognito_user_pool_arn" {
  type = string
}

variable "cognito_user_pool_id" {
  type = string
}

variable "cognito_client_id" {
  type = string
}

variable "email" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

locals {
  project = var.project_name
}
