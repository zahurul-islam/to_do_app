#!/bin/bash

# Email Verification Debugging and Emergency Fix Script
# Provides debugging tools and emergency user confirmation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

USER_POOL_ID="us-west-2_3TgtLQamd"
CLIENT_ID="6i27nq388mi7hmto8ouanos04d"

echo -e "${BLUE}🔧 Email Verification Debugging Tools${NC}"
echo "====================================="
echo ""

show_menu() {
    echo "🎯 Choose an action:"
    echo "  1. 📋 List all users in User Pool"
    echo "  2. 🔍 Check specific user status"
    echo "  3. ✅ Manually confirm user (emergency)"
    echo "  4. 📧 Resend confirmation code via CLI"
    echo "  5. 🧪 Test authentication flow"
    echo "  6. 🌐 Check production deployment"
    echo "  7. 🔧 Debug browser console logs"
    echo "  0. 🚪 Exit"
    echo ""
}

list_users() {
    echo -e "${BLUE}📋 Listing all users in User Pool...${NC}"
    echo ""
    
    aws cognito-idp list-users \
        --user-pool-id $USER_POOL_ID \
        --query 'Users[*].{Username:Username,Status:UserStatus,Email:Attributes[?Name==`email`].Value|[0],Confirmed:Attributes[?Name==`email_verified`].Value|[0]}' \
        --output table
    
    echo ""
}

check_user_status() {
    echo -e "${BLUE}🔍 Check User Status${NC}"
    echo ""
    read -p "Enter email address to check: " email
    
    if [ -z "$email" ]; then
        echo -e "${RED}❌ Email address required${NC}"
        return
    fi
    
    echo ""
    echo -e "${BLUE}Checking user: $email${NC}"
    echo ""
    
    # Try to get user info
    if aws cognito-idp admin-get-user \
        --user-pool-id $USER_POOL_ID \
        --username "$email" \
        --query '{Username:Username,Status:UserStatus,Attributes:Attributes}' \
        --output table 2>/dev/null; then
        echo ""
        echo -e "${GREEN}✅ User found${NC}"
    else
        echo -e "${RED}❌ User not found or error occurred${NC}"
        echo "   This could mean:"
        echo "   - User hasn't signed up yet"
        echo "   - Email address is incorrect"
        echo "   - User was deleted"
    fi
    echo ""
}

manually_confirm_user() {
    echo -e "${YELLOW}⚠️  Manual User Confirmation (Emergency)${NC}"
    echo ""
    echo "This will manually confirm a user account without requiring email verification."
    echo "Use this only if the normal verification process is not working."
    echo ""
    read -p "Enter email address to confirm: " email
    
    if [ -z "$email" ]; then
        echo -e "${RED}❌ Email address required${NC}"
        return
    fi
    
    echo ""
    read -p "Are you sure you want to manually confirm $email? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}🔧 Manually confirming user: $email${NC}"
        
        if aws cognito-idp admin-confirm-sign-up \
            --user-pool-id $USER_POOL_ID \
            --username "$email"; then
            echo ""
            echo -e "${GREEN}✅ User manually confirmed successfully!${NC}"
            echo ""
            echo "The user can now sign in with their email and password."
        else
            echo ""
            echo -e "${RED}❌ Failed to confirm user${NC}"
            echo "   Check if the user exists and hasn't been confirmed already."
        fi
    else
        echo "Operation cancelled."
    fi
    echo ""
}

resend_confirmation_code() {
    echo -e "${BLUE}📧 Resend Confirmation Code${NC}"
    echo ""
    read -p "Enter email address: " email
    
    if [ -z "$email" ]; then
        echo -e "${RED}❌ Email address required${NC}"
        return
    fi
    
    echo ""
    echo -e "${BLUE}Resending confirmation code to: $email${NC}"
    
    if aws cognito-idp resend-confirmation-code \
        --client-id $CLIENT_ID \
        --username "$email" \
        --query 'CodeDeliveryDetails' \
        --output table; then
        echo ""
        echo -e "${GREEN}✅ Confirmation code resent successfully!${NC}"
        echo "   Check the email inbox (and spam folder)"
    else
        echo ""
        echo -e "${RED}❌ Failed to resend confirmation code${NC}"
        echo "   Possible reasons:"
        echo "   - User doesn't exist"
        echo "   - User is already confirmed"
        echo "   - Rate limiting in effect"
    fi
    echo ""
}

test_auth_flow() {
    echo -e "${BLUE}🧪 Testing Authentication Flow${NC}"
    echo ""
    echo "This will run the authentication test script..."
    echo ""
    
    if [ -f "./test-auth.sh" ]; then
        ./test-auth.sh
    else
        echo -e "${RED}❌ test-auth.sh not found${NC}"
        echo "   You can create a simple test manually:"
        echo ""
        echo "   1. Go to: https://d8hwipi7b9ziq.cloudfront.net/"
        echo "   2. Open Developer Tools (F12)"
        echo "   3. Try the signup process"
        echo "   4. Check console for error messages"
    fi
    echo ""
}

check_deployment() {
    echo -e "${BLUE}🌐 Checking Production Deployment${NC}"
    echo ""
    
    CLOUDFRONT_URL="https://d8hwipi7b9ziq.cloudfront.net"
    
    echo "Testing deployment files..."
    echo ""
    
    # Test main page
    response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ Main page (HTTP $response)${NC}"
    else
        echo -e "${RED}❌ Main page (HTTP $response)${NC}"
    fi
    
    # Test app-enhanced.js
    response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/app-enhanced.js")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ app-enhanced.js (HTTP $response)${NC}"
    else
        echo -e "${RED}❌ app-enhanced.js (HTTP $response)${NC}"
    fi
    
    # Test config.json
    response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/config.json")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ config.json (HTTP $response)${NC}"
    else
        echo -e "${RED}❌ config.json (HTTP $response)${NC}"
    fi
    
    echo ""
    echo "🔍 To test manually:"
    echo "   1. Open: $CLOUDFRONT_URL"
    echo "   2. Open Developer Tools (F12)"
    echo "   3. Look for these messages in Console:"
    echo "      - '✅ AWS authentication interface ready with confirmSignUp support'"
    echo "      - '✅ Configuration loaded successfully'"
    echo "      - '✅ TodoApp components loaded successfully'"
    echo ""
}

debug_browser_logs() {
    echo -e "${BLUE}🔧 Browser Console Debugging Guide${NC}"
    echo ""
    echo "Follow these steps to debug the email verification:"
    echo ""
    echo "1️⃣  Open the application:"
    echo "   https://d8hwipi7b9ziq.cloudfront.net/"
    echo ""
    echo "2️⃣  Open Developer Tools (F12)"
    echo "   - Go to Console tab"
    echo "   - Clear console (Ctrl+L)"
    echo ""
    echo "3️⃣  Test signup process:"
    echo "   - Click 'Create an account'"
    echo "   - Fill in email and password"
    echo "   - Click 'Create Account'"
    echo "   - Watch console for messages"
    echo ""
    echo "4️⃣  Expected Console Messages:"
    echo "   ✅ '✅ AWS authentication interface ready with confirmSignUp support'"
    echo "   ✅ '✅ Configuration loaded successfully'"
    echo "   ✅ '✅ Sign up successful: [object]'"
    echo ""
    echo "5️⃣  Enter verification code:"
    echo "   - Get code from email"
    echo "   - Enter 6-digit code"
    echo "   - Click 'Verify Email'"
    echo "   - Watch console for confirmation messages"
    echo ""
    echo "6️⃣  Expected Verification Messages:"
    echo "   ✅ '🔄 Confirming signup for: [email] with code: [code]'"
    echo "   ✅ '✅ Email confirmed successfully: [result]'"
    echo ""
    echo "🚨 Common Error Messages to Look For:"
    echo "   ❌ 'InvalidParameterException' - Wrong parameter format"
    echo "   ❌ 'CodeMismatchException' - Wrong verification code"
    echo "   ❌ 'ExpiredCodeException' - Code expired (15 min limit)"
    echo "   ❌ 'UserNotFoundException' - User doesn't exist"
    echo ""
    echo "💡 If you see errors, copy the exact error message for troubleshooting."
    echo ""
}

# Main menu loop
while true; do
    show_menu
    read -p "👉 Select an option (0-7): " choice
    echo ""
    
    case $choice in
        1) list_users ;;
        2) check_user_status ;;
        3) manually_confirm_user ;;
        4) resend_confirmation_code ;;
        5) test_auth_flow ;;
        6) check_deployment ;;
        7) debug_browser_logs ;;
        0) 
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option. Please try again.${NC}"
            echo ""
            ;;
    esac
    
    if [ "$choice" != "0" ]; then
        read -p "Press Enter to continue..."
        echo ""
    fi
done

