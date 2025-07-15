# Output values for the Terraform configuration

output "aws_region" {
  description = "AWS region used for deployment"
  value       = var.aws_region
}

output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.todos.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.todos.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.todos_handler.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.todos_handler.arn
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.todos_api.id
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = aws_api_gateway_stage.todos_stage.invoke_url
}

output "api_gateway_stage" {
  description = "Stage name of the API Gateway deployment"
  value       = aws_api_gateway_stage.todos_stage.stage_name
}

# Amplify outputs commented out until repository URL is provided
# output "amplify_app_id" {
#   description = "ID of the Amplify app"
#   value       = aws_amplify_app.todo_app.id
# }

# output "amplify_app_name" {
#   description = "Name of the Amplify app"
#   value       = aws_amplify_app.todo_app.name
# }

# output "amplify_app_url" {
#   description = "URL of the Amplify app"
#   value       = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.todo_app.id}.amplifyapp.com"
# }

# output "amplify_branch_name" {
#   description = "Name of the Amplify branch"
#   value       = aws_amplify_branch.main.branch_name
# }

# Configuration for frontend application
output "frontend_config" {
  description = "Configuration object for the frontend application"
  value = {
    region           = var.aws_region
    userPoolId       = aws_cognito_user_pool.main.id
    userPoolClientId = aws_cognito_user_pool_client.main.id
    apiGatewayUrl    = aws_api_gateway_stage.todos_stage.invoke_url
  }
}

# Frontend hosting outputs
output "frontend_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend"
  value       = aws_s3_bucket.frontend_bucket.bucket
}

output "frontend_bucket_website_url" {
  description = "S3 bucket website URL"
  value       = aws_s3_bucket_website_configuration.frontend_bucket_website.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend_distribution.id
}

output "cloudfront_distribution_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
}

# Website URL (primary access point)
output "website_url" {
  description = "Primary website URL (CloudFront distribution)"
  value       = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
}

# Summary of all important URLs and IDs
output "deployment_summary" {
  description = "Summary of all deployed resources"
  value = {
    frontend_url        = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
    api_gateway_url     = aws_api_gateway_stage.todos_stage.invoke_url
    user_pool_id        = aws_cognito_user_pool.main.id
    user_pool_client_id = aws_cognito_user_pool_client.main.id
    region              = var.aws_region
    cloudfront_id       = aws_cloudfront_distribution.frontend_distribution.id
    s3_bucket          = aws_s3_bucket.frontend_bucket.bucket
  }
}