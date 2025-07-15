# Enhanced Authentication Configuration for Cognito User Pool

# Enhanced Cognito User Pool with additional security features
resource "aws_cognito_user_pool" "main" {
  name = var.cognito_user_pool_name

  # Username configuration - use email as username
  username_attributes = ["email"]

  # Enhanced password policy
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  # Account recovery configuration
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Email verification configuration
  verification_message_template {
    default_email_option  = "CONFIRM_WITH_CODE"
    email_subject         = "Todo App - Verify your email"
    email_message         = "Your verification code for Todo App is {####}"
    email_subject_by_link = "Todo App - Verify your email"
    email_message_by_link = "Please click the link below to verify your email address for Todo App: {##Verify Email##}"
  }

  # Auto-verified attributes
  auto_verified_attributes = ["email"]

  # User pool add-ons
  user_pool_add_ons {
    advanced_security_mode = "AUDIT"  # Use ENFORCED for production
  }

  # Admin create user configuration
  admin_create_user_config {
    allow_admin_create_user_only = false
    invite_message_template {
      email_subject = "Welcome to Todo App"
      email_message = "Your username is {username} and temporary password is {####}"
      sms_message   = "Your username is {username} and temporary password is {####}"
    }
  }

  # Device configuration
  device_configuration {
    challenge_required_on_new_device      = false
    device_only_remembered_on_user_prompt = false
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # User attribute schema
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  # Optional: Add custom attributes for todo app
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "name"
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  tags = {
    Name        = "TodoAppUserPool"
    Environment = var.environment
    Purpose     = "Authentication"
  }
}

# Enhanced Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = var.cognito_user_pool_client_name
  user_pool_id = aws_cognito_user_pool.main.id

  # Client configuration
  generate_secret                      = false
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
  enable_propagate_additional_user_context_data = false

  # Authentication flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",  # Secure Remote Password protocol
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"  # For admin auth flow
  ]

  # Token validity configuration
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = 1   # 1 hour
  id_token_validity      = 1   # 1 hour
  refresh_token_validity = 30  # 30 days

  # Read and write attributes
  read_attributes = [
    "email",
    "email_verified",
    "name"
  ]

  write_attributes = [
    "email",
    "name"
  ]

  # Callback URLs for OAuth (if needed in future)
  supported_identity_providers = ["COGNITO"]

  # Security configuration
  auth_session_validity = 3  # 3 minutes for auth session
}

# Cognito User Pool Domain (optional for hosted UI)
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-auth-${random_id.domain_suffix.hex}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Random ID for unique domain suffix
resource "random_id" "domain_suffix" {
  byte_length = 4
}

# Enhanced API Gateway Authorizer with additional configuration
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                             = "cognito-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.todos_api.id
  type                             = "COGNITO_USER_POOLS"
  provider_arns                    = [aws_cognito_user_pool.main.arn]
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300  # Cache for 5 minutes
}

# Additional IAM role for Cognito authenticated users
resource "aws_iam_role" "cognito_authenticated_role" {
  name = "cognito-authenticated-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "CognitoAuthenticatedRole"
    Environment = var.environment
  }
}

# Cognito Identity Pool for additional AWS service access
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.project_name}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = true
  }

  tags = {
    Name        = "TodoAppIdentityPool"
    Environment = var.environment
  }
}

# Attach policies to the authenticated role
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated" = aws_iam_role.cognito_authenticated_role.arn
  }
}
