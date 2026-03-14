# Generate a secure random password for Cognito user
resource "random_password" "cognito" {
  length           = 12
  upper            = true
  lower            = true
  numeric          = true
  special          = true
  override_special = "!@#$"  # Cognito-safe special chars
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

module "cognito" {
  source = "./modules/cognito"

  providers = {
    aws = aws.us
  }

  project_name  = local.project_name
  email         = var.email
  temp_password = random_password.cognito.result
}

module "primary" {
  source = "./modules/regional_stack"

  providers = {
    aws = aws.us
  }

  region                = var.primary_region
  project_name          = local.project_name
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_client_id     = module.cognito.client_id
  email                 = var.email
  github_repo           = var.github_repo
  sns_topic_arn         = var.sns_topic_arn
  vpc_cidr              = var.vpc_cidr
  subnet_cidr           = var.public_subnet_cidr
}

module "secondary" {
  source = "./modules/regional_stack"

  providers = {
    aws = aws.eu
  }

  region                = var.secondary_region
  project_name          = local.project_name
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_client_id     = module.cognito.client_id
  email                 = var.email
  github_repo           = var.github_repo
  sns_topic_arn         = var.sns_topic_arn
  vpc_cidr              = var.vpc_cidr
  subnet_cidr           = var.public_subnet_cidr
}
