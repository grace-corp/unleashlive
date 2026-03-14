variable "primary_region" {
  type    = string
  default = "us-east-1"
}

variable "secondary_region" {
  type    = string
  default = "eu-west-1"
}

variable "email" {
  type        = string
  description = "Candidate email address"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository URL"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "sns_topic_arn" {
  type    = string
  default = "arn:aws:sns:us-east-1:637226132752:Candidate-Verification-Topic"
}

variable "project_name" {
  type    = string
  default = "unleashlive-assessment"
}
