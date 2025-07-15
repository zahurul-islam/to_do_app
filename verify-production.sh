#!/bin/bash

# Production Authentication Verification Script
# Tests that signup functionality is working on CloudFront

echo "🔍 Verifying Production Deployment"
echo "=================================="
echo ""

CLOUDFRONT_URL="https://d8hwipi7b9ziq.cloudfront.net"

echo "📋 Checking deployed files..."
echo ""

# Test if the main page loads
echo "🌐 Testing main page..."
response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/")
if [ "$response" = "200" ]; then
    echo "✅ Main page loads successfully (HTTP $response)"
else
    echo "❌ Main page failed to load (HTTP $response)"
fi

# Test if app-enhanced.js is accessible
echo "🔧 Testing app-enhanced.js..."
response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/app-enhanced.js")
if [ "$response" = "200" ]; then
    echo "✅ app-enhanced.js is accessible (HTTP $response)"
else
    echo "❌ app-enhanced.js failed to load (HTTP $response)"
fi

# Test if config.json is accessible
echo "⚙️  Testing config.json..."
response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/config.json")
if [ "$response" = "200" ]; then
    echo "✅ config.json is accessible (HTTP $response)"
else
    echo "❌ config.json failed to load (HTTP $response)"
fi

echo ""
echo "🎯 Manual Testing Instructions:"
echo "================================"
echo ""
echo "1. Open: $CLOUDFRONT_URL"
echo "2. Look for 'Create an account' link below the sign-in form"
echo "3. Click it to test signup functionality"
echo ""
echo "📋 Expected signup flow:"
echo "  ➜ Click 'Create an account'"
echo "  ➜ Fill email and password (min 8 chars)"
echo "  ➜ Click 'Create Account' button"
echo "  ➜ Check email for verification code"
echo "  ➜ Enter 6-digit code"
echo "  ➜ Click 'Verify Email'"
echo "  ➜ Account confirmed, can now sign in"
echo ""
echo "🕐 Note: CloudFront cache updates may take 5-15 minutes"
echo "   If you don't see changes immediately, wait a few minutes and refresh"
echo ""

# Show current AWS config for reference
echo "🔧 Current AWS Configuration:"
aws sts get-caller-identity --query 'Account' --output text 2>/dev/null | head -1 | xargs -I {} echo "   Account: {}"
aws configure get region 2>/dev/null | xargs -I {} echo "   Region: {}"
echo ""

echo "✅ Verification complete!"
echo ""
echo "🌐 Production URL: $CLOUDFRONT_URL"

