#!/bin/bash

# Fix deployment conflicts and continue deployment
# This script resolves resource conflicts and resumes deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header "Fixing Deployment Conflicts"

cd terraform

# Load environment variables if available
if [[ -f "../.env" ]]; then
    print_status "Loading environment variables..."
    export $(grep -v '^#' ../.env | xargs)
fi

# Check current state
print_status "Checking current Terraform state..."

# Try to import existing resources instead of conflicting
print_status "Attempting to resolve resource conflicts..."

# Method 1: Try to continue with current state
print_status "Attempting to continue deployment..."
if terraform apply -auto-approve \
    -var="project_name=taskflow-ai" \
    -var="aws_region=us-west-2" \
    -var="gemini_api_key=${GEMINI_API_KEY:-}" \
    -var="openai_api_key=${OPENAI_API_KEY:-}" \
    -target=aws_api_gateway_integration.ai_extract_integration \
    -target=aws_api_gateway_integration.ai_extract_options_integration; then
    
    print_success "Successfully created API Gateway integrations"
    
    # Now try to create the integration responses
    print_status "Creating integration responses..."
    terraform apply -auto-approve \
        -var="project_name=taskflow-ai" \
        -var="aws_region=us-west-2" \
        -var="gemini_api_key=${GEMINI_API_KEY:-}" \
        -var="openai_api_key=${OPENAI_API_KEY:-}" \
        -target=aws_api_gateway_integration_response.ai_extract_integration_response \
        -target=aws_api_gateway_integration_response.ai_extract_options_integration_response
    
    print_success "Integration responses created successfully"
else
    print_warning "Targeted deployment failed, trying full deployment..."
fi

# Try full deployment
print_status "Running full deployment..."
terraform apply -auto-approve \
    -var="project_name=taskflow-ai" \
    -var="aws_region=us-west-2" \
    -var="gemini_api_key=${GEMINI_API_KEY:-}" \
    -var="openai_api_key=${OPENAI_API_KEY:-}"

if [[ $? -eq 0 ]]; then
    print_success "Deployment completed successfully!"
    
    # Get outputs
    print_status "Getting deployment outputs..."
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
    CLOUDFRONT_URL=$(terraform output -raw cloudfront_url 2>/dev/null || echo "")
    AI_ENDPOINT=$(terraform output -raw ai_extraction_endpoint 2>/dev/null || echo "")
    
    print_header "Deployment Summary"
    echo -e "${GREEN}🚀 TaskFlow AI deployed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📱 Application URL:${NC} $CLOUDFRONT_URL"
    echo -e "${BLUE}🔗 API Gateway URL:${NC} $API_URL"
    echo -e "${BLUE}🤖 AI Extraction Endpoint:${NC} $AI_ENDPOINT"
    echo ""
    echo -e "${YELLOW}🔧 Next Steps:${NC}"
    echo "1. Configure frontend: cd .. && cp frontend/index-ai-enhanced.html frontend/index.html"
    echo "2. Deploy frontend: aws s3 sync frontend/ s3://\$(terraform output -raw s3_bucket_name)/"
    echo "3. Test the application: cd .. && ./test-ai-functionality.sh"
    
else
    print_error "Deployment encountered issues"
    
    print_header "Manual Resolution Steps"
    echo -e "${YELLOW}If there are still conflicts, try:${NC}"
    echo ""
    echo -e "${BLUE}1. Clean up conflicting resources:${NC}"
    echo "   terraform state rm aws_iam_role.cognito_authenticated_role || true"
    echo "   terraform state rm aws_iam_policy.cognito_authenticated_policy || true"
    echo ""
    echo -e "${BLUE}2. Re-run deployment:${NC}"
    echo "   terraform apply -auto-approve"
    echo ""
    echo -e "${BLUE}3. Or destroy and redeploy:${NC}"
    echo "   terraform destroy -auto-approve"
    echo "   terraform apply -auto-approve"
fi

cd ..
