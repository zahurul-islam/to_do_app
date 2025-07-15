# Add monitoring variables
variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing for Lambda functions"
  type        = bool
  default     = true
}

variable "cost_budget_limit" {
  description = "Monthly cost budget limit in USD"
  type        = number
  default     = 10
}

variable "dashboard_name" {
  description = "Name for the CloudWatch dashboard"
  type        = string
  default     = "TodoApp"
}

# Backup and recovery variables
variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain DynamoDB backups"
  type        = number
  default     = 7
}

# Security variables
variable "enable_waf" {
  description = "Enable AWS WAF for API Gateway"
  type        = bool
  default     = false
}

variable "trusted_ip_ranges" {
  description = "List of trusted IP ranges for WAF"
  type        = list(string)
  default     = []
}

# Performance variables
variable "lambda_memory_size" {
  description = "Memory allocation for Lambda function in MB"
  type        = number
  default     = 128
  
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 3008
    error_message = "Lambda memory size must be between 128 and 3008 MB."
  }
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
  default     = 30
  
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "api_gateway_caching_enabled" {
  description = "Enable caching for API Gateway"
  type        = bool
  default     = false
}

variable "api_gateway_cache_ttl" {
  description = "Cache TTL for API Gateway in seconds"
  type        = number
  default     = 300
}

# Multi-environment variables
variable "enable_multi_region" {
  description = "Enable multi-region deployment"
  type        = bool
  default     = false
}

variable "secondary_region" {
  description = "Secondary AWS region for multi-region deployment"
  type        = string
  default     = "us-east-1"
}

# Advanced Cognito variables
variable "cognito_mfa_configuration" {
  description = "MFA configuration for Cognito User Pool"
  type        = string
  default     = "OFF"
  
  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.cognito_mfa_configuration)
    error_message = "MFA configuration must be OFF, ON, or OPTIONAL."
  }
}

variable "cognito_password_minimum_length" {
  description = "Minimum password length for Cognito"
  type        = number
  default     = 8
}

variable "cognito_advanced_security_mode" {
  description = "Advanced security mode for Cognito"
  type        = string
  default     = "AUDIT"
  
  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.cognito_advanced_security_mode)
    error_message = "Advanced security mode must be OFF, AUDIT, or ENFORCED."
  }
}

# DynamoDB variables
variable "dynamodb_billing_mode" {
  description = "Billing mode for DynamoDB table"
  type        = string
  default     = "PAY_PER_REQUEST"
  
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "Billing mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "dynamodb_read_capacity" {
  description = "Read capacity units for DynamoDB (only used with PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "Write capacity units for DynamoDB (only used with PROVISIONED billing)"
  type        = number
  default     = 5
}

# API Gateway variables
variable "api_gateway_throttle_rate_limit" {
  description = "Rate limit for API Gateway throttling"
  type        = number
  default     = 1000
}

variable "api_gateway_throttle_burst_limit" {
  description = "Burst limit for API Gateway throttling"
  type        = number
  default     = 2000
}

# Lambda concurrency variables
variable "lambda_reserved_concurrency" {
  description = "Reserved concurrency for Lambda function (-1 for unreserved)"
  type        = number
  default     = -1
}

variable "lambda_provisioned_concurrency" {
  description = "Provisioned concurrency for Lambda function"
  type        = number
  default     = 0
}

# Observability variables
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "custom_metrics_namespace" {
  description = "Namespace for custom CloudWatch metrics"
  type        = string
  default     = "TodoApp"
}

# Compliance and governance variables
variable "data_classification" {
  description = "Data classification level"
  type        = string
  default     = "internal"
  
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be public, internal, confidential, or restricted."
  }
}

variable "compliance_framework" {
  description = "Compliance framework requirements"
  type        = list(string)
  default     = []
}

variable "data_retention_policy" {
  description = "Data retention policy in days"
  type        = number
  default     = 2555  # 7 years
}

# Feature flags
variable "feature_flags" {
  description = "Feature flags for the application"
  type = object({
    enable_analytics     = bool
    enable_rate_limiting = bool
    enable_audit_logs   = bool
    enable_data_export  = bool
  })
  default = {
    enable_analytics     = false
    enable_rate_limiting = true
    enable_audit_logs   = true
    enable_data_export  = false
  }
}

# Development and testing variables
variable "enable_debug_mode" {
  description = "Enable debug mode for development"
  type        = bool
  default     = false
}

variable "mock_external_services" {
  description = "Mock external services for testing"
  type        = bool
  default     = false
}

variable "test_data_cleanup_enabled" {
  description = "Enable automatic cleanup of test data"
  type        = bool
  default     = true
}
