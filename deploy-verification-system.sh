#!/bin/bash

# Deploy Complete Email Verification System
# Includes verification page and direct links for users

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Deploying Complete Email Verification System${NC}"
echo "================================================"
echo ""

# Get deployment details
cd terraform
BUCKET_NAME=$(terraform output -raw frontend_bucket_name)
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id)
CLOUDFRONT_URL=$(terraform output -raw website_url)
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id)
cd ..

echo -e "${GREEN}✅ S3 Bucket: $BUCKET_NAME${NC}"
echo -e "${GREEN}✅ CloudFront: $CLOUDFRONT_ID${NC}"
echo -e "${GREEN}✅ Website: $CLOUDFRONT_URL${NC}"
echo -e "${GREEN}✅ User Pool: $USER_POOL_ID${NC}"
echo ""

# Deploy the verification page
echo -e "${BLUE}📤 Deploying email verification page...${NC}"

aws s3 cp frontend/verify-code.html s3://$BUCKET_NAME/verify-code.html \
    --content-type "text/html" \
    --cache-control "max-age=300"

aws s3 cp frontend/verify.html s3://$BUCKET_NAME/verify.html \
    --content-type "text/html" \
    --cache-control "max-age=300"

echo -e "${GREEN}✅ Verification pages deployed${NC}"
echo ""

# Invalidate CloudFront cache
echo -e "${BLUE}🔄 Invalidating CloudFront cache...${NC}"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id $CLOUDFRONT_ID \
    --paths "/verify-code.html" "/verify.html" \
    --query 'Invalidation.Id' \
    --output text)

echo -e "${GREEN}✅ Cache invalidation initiated: $INVALIDATION_ID${NC}"
echo ""

echo -e "${GREEN}🎉 Email Verification System Deployed!${NC}"
echo ""
echo "📋 Available verification methods:"
echo ""
echo "🔗 DIRECT VERIFICATION LINKS:"
echo "================================"
echo ""

echo -e "${BLUE}1. Main Verification Page:${NC}"
echo "   $CLOUDFRONT_URL/verify-code.html"
echo ""

echo -e "${BLUE}2. Advanced Verification Center:${NC}"
echo "   $CLOUDFRONT_URL/verify.html"
echo ""

echo -e "${BLUE}3. Email-Specific Verification Links:${NC}"
echo "   For any user: $CLOUDFRONT_URL/verify-code.html?email=USER_EMAIL"
echo ""

echo "📧 VERIFICATION LINK EXAMPLES:"
echo "================================"
echo ""

# Function to generate verification links
generate_verification_link() {
    local email=$1
    echo "   👤 $email:"
    echo "      🔗 $CLOUDFRONT_URL/verify-code.html?email=$email"
    echo ""
}

echo "Example verification links you can send to users:"
echo ""
generate_verification_link "user@example.com"
generate_verification_link "test@gmail.com"
generate_verification_link "demo@company.com"

echo "🧪 TESTING INSTRUCTIONS:"
echo "========================"
echo ""
echo "1. 📝 User Signs Up:"
echo "   - Go to: $CLOUDFRONT_URL"
echo "   - Click 'Create an account'"
echo "   - Fill email and password"
echo "   - Submit signup form"
echo ""
echo "2. 📧 User Receives Email:"
echo "   - AWS Cognito sends 6-digit code"
echo "   - User also gets verification link (manual)"
echo ""
echo "3. 🔗 Send Verification Link:"
echo "   - Email user: $CLOUDFRONT_URL/verify-code.html?email=THEIR_EMAIL"
echo "   - User clicks link and enters code"
echo ""
echo "4. ✅ Account Verified:"
echo "   - User can now sign in to main app"
echo "   - Full access to TaskFlow features"
echo ""

echo -e "${YELLOW}🛠️ MANUAL VERIFICATION TOOLS:${NC}"
echo ""
echo "Create verification link for specific user:"
echo '  echo "Verify your email: '"$CLOUDFRONT_URL"'/verify-code.html?email=USER@EXAMPLE.COM"'
echo ""
echo "Manual confirmation via CLI:"
echo "  aws cognito-idp admin-confirm-sign-up \\"
echo "    --user-pool-id $USER_POOL_ID \\"
echo "    --username USER@EXAMPLE.COM"
echo ""
echo "Resend verification code:"
echo "  aws cognito-idp resend-confirmation-code \\"
echo "    --client-id $CLIENT_ID \\"
echo "    --username USER@EXAMPLE.COM"
echo ""

echo -e "${BLUE}🌐 PRODUCTION URLS:${NC}"
echo ""
echo "Main App:           $CLOUDFRONT_URL"
echo "Code Verification:  $CLOUDFRONT_URL/verify-code.html"
echo "Verification Center: $CLOUDFRONT_URL/verify.html"
echo ""

echo -e "${GREEN}✅ Complete email verification system is now deployed!${NC}"
echo ""
echo "Users can now:"
echo "  ✅ Sign up for accounts"
echo "  ✅ Receive verification codes via email"
echo "  ✅ Use direct verification links"
echo "  ✅ Enter codes and verify accounts"
echo "  ✅ Sign in and use the application"

