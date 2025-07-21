# Terraform configuration for Serverless Todo App
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# DynamoDB Table for storing todos
resource "aws_dynamodb_table" "todos" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "TodosTable"
    Environment = var.environment
  }
}

# Cognito User Pool is defined in cognito-enhanced.tf (using flowless configuration)

# Cognito User Pool Client is defined in cognito-enhanced.tf (using flowless configuration)

# AI Integration is defined in ai-integration.tf

# IAM Role for Lambda
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_iam_role" "lambda_role" {
  name = "todo-lambda-role-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "TodoLambdaRole"
    Environment = var.environment
  }
}

# IAM Policy for Lambda to access DynamoDB and CloudWatch Logs
resource "aws_iam_policy" "lambda_policy" {
  name        = "todo-lambda-policy-${random_string.suffix.result}"
  description = "Policy for Lambda to access DynamoDB and CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.todos.arn
      }
    ]
  })
}

# Attach policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function for handling todo CRUD operations
resource "aws_lambda_function" "todos_handler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-todos-handler"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.todos.name
    }
  }

  tags = {
    Name        = "TodosLambda"
    Environment = var.environment
  }
}

# Create Lambda function package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source_file = "${path.module}/lambda/index.py"
}

# CloudWatch Log Group for Lambda is defined in monitoring.tf

# API Gateway REST API
resource "aws_api_gateway_rest_api" "todos_api" {
  name        = "${var.project_name}-api"
  description = "API for Todo application"

  tags = {
    Name        = "TodoAPI"
    Environment = var.environment
  }
}

# API Gateway Authorizer (Cognito User Pool) is defined in cognito-enhanced.tf

# API Gateway Resource - /todos
resource "aws_api_gateway_resource" "todos_resource" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  parent_id   = aws_api_gateway_rest_api.todos_api.root_resource_id
  path_part   = "todos"
}

# API Gateway Resource - /todos/{id}
resource "aws_api_gateway_resource" "todo_item_resource" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  parent_id   = aws_api_gateway_resource.todos_resource.id
  path_part   = "{id}"
}

# API Gateway Method - GET /todos
resource "aws_api_gateway_method" "get_todos" {
  rest_api_id   = aws_api_gateway_rest_api.todos_api.id
  resource_id   = aws_api_gateway_resource.todos_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# API Gateway Method - POST /todos
resource "aws_api_gateway_method" "post_todos" {
  rest_api_id   = aws_api_gateway_rest_api.todos_api.id
  resource_id   = aws_api_gateway_resource.todos_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# API Gateway Method - PUT /todos/{id}
resource "aws_api_gateway_method" "put_todo" {
  rest_api_id   = aws_api_gateway_rest_api.todos_api.id
  resource_id   = aws_api_gateway_resource.todo_item_resource.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# API Gateway Method - DELETE /todos/{id}
resource "aws_api_gateway_method" "delete_todo" {
  rest_api_id   = aws_api_gateway_rest_api.todos_api.id
  resource_id   = aws_api_gateway_resource.todo_item_resource.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# API Gateway Integration - GET /todos
resource "aws_api_gateway_integration" "get_todos_integration" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.todos_resource.id
  http_method = aws_api_gateway_method.get_todos.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.todos_handler.invoke_arn
}

# API Gateway Integration - POST /todos
resource "aws_api_gateway_integration" "post_todos_integration" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.todos_resource.id
  http_method = aws_api_gateway_method.post_todos.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.todos_handler.invoke_arn
}

# API Gateway Integration - PUT /todos/{id}
resource "aws_api_gateway_integration" "put_todo_integration" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.todo_item_resource.id
  http_method = aws_api_gateway_method.put_todo.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.todos_handler.invoke_arn
}

# API Gateway Integration - DELETE /todos/{id}
resource "aws_api_gateway_integration" "delete_todo_integration" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.todo_item_resource.id
  http_method = aws_api_gateway_method.delete_todo.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.todos_handler.invoke_arn
}

# CORS Configuration for /todos
resource "aws_api_gateway_method" "options_todos" {
  rest_api_id   = aws_api_gateway_rest_api.todos_api.id
  resource_id   = aws_api_gateway_resource.todos_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_todos_integration" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.todos_resource.id
  http_method = aws_api_gateway_method.options_todos.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "options_todos_response" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.todos_resource.id
  http_method = aws_api_gateway_method.options_todos.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_todos_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.todos_resource.id
  http_method = aws_api_gateway_method.options_todos.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options_todos_integration]
}

# CORS Configuration for /todos/{id}
resource "aws_api_gateway_method" "options_todo_item" {
  rest_api_id   = aws_api_gateway_rest_api.todos_api.id
  resource_id   = aws_api_gateway_resource.todo_item_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_todo_item_integration" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.todo_item_resource.id
  http_method = aws_api_gateway_method.options_todo_item.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "options_todo_item_response" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.todo_item_resource.id
  http_method = aws_api_gateway_method.options_todo_item.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_todo_item_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.todo_item_resource.id
  http_method = aws_api_gateway_method.options_todo_item.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options_todo_item_integration]
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.todos_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todos_api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "todos_deployment" {
  depends_on = [
    aws_api_gateway_integration.get_todos_integration,
    aws_api_gateway_integration.post_todos_integration,
    aws_api_gateway_integration.put_todo_integration,
    aws_api_gateway_integration.delete_todo_integration,
    aws_api_gateway_integration.options_todos_integration,
    aws_api_gateway_integration.options_todo_item_integration,
    aws_api_gateway_integration.ai_extract_integration,
    aws_api_gateway_integration.ai_extract_options_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.todos_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.todos_resource.id,
      aws_api_gateway_resource.todo_item_resource.id,
      aws_api_gateway_resource.ai_extract_resource.id,
      aws_api_gateway_method.get_todos.id,
      aws_api_gateway_method.post_todos.id,
      aws_api_gateway_method.put_todo.id,
      aws_api_gateway_method.delete_todo.id,
      aws_api_gateway_method.ai_extract_post.id,
      aws_api_gateway_method.ai_extract_options.id,
      aws_api_gateway_integration.get_todos_integration.id,
      aws_api_gateway_integration.post_todos_integration.id,
      aws_api_gateway_integration.put_todo_integration.id,
      aws_api_gateway_integration.delete_todo_integration.id,
      aws_api_gateway_integration.ai_extract_integration.id,
      aws_api_gateway_integration.ai_extract_options_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "todos_stage" {
  deployment_id = aws_api_gateway_deployment.todos_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.todos_api.id
  stage_name    = var.api_gateway_stage
}
