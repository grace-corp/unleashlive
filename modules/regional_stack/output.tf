output "api_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.logs.name
}
