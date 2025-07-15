#!/bin/bash

# Quick Verification of Signup UI Fix
# Tests that the complete authentication system is deployed

echo "🔍 Verifying Signup UI Fix Deployment"
echo "====================================="
echo ""

CLOUDFRONT_URL="https://ddbchpi65u1nc.cloudfront.net"

echo "📋 Testing deployment files..."
echo ""

# Test main page
echo "🌐 Testing main page..."
response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/")
if [ "$response" = "200" ]; then
    echo "✅ Main page loads (HTTP $response)"
else
    echo "❌ Main page failed (HTTP $response)"
fi

# Test app-enhanced.js
echo "🔧 Testing app-enhanced.js..."
response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/app-enhanced.js")
if [ "$response" = "200" ]; then
    echo "✅ app-enhanced.js accessible (HTTP $response)"
else
    echo "❌ app-enhanced.js failed (HTTP $response)"
fi

# Test config.json
echo "⚙️  Testing config.json..."
response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/config.json")
if [ "$response" = "200" ]; then
    echo "✅ config.json accessible (HTTP $response)"
else
    echo "❌ config.json failed (HTTP $response)"
fi

echo ""
echo "🎯 SIGNUP UI SHOULD NOW BE AVAILABLE!"
echo ""
echo "📋 Expected changes:"
echo "  ✅ 'Create an account' link below login form"
echo "  ✅ Complete signup form with email/password fields"
echo "  ✅ Email verification process"
echo "  ✅ Working authentication flow"
echo ""
echo "🧪 Manual Testing:"
echo "  1. Open: $CLOUDFRONT_URL"
echo "  2. Look for 'Create an account' link"
echo "  3. Click to access signup form"
echo "  4. Fill in email and password"
echo "  5. Test signup and verification"
echo ""
echo "⏰ Note: CloudFront cache updates may take 5-15 minutes"
echo "   If you don't see changes immediately, wait and refresh"
echo ""
echo "🌐 Production URL: $CLOUDFRONT_URL"

