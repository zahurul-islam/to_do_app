# Variables for Terraform configuration

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "serverless-todo-app"
}

# DynamoDB Variables
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for todos"
  type        = string
  default     = "todos-table"
}

# Cognito Variables
variable "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "todo-app-user-pool"
}

variable "cognito_user_pool_client_name" {
  description = "Name of the Cognito User Pool Client"
  type        = string
  default     = "todo-app-client"
}

# Lambda Variables
variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "todo-handler"
}

# API Gateway Variables
variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "todo-api"
}

variable "api_gateway_stage" {
  description = "Stage name for API Gateway deployment"
  type        = string
  default     = "prod"
}

# Amplify Variables
variable "amplify_app_name" {
  description = "Name of the Amplify app"
  type        = string
  default     = "todo-app"
}

variable "amplify_repository_url" {
  description = "Git repository URL for Amplify app"
  type        = string
  default     = ""
}

variable "amplify_branch_name" {
  description = "Branch name for Amplify deployment"
  type        = string
  default     = "main"
}

variable "amplify_domain_name" {
  description = "Custom domain name for Amplify app (optional)"
  type        = string
  default     = ""
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "ServerlessTodoApp"
    Environment = "dev"
    Owner       = "DevOps Team"
  }
}# Add to variables.tf for flowless authentication support

variable "enable_post_confirmation_trigger" {
  description = "Enable post-confirmation Lambda trigger for user initialization"
  type        = bool
  default     = false
}

# AI API Keys variables
variable "gemini_api_key" {
  description = "Google Gemini API key for AI task extraction"
  type        = string
  default     = ""
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API key for AI task extraction (fallback)"
  type        = string
  default     = ""
  sensitive   = true
}

# Tags variable for consistent resource tagging
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default = {
    Project     = "TaskFlow-AI"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
