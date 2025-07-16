# Enhanced Cognito Configuration for Flowless Authentication

# Enhanced Cognito User Pool with streamlined signup flow
resource "aws_cognito_user_pool" "main" {
  name = var.cognito_user_pool_name

  # Username configuration - allow email sign-in but keep usernames flexible
  username_attributes = ["email"]
  
  # Set username configuration for case insensitive usernames
  username_configuration {
    case_sensitive = false
  }

  # Streamlined password policy - reasonable but not overly complex
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = false  # Simplified for better UX
    require_numbers                  = true
    require_symbols                  = false  # Simplified for better UX
    temporary_password_validity_days = 7
  }

  # Account recovery configuration
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Enhanced email verification configuration for flowless experience
  verification_message_template {
    default_email_option  = "CONFIRM_WITH_CODE"
    email_subject         = "TaskFlow - Your verification code"
    email_message         = "Welcome to TaskFlow! Your verification code is: {####}\n\nThis code will expire in 24 hours."
  }

  # Auto-verified attributes for seamless experience
  auto_verified_attributes = ["email"]

  # User pool add-ons for security
  user_pool_add_ons {
    advanced_security_mode = "AUDIT"  # Use ENFORCED for production
  }

  # Admin create user configuration - allow self-registration
  admin_create_user_config {
    allow_admin_create_user_only = false
    
    # Invitation message template
    invite_message_template {
      email_subject = "Welcome to TaskFlow"
      email_message = "Welcome to TaskFlow! Your username is {username} and temporary password is {####}"
      sms_message   = "Welcome to TaskFlow! Username: {username} Password: {####}"
    }
  }

  # Device configuration - simplified for better UX
  device_configuration {
    challenge_required_on_new_device      = false
    device_only_remembered_on_user_prompt = false
  }

  # Email configuration - use default Cognito email for simplicity
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

  # Optional name attribute
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

  # Custom attribute for user preferences (optional)
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "custom:preferences"
    required                 = false

    string_attribute_constraints {
      min_length = 0
      max_length = 1000
    }
  }

  tags = {
    Name        = "TaskFlow-UserPool"
    Environment = var.environment
    Purpose     = "FlowlessAuthentication"
  }
}

# Enhanced Cognito User Pool Client for flowless experience
resource "aws_cognito_user_pool_client" "main" {
  name         = var.cognito_user_pool_client_name
  user_pool_id = aws_cognito_user_pool.main.id

  # Client configuration optimized for web app
  generate_secret                      = false
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
  enable_propagate_additional_user_context_data = false

  # Authentication flows - enable all necessary flows for flexibility
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",        # Direct username/password auth
    "ALLOW_REFRESH_TOKEN_AUTH",        # Token refresh
    "ALLOW_USER_SRP_AUTH",             # Secure Remote Password
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"   # Admin auth flow
  ]

  # Token validity configuration - balanced security and UX
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = 2   # 2 hours - reasonable for todo app
  id_token_validity      = 2   # 2 hours - matches access token
  refresh_token_validity = 30  # 30 days - good balance

  # Read and write attributes
  read_attributes = [
    "email",
    "name"
  ]

  write_attributes = [
    "email",
    "name"
  ]

  # OAuth configuration for future extensibility
  supported_identity_providers = ["COGNITO"]
  
  # Callback URLs for OAuth (can be used for future features)
  callback_urls = [
    "http://localhost:3000",
    "https://localhost:3000"
  ]
  
  logout_urls = [
    "http://localhost:3000",
    "https://localhost:3000"
  ]

  # Security configuration
  auth_session_validity = 5  # 5 minutes for auth session
}

# Cognito User Pool Domain for hosted UI (optional future use)
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-taskflow-${random_id.domain_suffix.hex}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Random ID for unique domain suffix
resource "random_id" "domain_suffix" {
  byte_length = 4
}

# Enhanced API Gateway Authorizer
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                             = "taskflow-cognito-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.todos_api.id
  type                             = "COGNITO_USER_POOLS"
  provider_arns                    = [aws_cognito_user_pool.main.arn]
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300  # Cache for 5 minutes
}

# Cognito Identity Pool for additional AWS access
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.project_name}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = true
  }

  tags = {
    Name        = "TaskFlow-IdentityPool"
    Environment = var.environment
  }
}

# IAM role for authenticated users
resource "aws_iam_role" "cognito_authenticated_role" {
  name = "taskflow-cognito-authenticated-role-${var.environment}"

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
    Name        = "TaskFlow-AuthenticatedRole"
    Environment = var.environment
  }
}

# Enhanced policy for authenticated users
resource "aws_iam_policy" "cognito_authenticated_policy" {
  name        = "taskflow-cognito-authenticated-policy"
  description = "Policy for authenticated TaskFlow users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-sync:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "${aws_api_gateway_rest_api.todos_api.execution_arn}/*"
      }
    ]
  })
}

# Attach policy to authenticated role
resource "aws_iam_role_policy_attachment" "cognito_authenticated_policy_attachment" {
  role       = aws_iam_role.cognito_authenticated_role.name
  policy_arn = aws_iam_policy.cognito_authenticated_policy.arn
}

# Attach identity pool roles
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated" = aws_iam_role.cognito_authenticated_role.arn
  }
}


