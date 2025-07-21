#!/bin/bash

# Fix TaskFlow AI deployment conflicts
# Comprehensive solution for state management and resource conflicts

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if AWS resource exists
check_iam_role_exists() {
    aws iam get-role --role-name "$1" >/dev/null 2>&1
}

check_iam_policy_exists() {
    aws iam list-policies --scope Local --query "Policies[?PolicyName=='$1'].Arn" --output text | grep -q .
}

get_api_gateway_id() {
    aws apigateway get-rest-apis --query 'items[?name==`todo-api`].id' --output text
}

print_header "TaskFlow AI Deployment Conflict Resolution"

# Load environment
if [[ -f ".env" ]]; then
    export $(grep -v '^#' .env | xargs)
    print_success "Environment variables loaded"
fi

cd terraform

print_header "Phase 1: Initialize Terraform and Check Current State"

# Initialize terraform
print_status "Initializing Terraform..."
terraform init

# Check if state exists and what's in it
print_status "Checking current Terraform state..."
STATE_RESOURCES=$(terraform state list 2>/dev/null | wc -l)
print_status "Current state contains $STATE_RESOURCES resources"

print_header "Phase 2: Handle Existing AWS Resources"

# Get API Gateway ID if it exists
API_ID=$(get_api_gateway_id)
if [[ ! -z "$API_ID" ]]; then
    print_success "Found existing API Gateway: $API_ID"
else
    print_warning "No existing API Gateway found"
fi

# Check for existing IAM resources
IAM_ROLE_NAME="taskflow-cognito-authenticated-role-dev"
IAM_POLICY_NAME="taskflow-cognito-authenticated-policy"

print_status "Checking for existing IAM resources..."

if check_iam_role_exists "$IAM_ROLE_NAME"; then
    print_warning "IAM Role $IAM_ROLE_NAME already exists in AWS"
    IAM_ROLE_EXISTS=true
else
    print_status "IAM Role $IAM_ROLE_NAME does not exist"
    IAM_ROLE_EXISTS=false
fi

if check_iam_policy_exists "$IAM_POLICY_NAME"; then
    print_warning "IAM Policy $IAM_POLICY_NAME already exists in AWS"
    IAM_POLICY_EXISTS=true
    # Get the policy ARN
    IAM_POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$IAM_POLICY_NAME'].Arn" --output text)
    print_status "Policy ARN: $IAM_POLICY_ARN"
else
    print_status "IAM Policy $IAM_POLICY_NAME does not exist"
    IAM_POLICY_EXISTS=false
fi

print_header "Phase 3: Import Existing Resources into Terraform State"

# Import existing resources if they exist but are not in state
if [[ "$IAM_ROLE_EXISTS" == true ]]; then
    # Check if role is already in state
    if ! terraform state show aws_iam_role.cognito_authenticated_role >/dev/null 2>&1; then
        print_status "Importing existing IAM role into Terraform state..."
        terraform import aws_iam_role.cognito_authenticated_role "$IAM_ROLE_NAME" || print_warning "Failed to import IAM role (may already be managed)"
    else
        print_status "IAM role already in Terraform state"
    fi
fi

if [[ "$IAM_POLICY_EXISTS" == true && ! -z "$IAM_POLICY_ARN" ]]; then
    # Check if policy is already in state
    if ! terraform state show aws_iam_policy.cognito_authenticated_policy >/dev/null 2>&1; then
        print_status "Importing existing IAM policy into Terraform state..."
        terraform import aws_iam_policy.cognito_authenticated_policy "$IAM_POLICY_ARN" || print_warning "Failed to import IAM policy (may already be managed)"
    else
        print_status "IAM policy already in Terraform state"
    fi
fi

# Import API Gateway if it exists
if [[ ! -z "$API_ID" ]]; then
    if ! terraform state show aws_api_gateway_rest_api.todos_api >/dev/null 2>&1; then
        print_status "Importing existing API Gateway into Terraform state..."
        terraform import aws_api_gateway_rest_api.todos_api "$API_ID" || print_warning "Failed to import API Gateway (may already be managed)"
    else
        print_status "API Gateway already in Terraform state"
    fi
fi

print_header "Phase 4: Strategic Deployment"

# Strategy: Deploy in layers to avoid dependency issues
print_status "Deploying core infrastructure first..."

# Deploy core resources (skip problematic integration responses initially)
terraform apply -auto-approve \
    -var="project_name=taskflow-ai" \
    -var="aws_region=us-west-2" \
    -var="gemini_api_key=${GEMINI_API_KEY:-}" \
    -var="openai_api_key=${OPENAI_API_KEY:-}" \
    -target=aws_cognito_user_pool.main \
    -target=aws_cognito_user_pool_client.main \
    -target=aws_lambda_function.ai_extractor \
    -target=aws_api_gateway_rest_api.todos_api \
    -target=aws_api_gateway_resource.ai_resource \
    -target=aws_api_gateway_resource.ai_extract_resource \
    -target=aws_api_gateway_method.ai_extract_post \
    -target=aws_api_gateway_method.ai_extract_options || print_warning "Core deployment had issues"

print_status "Deploying API Gateway integrations..."

# Deploy integrations before integration responses
terraform apply -auto-approve \
    -var="project_name=taskflow-ai" \
    -var="aws_region=us-west-2" \
    -var="gemini_api_key=${GEMINI_API_KEY:-}" \
    -var="openai_api_key=${OPENAI_API_KEY:-}" \
    -target=aws_api_gateway_integration.ai_extract_integration \
    -target=aws_api_gateway_integration.ai_extract_options_integration || print_warning "Integration deployment had issues"

print_status "Deploying method responses..."

# Deploy method responses
terraform apply -auto-approve \
    -var="project_name=taskflow-ai" \
    -var="aws_region=us-west-2" \
    -var="gemini_api_key=${GEMINI_API_KEY:-}" \
    -var="openai_api_key=${OPENAI_API_KEY:-}" \
    -target=aws_api_gateway_method_response.ai_extract_response_200 \
    -target=aws_api_gateway_method_response.ai_extract_options_response_200 || print_warning "Method response deployment had issues"

print_status "Deploying integration responses..."

# Now deploy integration responses
terraform apply -auto-approve \
    -var="project_name=taskflow-ai" \
    -var="aws_region=us-west-2" \
    -var="gemini_api_key=${GEMINI_API_KEY:-}" \
    -var="openai_api_key=${OPENAI_API_KEY:-}" \
    -target=aws_api_gateway_integration_response.ai_extract_integration_response \
    -target=aws_api_gateway_integration_response.ai_extract_options_integration_response || print_warning "Integration response deployment had issues"

print_header "Phase 5: Complete Deployment"

print_status "Running final complete deployment..."

# Final comprehensive apply
terraform apply -auto-approve \
    -var="project_name=taskflow-ai" \
    -var="aws_region=us-west-2" \
    -var="gemini_api_key=${GEMINI_API_KEY:-}" \
    -var="openai_api_key=${OPENAI_API_KEY:-}"

if [[ $? -eq 0 ]]; then
    print_success "Infrastructure deployment completed successfully!"
    
    # Get outputs
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
    CLOUDFRONT_URL=$(terraform output -raw cloudfront_url 2>/dev/null || echo "")
    AI_ENDPOINT=$(terraform output -raw ai_extraction_endpoint 2>/dev/null || echo "")
    
    print_header "Deployment Results"
    echo ""
    echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
    echo ""
    if [[ ! -z "$CLOUDFRONT_URL" ]]; then
        echo -e "${BLUE}📱 Application URL:${NC} $CLOUDFRONT_URL"
    fi
    if [[ ! -z "$API_URL" ]]; then
        echo -e "${BLUE}🔗 API Gateway URL:${NC} $API_URL"
    fi
    if [[ ! -z "$AI_ENDPOINT" ]]; then
        echo -e "${BLUE}🤖 AI Extraction Endpoint:${NC} $AI_ENDPOINT"
    fi
    echo ""
    
    cd ..
    
    print_status "Ready for frontend deployment..."
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Run: ./continue-deployment.sh (for frontend deployment)"
    echo "2. Or run: ./test-ai-functionality.sh (to test the deployment)"
    
else
    print_error "Deployment encountered issues. Check the errors above."
    echo ""
    echo -e "${YELLOW}Troubleshooting options:${NC}"
    echo "1. Check Terraform state: terraform state list"
    echo "2. Manual resource cleanup: ./cleanup.sh"
    echo "3. Re-run this script: ./fix-deployment-conflicts.sh"
fi

print_header "Deployment Fix Complete"
