#!/bin/bash

# Continue TaskFlow AI deployment after fixing conflicts
# Simple continuation script for partial deployment

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_header "Continuing TaskFlow AI Deployment"

# Load environment
if [[ -f ".env" ]]; then
    export $(grep -v '^#' .env | xargs)
    print_success "Environment variables loaded"
fi

cd terraform

# First, let's remove the conflicting IAM resources from state if they exist
print_status "Cleaning up conflicting IAM resources..."
terraform state rm aws_iam_role.cognito_authenticated_role 2>/dev/null || true
terraform state rm aws_iam_policy.cognito_authenticated_policy 2>/dev/null || true
terraform state rm aws_iam_role_policy_attachment.cognito_authenticated_attachment 2>/dev/null || true

# Continue the deployment excluding the problematic resources for now
print_status "Continuing deployment (excluding conflicted resources)..."

# Deploy everything except the problematic IAM resources
terraform apply -auto-approve \
    -var="project_name=taskflow-ai" \
    -var="aws_region=us-west-2" \
    -var="gemini_api_key=${GEMINI_API_KEY:-}" \
    -var="openai_api_key=${OPENAI_API_KEY:-}" \
    -target=aws_lambda_function.ai_extractor \
    -target=aws_api_gateway_resource.ai_resource \
    -target=aws_api_gateway_resource.ai_extract_resource \
    -target=aws_api_gateway_method.ai_extract_post \
    -target=aws_api_gateway_method.ai_extract_options \
    -target=aws_api_gateway_integration.ai_extract_integration \
    -target=aws_api_gateway_integration.ai_extract_options_integration \
    -target=aws_api_gateway_method_response.ai_extract_response_200 \
    -target=aws_api_gateway_method_response.ai_extract_options_response_200

if [[ $? -eq 0 ]]; then
    print_success "Core AI resources deployed successfully"
    
    # Now try the integration responses
    print_status "Creating integration responses..."
    terraform apply -auto-approve \
        -var="project_name=taskflow-ai" \
        -var="aws_region=us-west-2" \
        -var="gemini_api_key=${GEMINI_API_KEY:-}" \
        -var="openai_api_key=${OPENAI_API_KEY:-}" \
        -target=aws_api_gateway_integration_response.ai_extract_integration_response \
        -target=aws_api_gateway_integration_response.ai_extract_options_integration_response
    
    print_success "Integration responses created"
fi

# Try a final complete apply
print_status "Final deployment pass..."
terraform apply -auto-approve \
    -var="project_name=taskflow-ai" \
    -var="aws_region=us-west-2" \
    -var="gemini_api_key=${GEMINI_API_KEY:-}" \
    -var="openai_api_key=${OPENAI_API_KEY:-}"

# Get outputs
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url 2>/dev/null || echo "")
AI_ENDPOINT=$(terraform output -raw ai_extraction_endpoint 2>/dev/null || echo "")

cd ..

print_header "Deployment Status"

if [[ ! -z "$CLOUDFRONT_URL" ]]; then
    print_success "✅ Infrastructure deployment completed!"
    echo ""
    echo -e "${BLUE}📱 Application URL:${NC} $CLOUDFRONT_URL"
    echo -e "${BLUE}🔗 API Gateway URL:${NC} $API_URL"
    echo -e "${BLUE}🤖 AI Extraction Endpoint:${NC} $AI_ENDPOINT"
    echo ""
    
    print_status "Configuring and deploying frontend..."
    
    # Configure frontend
    cat > frontend/config.json << EOF
{
  "region": "us-west-2",
  "userPoolId": "$(cd terraform && terraform output -raw user_pool_id)",
  "userPoolClientId": "$(cd terraform && terraform output -raw user_pool_client_id)",
  "apiGatewayUrl": "$API_URL"
}
EOF
    
    # Copy enhanced files
    cp frontend/index-ai-enhanced.html frontend/index.html
    cp frontend/app-ai-enhanced.js frontend/app.js
    
    # Deploy to S3
    S3_BUCKET=$(cd terraform && terraform output -raw s3_bucket_name)
    aws s3 sync frontend/ s3://$S3_BUCKET/ \
        --exclude "*.md" \
        --exclude "*-ai-enhanced.*" \
        --exclude "*-unified.*" \
        --exclude "*-modern.*" \
        --delete
    
    # Invalidate CloudFront
    DISTRIBUTION_ID=$(cd terraform && terraform output -raw cloudfront_distribution_id)
    aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*" >/dev/null
    
    print_success "Frontend deployed successfully!"
    
    print_header "🎉 TaskFlow AI Deployment Complete!"
    echo ""
    echo -e "${GREEN}🚀 Your AI-powered todo app is ready!${NC}"
    echo ""
    echo -e "${YELLOW}🔗 Open your app:${NC} $CLOUDFRONT_URL"
    echo ""
    echo -e "${BLUE}✨ Features available:${NC}"
    echo "• 🤖 AI task extraction with your Gemini API key"
    echo "• 🎨 Modern glassmorphism UI with dark theme"
    echo "• 📧 Smart email and notes processing"
    echo "• 🧠 Intelligent categorization and priorities"
    echo "• 📅 Automatic due date extraction"
    echo ""
    echo -e "${YELLOW}🧪 Test your deployment:${NC} ./test-ai-functionality.sh"
    
else
    print_warning "⚠️ Deployment partially completed - some resources may need manual attention"
    echo ""
    echo -e "${YELLOW}Try the following:${NC}"
    echo "1. Check terraform state: cd terraform && terraform show"
    echo "2. Run manual apply: cd terraform && terraform apply"
    echo "3. Or contact support with the error details"
fi
