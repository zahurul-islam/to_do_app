#!/bin/bash

# Verification Link Generator
# Creates custom verification links and email templates for users

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLOUDFRONT_URL="https://ddbchpi65u1nc.cloudfront.net"
USER_POOL_ID="us-west-2_wlP1JRTB1"
CLIENT_ID="u3hli4smpmneroq9oatd23p0b"

echo -e "${BLUE}🔗 Email Verification Link Generator${NC}"
echo "===================================="
echo ""

show_menu() {
    echo "Choose an action:"
    echo "  1. 🔗 Generate verification link for user"
    echo "  2. 📧 Create email template with verification link"
    echo "  3. 📋 List all verification options"
    echo "  4. 🧪 Test verification system"
    echo "  5. ⚙️  Show manual CLI commands"
    echo "  0. 🚪 Exit"
    echo ""
}

generate_verification_link() {
    echo -e "${BLUE}🔗 Generate Verification Link${NC}"
    echo ""
    read -p "Enter user's email address: " email
    
    if [ -z "$email" ]; then
        echo -e "${RED}❌ Email address required${NC}"
        return
    fi
    
    local verification_link="$CLOUDFRONT_URL/verify-code.html?email=$email"
    
    echo ""
    echo -e "${GREEN}✅ Verification link generated:${NC}"
    echo ""
    echo "🔗 Direct Link:"
    echo "$verification_link"
    echo ""
    echo "📧 For Email:"
    echo "Click here to verify your email: $verification_link"
    echo ""
    echo "📱 For SMS/Message:"
    echo "Verify email: $verification_link"
    echo ""
}

create_email_template() {
    echo -e "${BLUE}📧 Create Email Template${NC}"
    echo ""
    read -p "Enter user's email address: " email
    read -p "Enter user's name (optional): " name
    
    if [ -z "$email" ]; then
        echo -e "${RED}❌ Email address required${NC}"
        return
    fi
    
    if [ -z "$name" ]; then
        name="User"
    fi
    
    local verification_link="$CLOUDFRONT_URL/verify-code.html?email=$email"
    
    echo ""
    echo -e "${GREEN}✅ Email template created:${NC}"
    echo ""
    echo "=========================="
    echo "Subject: Verify Your TaskFlow Account"
    echo ""
    echo "Hi $name,"
    echo ""
    echo "Welcome to TaskFlow! To complete your account setup, please verify your email address."
    echo ""
    echo "📧 Your verification code has been sent to: $email"
    echo ""
    echo "🔗 Click here to verify your account:"
    echo "$verification_link"
    echo ""
    echo "Or copy and paste this link into your browser:"
    echo "$verification_link"
    echo ""
    echo "If you didn't create this account, you can safely ignore this email."
    echo ""
    echo "Best regards,"
    echo "The TaskFlow Team"
    echo "=========================="
    echo ""
}

list_verification_options() {
    echo -e "${BLUE}📋 All Verification Options${NC}"
    echo ""
    echo "🌐 MAIN URLS:"
    echo "  Application:     $CLOUDFRONT_URL"
    echo "  Verification:    $CLOUDFRONT_URL/verify-code.html"
    echo "  Admin Center:    $CLOUDFRONT_URL/verify.html"
    echo ""
    echo "🔗 VERIFICATION LINK PATTERNS:"
    echo "  Generic:         $CLOUDFRONT_URL/verify-code.html"
    echo "  With Email:      $CLOUDFRONT_URL/verify-code.html?email=USER@EXAMPLE.COM"
    echo ""
    echo "📧 EXAMPLE VERIFICATION LINKS:"
    echo "  Gmail User:      $CLOUDFRONT_URL/verify-code.html?email=user@gmail.com"
    echo "  Yahoo User:      $CLOUDFRONT_URL/verify-code.html?email=user@yahoo.com"
    echo "  Company User:    $CLOUDFRONT_URL/verify-code.html?email=user@company.com"
    echo ""
    echo "🛠️ FEATURES:"
    echo "  ✅ Auto-populate email field"
    echo "  ✅ 6-digit code verification"
    echo "  ✅ Resend code functionality"
    echo "  ✅ Error handling and validation"
    echo "  ✅ Success redirect to main app"
    echo ""
}

test_verification_system() {
    echo -e "${BLUE}🧪 Test Verification System${NC}"
    echo ""
    echo "Testing verification pages accessibility..."
    echo ""
    
    # Test main verification page
    echo "🌐 Testing main verification page..."
    response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/verify-code.html")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ Verification page accessible (HTTP $response)${NC}"
    else
        echo -e "${RED}❌ Verification page failed (HTTP $response)${NC}"
    fi
    
    # Test verification center
    echo "🏠 Testing verification center..."
    response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/verify.html")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ Verification center accessible (HTTP $response)${NC}"
    else
        echo -e "${RED}❌ Verification center failed (HTTP $response)${NC}"
    fi
    
    # Test main app
    echo "📱 Testing main application..."
    response=$(curl -s -w "%{http_code}" -o /dev/null "$CLOUDFRONT_URL/")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ Main application accessible (HTTP $response)${NC}"
    else
        echo -e "${RED}❌ Main application failed (HTTP $response)${NC}"
    fi
    
    echo ""
    echo "🧪 MANUAL TESTING STEPS:"
    echo "  1. Go to: $CLOUDFRONT_URL"
    echo "  2. Create new account with test email"
    echo "  3. Use verification link: $CLOUDFRONT_URL/verify-code.html?email=TEST_EMAIL"
    echo "  4. Enter verification code received via email"
    echo "  5. Verify successful redirect to main app"
    echo ""
}

show_cli_commands() {
    echo -e "${BLUE}⚙️  Manual CLI Commands${NC}"
    echo ""
    echo "🔧 MANUAL USER CONFIRMATION:"
    echo "  aws cognito-idp admin-confirm-sign-up \\"
    echo "    --user-pool-id $USER_POOL_ID \\"
    echo "    --username USER@EXAMPLE.COM"
    echo ""
    echo "📧 RESEND VERIFICATION CODE:"
    echo "  aws cognito-idp resend-confirmation-code \\"
    echo "    --client-id $CLIENT_ID \\"
    echo "    --username USER@EXAMPLE.COM"
    echo ""
    echo "👤 CHECK USER STATUS:"
    echo "  aws cognito-idp admin-get-user \\"
    echo "    --user-pool-id $USER_POOL_ID \\"
    echo "    --username USER@EXAMPLE.COM"
    echo ""
    echo "📋 LIST ALL USERS:"
    echo "  aws cognito-idp list-users \\"
    echo "    --user-pool-id $USER_POOL_ID"
    echo ""
    echo "🗑️ DELETE USER (if needed):"
    echo "  aws cognito-idp admin-delete-user \\"
    echo "    --user-pool-id $USER_POOL_ID \\"
    echo "    --username USER@EXAMPLE.COM"
    echo ""
}

# Main menu loop
while true; do
    show_menu
    read -p "👉 Select an option (0-5): " choice
    echo ""
    
    case $choice in
        1) generate_verification_link ;;
        2) create_email_template ;;
        3) list_verification_options ;;
        4) test_verification_system ;;
        5) show_cli_commands ;;
        0) 
            echo -e "${GREEN}👋 Goodbye!${NC}"
            echo ""
            echo "📋 QUICK REFERENCE:"
            echo "  Verification Page: $CLOUDFRONT_URL/verify-code.html"
            echo "  With Email Param:  $CLOUDFRONT_URL/verify-code.html?email=USER@EXAMPLE.COM"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option. Please try again.${NC}"
            ;;
    esac
    
    if [ "$choice" != "0" ]; then
        echo ""
        read -p "Press Enter to continue..."
        echo ""
    fi
done

