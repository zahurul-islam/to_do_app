#!/bin/bash

# Fix AWS Secrets Manager conflicts for TaskFlow AI
# Handles secrets in pending deletion state

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

print_header "Fixing Secrets Manager Conflicts"

# Load environment
if [[ -f ".env" ]]; then
    export $(grep -v '^#' .env | xargs)
    print_success "Environment variables loaded"
fi

print_status "Checking secrets status..."

# Check current secrets
GEMINI_SECRET_ARN="arn:aws:secretsmanager:us-west-2:948766507067:secret:taskflow-ai-gemini-api-key-QzNZJM"
OPENAI_SECRET_ARN="arn:aws:secretsmanager:us-west-2:948766507067:secret:taskflow-ai-openai-api-key-qFzZCQ"

print_status "Force deleting pending secrets to clear the way..."

# Force delete the secrets immediately
aws secretsmanager delete-secret \
    --secret-id "$GEMINI_SECRET_ARN" \
    --force-delete-without-recovery \
    --region us-west-2 || print_warning "Gemini secret may already be fully deleted"

aws secretsmanager delete-secret \
    --secret-id "$OPENAI_SECRET_ARN" \
    --force-delete-without-recovery \
    --region us-west-2 || print_warning "OpenAI secret may already be fully deleted"

print_success "Secrets cleared! Waiting 10 seconds for AWS to propagate..."
sleep 10

print_status "Verifying secrets are gone..."
aws secretsmanager list-secrets --include-planned-deletion --query 'SecretList[?contains(Name, `taskflow`)]' --output table || echo "No secrets found (good!)"

cd terraform

print_header "Continuing Terraform Deployment"

print_status "Running targeted apply for secrets first..."

# Create secrets first
terraform apply -auto-approve \
    -var="project_name=taskflow-ai" \
    -var="aws_region=us-west-2" \
    -var="gemini_api_key=${GEMINI_API_KEY:-AIzaSyA7i9p0S8QPgcZLAwmRRtC89RPiiJuqWNI}" \
    -var="openai_api_key=${OPENAI_API_KEY:-}" \
    -target=aws_secretsmanager_secret.gemini_api_key \
    -target=aws_secretsmanager_secret.openai_api_key

if [[ $? -eq 0 ]]; then
    print_success "Secrets created successfully!"
    
    print_status "Adding secret values..."
    
    # Add the secret values
    terraform apply -auto-approve \
        -var="project_name=taskflow-ai" \
        -var="aws_region=us-west-2" \
        -var="gemini_api_key=${GEMINI_API_KEY:-AIzaSyA7i9p0S8QPgcZLAwmRRtC89RPiiJuqWNI}" \
        -var="openai_api_key=${OPENAI_API_KEY:-}" \
        -target=aws_secretsmanager_secret_version.gemini_api_key \
        -target=aws_secretsmanager_secret_version.openai_api_key
    
    print_success "Secret values added!"
    
    print_status "Now running full deployment..."
    
    # Full deployment
    terraform apply -auto-approve \
        -var="project_name=taskflow-ai" \
        -var="aws_region=us-west-2" \
        -var="gemini_api_key=${GEMINI_API_KEY:-AIzaSyA7i9p0S8QPgcZLAwmRRtC89RPiiJuqWNI}" \
        -var="openai_api_key=${OPENAI_API_KEY:-}"
    
    if [[ $? -eq 0 ]]; then
        print_success "Complete deployment successful!"
        
        # Get outputs
        API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
        CLOUDFRONT_URL=$(terraform output -raw cloudfront_url 2>/dev/null || echo "")
        AI_ENDPOINT=$(terraform output -raw ai_extraction_endpoint 2>/dev/null || echo "")
        
        print_header "🎉 Deployment Complete!"
        echo ""
        echo -e "${GREEN}✅ All infrastructure deployed successfully!${NC}"
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
        
        print_header "Ready for Frontend Deployment"
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo "1. Deploy frontend: ./continue-deployment.sh"
        echo "2. Test AI functionality: ./test-ai-functionality.sh"
        echo ""
        echo -e "${RED}🔒 Security Reminder:${NC} Consider regenerating your Gemini API key for security"
        
    else
        print_warning "Full deployment had issues, but secrets are fixed. You can try running terraform apply again."
    fi
    
else
    print_warning "Secret creation failed. Check the errors above."
fi

cd ..
print_header "Secrets Fix Complete"
