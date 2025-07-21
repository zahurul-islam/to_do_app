# Enhanced API Gateway with AI extraction endpoint
resource "aws_api_gateway_resource" "ai_resource" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  parent_id   = aws_api_gateway_rest_api.todos_api.root_resource_id
  path_part   = "ai"
}

resource "aws_api_gateway_resource" "ai_extract_resource" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  parent_id   = aws_api_gateway_resource.ai_resource.id
  path_part   = "extract"
}

# AI Extraction Lambda
resource "aws_lambda_function" "ai_extractor" {
  filename         = data.archive_file.ai_extractor_zip.output_path
  function_name    = "${var.project_name}-ai-extractor"
  role            = aws_iam_role.ai_extractor_role.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 512
  source_code_hash = data.archive_file.ai_extractor_zip.output_base64sha256

  environment {
    variables = {
      GEMINI_API_KEY_SECRET_NAME = aws_secretsmanager_secret.gemini_api_key.name
      OPENAI_API_KEY_SECRET_NAME = aws_secretsmanager_secret.openai_api_key.name
      # Environment variables for direct API key access
      # Using OpenRouter API key in place of Gemini
      GEMINI_API_KEY = "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"
      OPENAI_API_KEY = var.openai_api_key != "" ? var.openai_api_key : ""
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.ai_extractor_policy,
    aws_cloudwatch_log_group.ai_extractor,
  ]

  tags = var.tags
}

# Package AI extractor Lambda
data "archive_file" "ai_extractor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/gemini_extractor"
  output_path = "${path.module}/lambda/ai_extractor.zip"
}

# IAM role for AI extractor Lambda
resource "aws_iam_role" "ai_extractor_role" {
  name = "${var.project_name}-ai-extractor-role"

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

  tags = var.tags
}

# IAM policy for AI extractor Lambda
resource "aws_iam_role_policy" "ai_extractor_policy" {
  name = "${var.project_name}-ai-extractor-policy"
  role = aws_iam_role.ai_extractor_role.id

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
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.gemini_api_key.arn,
          aws_secretsmanager_secret.openai_api_key.arn
        ]
      }
    ]
  })
}

# Attach basic execution role to AI extractor
resource "aws_iam_role_policy_attachment" "ai_extractor_policy" {
  role       = aws_iam_role.ai_extractor_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch log group for AI extractor
resource "aws_cloudwatch_log_group" "ai_extractor" {
  name              = "/aws/lambda/${var.project_name}-ai-extractor"
  retention_in_days = 14
  tags              = var.tags
}

# API Gateway method for AI extraction
resource "aws_api_gateway_method" "ai_extract_post" {
  rest_api_id   = aws_api_gateway_rest_api.todos_api.id
  resource_id   = aws_api_gateway_resource.ai_extract_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

# API Gateway method for AI extraction OPTIONS (CORS)
resource "aws_api_gateway_method" "ai_extract_options" {
  rest_api_id   = aws_api_gateway_rest_api.todos_api.id
  resource_id   = aws_api_gateway_resource.ai_extract_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# API Gateway integration for AI extraction
resource "aws_api_gateway_integration" "ai_extract_integration" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.ai_extract_resource.id
  http_method = aws_api_gateway_method.ai_extract_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.ai_extractor.invoke_arn
  timeout_milliseconds   = 29000
}

# API Gateway integration for AI extraction OPTIONS
resource "aws_api_gateway_integration" "ai_extract_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.ai_extract_resource.id
  http_method = aws_api_gateway_method.ai_extract_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# API Gateway method response for AI extraction
resource "aws_api_gateway_method_response" "ai_extract_response_200" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.ai_extract_resource.id
  http_method = aws_api_gateway_method.ai_extract_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# API Gateway method response for AI extraction OPTIONS
resource "aws_api_gateway_method_response" "ai_extract_options_response_200" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.ai_extract_resource.id
  http_method = aws_api_gateway_method.ai_extract_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# API Gateway integration response for AI extraction
resource "aws_api_gateway_integration_response" "ai_extract_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.ai_extract_resource.id
  http_method = aws_api_gateway_method.ai_extract_post.http_method
  status_code = aws_api_gateway_method_response.ai_extract_response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'"
  }

  depends_on = [
    aws_api_gateway_integration.ai_extract_integration,
    aws_api_gateway_method_response.ai_extract_response_200
  ]
}

# API Gateway integration response for AI extraction OPTIONS
resource "aws_api_gateway_integration_response" "ai_extract_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.todos_api.id
  resource_id = aws_api_gateway_resource.ai_extract_resource.id
  http_method = aws_api_gateway_method.ai_extract_options.http_method
  status_code = aws_api_gateway_method_response.ai_extract_options_response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'"
  }

  depends_on = [
    aws_api_gateway_integration.ai_extract_options_integration,
    aws_api_gateway_method_response.ai_extract_options_response_200
  ]
}

# Lambda permission for API Gateway to invoke AI extractor
resource "aws_lambda_permission" "ai_extractor_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_extractor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.todos_api.execution_arn}/*/*"
}

# Secrets for AI API keys
resource "aws_secretsmanager_secret" "gemini_api_key" {
  name                    = "${var.project_name}-gemini-api-key"
  description             = "Google Gemini API key for AI task extraction"
  recovery_window_in_days = 0  # Force immediate deletion
  
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "gemini_api_key" {
  secret_id     = aws_secretsmanager_secret.gemini_api_key.id
  secret_string = "YOUR_GEMINI_API_KEY_HERE" # This will be updated manually or via script
}

resource "aws_secretsmanager_secret" "openai_api_key" {
  name                    = "${var.project_name}-openai-api-key"
  description             = "OpenAI API key for AI task extraction fallback"
  recovery_window_in_days = 0  # Force immediate deletion
  
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = "YOUR_OPENAI_API_KEY_HERE" # This will be updated manually or via script
}

# Output the AI endpoint
output "ai_extraction_endpoint" {
  description = "AI extraction endpoint URL"
  value       = "${aws_api_gateway_stage.todos_stage.invoke_url}/ai/extract"
}
