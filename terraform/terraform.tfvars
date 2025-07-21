# Terraform variables file - customize these values for your deployment
# Copy this file to terraform.tfvars and update with your specific values

# AWS Configuration
aws_region = "us-west-2"
environment = "dev"
project_name = "serverless-todo-app"

# DynamoDB Configuration
dynamodb_table_name = "todos-table"

# Cognito Configuration
cognito_user_pool_name = "todo-app-user-pool"
cognito_user_pool_client_name = "todo-app-client"

# Lambda Configuration
lambda_function_name = "todo-handler"

# API Gateway Configuration
api_gateway_name = "todo-api"
api_gateway_stage = "prod"

# Amplify Configuration
amplify_app_name = "todo-app"
amplify_repository_url = "" # Add your Git repository URL here
amplify_branch_name = "main"
amplify_domain_name = "" # Add custom domain if you have one

# Common Tags
common_tags = {
  Project     = "ServerlessTodoApp"
  Environment = "dev"
  Owner       = "DevOps Team"
  Purpose     = "Capstone Project"
}

# AI Integration Configuration
gemini_api_key = "AIzaSyCvo8qwwdRHztBF_1yXZrShNS-0dTaACQs"
openai_api_key = ""
