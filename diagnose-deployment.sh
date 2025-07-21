#!/bin/bash

# Quick diagnosis of current AWS resources and Terraform state
# For TaskFlow AI deployment troubleshooting

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_section() {
    echo -e "\n${YELLOW}--- $1 ---${NC}"
}

print_header "TaskFlow AI Deployment Diagnosis"

cd terraform

print_section "Terraform State Check"
echo "Terraform initialization status:"
if [[ -d ".terraform" ]]; then
    echo -e "${GREEN}✅ Terraform initialized${NC}"
    echo "State file status:"
    if [[ -f "terraform.tfstate" ]]; then
        RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l)
        echo -e "${GREEN}✅ State file exists with $RESOURCE_COUNT resources${NC}"
        echo "Current resources in state:"
        terraform state list 2>/dev/null | head -10
        if [[ $RESOURCE_COUNT -gt 10 ]]; then
            echo "... and $((RESOURCE_COUNT - 10)) more"
        fi
    else
        echo -e "${YELLOW}⚠️ No local state file found${NC}"
    fi
else
    echo -e "${RED}❌ Terraform not initialized${NC}"
fi

print_section "AWS Resources Check"

echo "Checking IAM resources:"
IAM_ROLES=$(aws iam list-roles --query 'Roles[?contains(RoleName, `taskflow`)].RoleName' --output text 2>/dev/null || echo "")
if [[ ! -z "$IAM_ROLES" ]]; then
    echo -e "${YELLOW}⚠️ Found existing IAM roles:${NC} $IAM_ROLES"
else
    echo -e "${GREEN}✅ No conflicting IAM roles found${NC}"
fi

IAM_POLICIES=$(aws iam list-policies --scope Local --query 'Policies[?contains(PolicyName, `taskflow`)].PolicyName' --output text 2>/dev/null || echo "")
if [[ ! -z "$IAM_POLICIES" ]]; then
    echo -e "${YELLOW}⚠️ Found existing IAM policies:${NC} $IAM_POLICIES"
else
    echo -e "${GREEN}✅ No conflicting IAM policies found${NC}"
fi

echo -e "\nChecking API Gateway:"
API_GATEWAYS=$(aws apigateway get-rest-apis --query 'items[?contains(name, `todo`)].{Name:name,ID:id}' --output table 2>/dev/null || echo "None found")
echo "$API_GATEWAYS"

echo -e "\nChecking Lambda functions:"
LAMBDA_FUNCTIONS=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `taskflow`) || contains(FunctionName, `ai-extractor`)].FunctionName' --output text 2>/dev/null || echo "")
if [[ ! -z "$LAMBDA_FUNCTIONS" ]]; then
    echo -e "${GREEN}✅ Found Lambda functions:${NC} $LAMBDA_FUNCTIONS"
else
    echo -e "${YELLOW}⚠️ No Lambda functions found${NC}"
fi

echo -e "\nChecking S3 buckets:"
S3_BUCKETS=$(aws s3 ls | grep taskflow || echo "No TaskFlow buckets found")
echo "$S3_BUCKETS"

echo -e "\nChecking CloudFront distributions:"
CF_DISTRIBUTIONS=$(aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `taskflow`) || contains(Comment, `TaskFlow`)].{ID:Id,Status:Status,Comment:Comment}' --output table 2>/dev/null || echo "None found")
echo "$CF_DISTRIBUTIONS"

print_section "Environment Check"
echo "Environment variables:"
if [[ ! -z "$GEMINI_API_KEY" ]]; then
    echo -e "${GREEN}✅ GEMINI_API_KEY is set${NC}"
else
    echo -e "${RED}❌ GEMINI_API_KEY not set${NC}"
fi

if [[ ! -z "$OPENAI_API_KEY" ]]; then
    echo -e "${GREEN}✅ OPENAI_API_KEY is set${NC}"
else
    echo -e "${YELLOW}⚠️ OPENAI_API_KEY not set${NC}"
fi

print_section "Recommendations"
echo ""

# Determine the best course of action
if [[ -d ".terraform" ]] && [[ -f "terraform.tfstate" ]]; then
    RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l)
    if [[ $RESOURCE_COUNT -gt 0 ]]; then
        echo -e "${GREEN}✅ You have a working Terraform state${NC}"
        echo "Recommended action: Run 'terraform apply' to continue deployment"
    else
        echo -e "${YELLOW}⚠️ Terraform is initialized but state is empty${NC}"
        echo "Recommended action: Run './fix-deployment-conflicts.sh' to import existing resources"
    fi
elif [[ ! -z "$IAM_ROLES" ]] || [[ ! -z "$IAM_POLICIES" ]]; then
    echo -e "${RED}❌ You have existing AWS resources but no Terraform state${NC}"
    echo "Recommended action: Run './fix-deployment-conflicts.sh' to fix conflicts and import resources"
else
    echo -e "${BLUE}ℹ️ Starting fresh deployment${NC}"
    echo "Recommended action: Run './deploy.sh' for initial deployment"
fi

echo ""
echo -e "${BLUE}Available scripts:${NC}"
echo "• ./fix-deployment-conflicts.sh - Fix conflicts and import existing resources"
echo "• ./continue-deployment.sh - Continue deployment after fixes"
echo "• ./cleanup.sh - Clean up all resources and start fresh"
echo "• ./test-ai-functionality.sh - Test the deployed application"

cd ..
