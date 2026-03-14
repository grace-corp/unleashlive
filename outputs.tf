output "primary_api_url" {
  description = "us-east-1 API Gateway base URL"
  value       = module.primary.api_url
}

output "secondary_api_url" {
  description = "eu-west-1 API Gateway base URL"
  value       = module.secondary.api_url
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.client_id
}

output "cognito_password" {
  description = "Generated Cognito password - use this for test script"
  value       = random_password.cognito.result
  sensitive   = true
}
