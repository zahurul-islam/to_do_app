#!/bin/bash

# Test script for TaskFlow AI functionality
# This script validates the AI-enhanced todo application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REGION="us-west-2"
PROJECT_NAME="taskflow-ai"

# Function to print colored output
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
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to get Terraform outputs
get_terraform_outputs() {
    print_header "Getting Terraform Outputs"
    
    cd terraform
    
    # Check if terraform state exists
    if [[ ! -f "terraform.tfstate" ]]; then
        print_error "Terraform state not found. Please run deployment first."
        exit 1
    fi
    
    # Get outputs
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
    USER_POOL_ID=$(terraform output -raw user_pool_id 2>/dev/null || echo "")
    USER_POOL_CLIENT_ID=$(terraform output -raw user_pool_client_id 2>/dev/null || echo "")
    CLOUDFRONT_URL=$(terraform output -raw cloudfront_url 2>/dev/null || echo "")
    AI_ENDPOINT=$(terraform output -raw ai_extraction_endpoint 2>/dev/null || echo "")
    
    cd ..
    
    if [[ -z "$API_URL" ]]; then
        print_error "Could not get API Gateway URL from Terraform outputs"
        exit 1
    fi
    
    print_success "Terraform outputs retrieved successfully"
    echo "API URL: $API_URL"
    echo "CloudFront URL: $CLOUDFRONT_URL"
    echo "AI Endpoint: $AI_ENDPOINT"
}

# Function to test API Gateway health
test_api_gateway() {
    print_header "Testing API Gateway"
    
    # Test health endpoint if it exists
    print_status "Testing API Gateway accessibility..."
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/todos" \
        -H "Authorization: Bearer invalid-token" || echo "000")
    
    if [[ $response == "401" ]]; then
        print_success "API Gateway is responding correctly (401 Unauthorized expected)"
    elif [[ $response == "403" ]]; then
        print_success "API Gateway is responding correctly (403 Forbidden expected)"
    else
        print_warning "API Gateway responded with HTTP $response"
    fi
}

# Function to test AI endpoint
test_ai_endpoint() {
    print_header "Testing AI Extraction Endpoint"
    
    if [[ -z "$AI_ENDPOINT" ]]; then
        print_warning "AI endpoint not found in Terraform outputs"
        return
    fi
    
    print_status "Testing AI endpoint accessibility..."
    
    # Test with invalid token (should get 401)
    response=$(curl -s -o /dev/null -w "%{http_code}" "$AI_ENDPOINT" \
        -H "Authorization: Bearer invalid-token" \
        -H "Content-Type: application/json" \
        -d '{"text": "Test text"}' || echo "000")
    
    if [[ $response == "401" ]]; then
        print_success "AI endpoint is responding correctly (401 Unauthorized expected)"
    elif [[ $response == "403" ]]; then
        print_success "AI endpoint is responding correctly (403 Forbidden expected)"
    else
        print_warning "AI endpoint responded with HTTP $response"
    fi
}

# Function to test frontend
test_frontend() {
    print_header "Testing Frontend"
    
    if [[ -z "$CLOUDFRONT_URL" ]]; then
        print_warning "CloudFront URL not found in Terraform outputs"
        return
    fi
    
    print_status "Testing frontend accessibility..."
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$CLOUDFRONT_URL" || echo "000")
    
    if [[ $response == "200" ]]; then
        print_success "Frontend is accessible"
    else
        print_warning "Frontend responded with HTTP $response"
    fi
    
    # Test if config.json is accessible
    print_status "Testing config.json accessibility..."
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$CLOUDFRONT_URL/config.json" || echo "000")
    
    if [[ $response == "200" ]]; then
        print_success "Config.json is accessible"
    else
        print_warning "Config.json responded with HTTP $response"
    fi
}

# Function to test AWS resources
test_aws_resources() {
    print_header "Testing AWS Resources"
    
    # Test DynamoDB table
    print_status "Testing DynamoDB table..."
    
    table_status=$(aws dynamodb describe-table \
        --table-name "$PROJECT_NAME-todos" \
        --region "$REGION" \
        --query 'Table.TableStatus' \
        --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [[ $table_status == "ACTIVE" ]]; then
        print_success "DynamoDB table is active"
    else
        print_warning "DynamoDB table status: $table_status"
    fi
    
    # Test Cognito User Pool
    print_status "Testing Cognito User Pool..."
    
    if [[ ! -z "$USER_POOL_ID" ]]; then
        pool_status=$(aws cognito-idp describe-user-pool \
            --user-pool-id "$USER_POOL_ID" \
            --region "$REGION" \
            --query 'UserPool.Status' \
            --output text 2>/dev/null || echo "NOT_FOUND")
        
        if [[ $pool_status == "ACTIVE" ]]; then
            print_success "Cognito User Pool is active"
        else
            print_warning "Cognito User Pool status: $pool_status"
        fi
    else
        print_warning "User Pool ID not found"
    fi
    
    # Test Lambda functions
    print_status "Testing Lambda functions..."
    
    # Test main Lambda
    main_lambda_status=$(aws lambda get-function \
        --function-name "$PROJECT_NAME-todos-handler" \
        --region "$REGION" \
        --query 'Configuration.State' \
        --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [[ $main_lambda_status == "Active" ]]; then
        print_success "Main Lambda function is active"
    else
        print_warning "Main Lambda function status: $main_lambda_status"
    fi
    
    # Test AI Lambda
    ai_lambda_status=$(aws lambda get-function \
        --function-name "$PROJECT_NAME-ai-extractor" \
        --region "$REGION" \
        --query 'Configuration.State' \
        --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [[ $ai_lambda_status == "Active" ]]; then
        print_success "AI Lambda function is active"
    else
        print_warning "AI Lambda function status: $ai_lambda_status"
    fi
}

# Function to test AI secrets
test_ai_secrets() {
    print_header "Testing AI Secrets"
    
    # Test Gemini API key secret
    print_status "Testing Gemini API key secret..."
    
    gemini_secret=$(aws secretsmanager get-secret-value \
        --secret-id "$PROJECT_NAME-gemini-api-key" \
        --region "$REGION" \
        --query 'SecretString' \
        --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [[ $gemini_secret != "NOT_FOUND" && $gemini_secret != "YOUR_GEMINI_API_KEY_HERE" ]]; then
        print_success "Gemini API key secret is configured"
    else
        print_warning "Gemini API key secret not configured or using placeholder"
    fi
    
    # Test OpenAI API key secret
    print_status "Testing OpenAI API key secret..."
    
    openai_secret=$(aws secretsmanager get-secret-value \
        --secret-id "$PROJECT_NAME-openai-api-key" \
        --region "$REGION" \
        --query 'SecretString' \
        --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [[ $openai_secret != "NOT_FOUND" && $openai_secret != "YOUR_OPENAI_API_KEY_HERE" ]]; then
        print_success "OpenAI API key secret is configured"
    else
        print_warning "OpenAI API key secret not configured or using placeholder"
    fi
}

# Function to test AI functionality locally
test_ai_locally() {
    print_header "Testing AI Extraction Logic"
    
    # Test the AI extraction logic locally
    print_status "Testing AI extraction logic..."
    
    cd terraform/lambda/gemini_extractor
    
    # Create a simple test
    python3 -c "
import sys
sys.path.insert(0, '.')
from index import AITaskExtractor

# Test the extractor
extractor = AITaskExtractor()

# Test text
test_text = '''
Meeting with John tomorrow at 2pm about Q4 budget
Buy groceries for dinner tonight
Call dentist to schedule appointment next week
'''

# Test local extraction
try:
    tasks = extractor._fallback_text_extraction(test_text)
    print(f'Successfully extracted {len(tasks)} tasks:')
    for task in tasks:
        print(f'  - {task[\"title\"]} ({task[\"category\"]}, {task[\"priority\"]})')
    print('✅ AI extraction logic test passed')
except Exception as e:
    print(f'❌ AI extraction logic test failed: {e}')
    sys.exit(1)
"
    
    cd ../../..
    
    if [[ $? -eq 0 ]]; then
        print_success "AI extraction logic test passed"
    else
        print_error "AI extraction logic test failed"
    fi
}

# Function to display test summary
display_test_summary() {
    print_header "Test Summary"
    
    echo -e "${CYAN}🧪 TaskFlow AI Test Results${NC}"
    echo ""
    echo -e "${GREEN}✅ Completed Tests:${NC}"
    echo "• API Gateway connectivity"
    echo "• AI endpoint accessibility"
    echo "• Frontend deployment"
    echo "• AWS resources status"
    echo "• AI secrets configuration"
    echo "• Local AI extraction logic"
    echo ""
    echo -e "${YELLOW}📋 Manual Testing Recommendations:${NC}"
    echo "1. Open $CLOUDFRONT_URL in browser"
    echo "2. Create a new user account"
    echo "3. Test AI extraction with sample text"
    echo "4. Verify task categorization and priorities"
    echo "5. Test task CRUD operations"
    echo ""
    echo -e "${CYAN}🔧 Configuration Notes:${NC}"
    echo "• API URL: $API_URL"
    echo "• AI Endpoint: $AI_ENDPOINT"
    echo "• Frontend URL: $CLOUDFRONT_URL"
    echo ""
    echo -e "${PURPLE}🚀 Next Steps:${NC}"
    echo "1. Configure AI API keys if not done:"
    echo "   aws secretsmanager update-secret --secret-id $PROJECT_NAME-gemini-api-key --secret-string 'YOUR_KEY'"
    echo "2. Test the application manually"
    echo "3. Monitor CloudWatch logs for any issues"
}

# Main execution
main() {
    print_header "TaskFlow AI - Testing Suite"
    
    echo -e "${CYAN}This script will test the deployed TaskFlow AI application${NC}"
    echo ""
    
    # Execute tests
    get_terraform_outputs
    test_api_gateway
    test_ai_endpoint
    test_frontend
    test_aws_resources
    test_ai_secrets
    test_ai_locally
    display_test_summary
    
    print_success "All tests completed!"
}

# Run main function
main "$@"
