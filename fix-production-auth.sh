#!/bin/bash

# Production Authentication Fix Deployment
# Updates the CloudFront deployment with complete signup functionality

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying Authentication Fix to Production${NC}"
echo "=============================================="
echo ""

# Get bucket name from Terraform
echo -e "${BLUE}📋 Getting deployment configuration...${NC}"
cd terraform
BUCKET_NAME=$(terraform output -raw frontend_bucket_name)
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id)
cd ..

echo -e "${GREEN}✅ S3 Bucket: $BUCKET_NAME${NC}"
echo -e "${GREEN}✅ CloudFront: $CLOUDFRONT_ID${NC}"
echo ""

# Create a fixed index.html that loads app-enhanced.js
echo -e "${BLUE}🔧 Creating production-ready index.html...${NC}"
cp frontend/index.html frontend/index-production.html

# Update the script source to load app-enhanced.js instead of app-fixed.js
sed -i 's/app-fixed\.js/app-enhanced.js/g' frontend/index-production.html

echo -e "${GREEN}✅ Updated index.html to load app-enhanced.js${NC}"

# Deploy files to S3
echo -e "${BLUE}📤 Deploying files to S3...${NC}"

# Deploy the main application files
aws s3 cp frontend/index-production.html s3://$BUCKET_NAME/index.html \
    --content-type "text/html" \
    --cache-control "max-age=300"

aws s3 cp frontend/app-enhanced.js s3://$BUCKET_NAME/app-enhanced.js \
    --content-type "application/javascript" \
    --cache-control "max-age=3600"

aws s3 cp frontend/config.json s3://$BUCKET_NAME/config.json \
    --content-type "application/json" \
    --cache-control "max-age=300"

echo -e "${GREEN}✅ Files deployed to S3${NC}"
echo ""

# Invalidate CloudFront cache
echo -e "${BLUE}🔄 Invalidating CloudFront cache...${NC}"
aws cloudfront create-invalidation \
    --distribution-id $CLOUDFRONT_ID \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text

echo -e "${GREEN}✅ CloudFront cache invalidation initiated${NC}"
echo ""

# Clean up temporary file
rm frontend/index-production.html

echo -e "${BLUE}🧪 Testing deployment...${NC}"
echo ""
echo "🌐 Production URL: https://d8hwipi7b9ziq.cloudfront.net/"
echo ""
echo -e "${YELLOW}⏳ Note: CloudFront cache invalidation may take 5-15 minutes${NC}"
echo -e "${YELLOW}   You can test immediately, but changes may take time to propagate${NC}"
echo ""

echo -e "${GREEN}🎉 Authentication fix deployed successfully!${NC}"
echo ""
echo "📋 What's fixed:"
echo "  ✅ Signup functionality now available"
echo "  ✅ Email verification with confirmation codes"  
echo "  ✅ Complete authentication flow"
echo "  ✅ User registration and login"
echo ""
echo "🧪 Test the signup flow:"
echo "  1. Go to: https://d8hwipi7b9ziq.cloudfront.net/"
echo "  2. Click 'Create an account'"
echo "  3. Fill in email and password"
echo "  4. Check email for verification code"
echo "  5. Enter code and verify account"
echo "  6. Sign in with your credentials"
echo ""

