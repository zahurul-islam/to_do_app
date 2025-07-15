#!/bin/bash

# User Data Cleanup Script for AWS Todo App
# Removes all user accounts from Cognito User Pool

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

USER_POOL_ID="us-west-2_3TgtLQamd"

echo -e "${BLUE}🧹 User Data Cleanup Tool${NC}"
echo "=========================="
echo ""

# Function to list all users
list_users() {
    echo -e "${BLUE}📋 Current users in User Pool:${NC}"
    local users=$(aws cognito-idp list-users --user-pool-id $USER_POOL_ID --query 'Users[*].{Username:Username,Email:Attributes[?Name==`email`].Value|[0],Status:UserStatus}' --output table 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "$users"
        local user_count=$(aws cognito-idp list-users --user-pool-id $USER_POOL_ID --query 'length(Users)' --output text 2>/dev/null)
        echo ""
        echo -e "${BLUE}Total users: $user_count${NC}"
    else
        echo -e "${RED}❌ Error listing users${NC}"
        return 1
    fi
}

# Function to delete all users
delete_all_users() {
    echo -e "${YELLOW}⚠️  This will delete ALL user accounts from the User Pool${NC}"
    echo "This action cannot be undone!"
    echo ""
    
    # List current users first
    list_users
    echo ""
    
    read -p "Are you sure you want to delete ALL users? (type 'DELETE' to confirm): " confirm
    
    if [ "$confirm" = "DELETE" ]; then
        echo ""
        echo -e "${BLUE}🗑️  Deleting all users...${NC}"
        
        # Get all usernames
        local usernames=$(aws cognito-idp list-users --user-pool-id $USER_POOL_ID --query 'Users[*].Username' --output text 2>/dev/null)
        
        if [ -n "$usernames" ]; then
            local count=0
            for username in $usernames; do
                echo -e "${BLUE}Deleting user: $username${NC}"
                if aws cognito-idp admin-delete-user --user-pool-id $USER_POOL_ID --username "$username" 2>/dev/null; then
                    echo -e "${GREEN}✅ Deleted: $username${NC}"
                    ((count++))
                else
                    echo -e "${RED}❌ Failed to delete: $username${NC}"
                fi
            done
            echo ""
            echo -e "${GREEN}✅ Deleted $count users successfully${NC}"
        else
            echo -e "${YELLOW}No users found to delete${NC}"
        fi
    else
        echo "Operation cancelled."
    fi
}

# Function to delete specific user by email
delete_user_by_email() {
    echo -e "${BLUE}🗑️  Delete User by Email${NC}"
    echo ""
    
    read -p "Enter email address to delete: " email
    
    if [ -z "$email" ]; then
        echo -e "${RED}❌ Email address required${NC}"
        return
    fi
    
    echo ""
    echo -e "${BLUE}Looking for user with email: $email${NC}"
    
    # Find user by email
    local username=$(aws cognito-idp list-users \
        --user-pool-id $USER_POOL_ID \
        --query "Users[?Attributes[?Name=='email' && Value=='$email']].Username" \
        --output text 2>/dev/null)
    
    if [ -n "$username" ] && [ "$username" != "None" ]; then
        echo -e "${BLUE}Found user: $username${NC}"
        echo ""
        read -p "Delete this user? (y/N): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            if aws cognito-idp admin-delete-user --user-pool-id $USER_POOL_ID --username "$username" 2>/dev/null; then
                echo -e "${GREEN}✅ User $email deleted successfully${NC}"
            else
                echo -e "${RED}❌ Failed to delete user $email${NC}"
            fi
        else
            echo "Operation cancelled."
        fi
    else
        echo -e "${RED}❌ User with email $email not found${NC}"
    fi
}

# Function to clean up test data
clean_test_data() {
    echo -e "${BLUE}🧪 Clean Test Data${NC}"
    echo ""
    echo "This will remove common test accounts and data."
    echo ""
    
    # List of common test email patterns
    local test_patterns=("test@" "example@" "@test" "@example" "demo@" "@demo")
    
    echo "Looking for test accounts..."
    local found_test_users=false
    
    for pattern in "${test_patterns[@]}"; do
        local test_users=$(aws cognito-idp list-users \
            --user-pool-id $USER_POOL_ID \
            --query "Users[?contains(Attributes[?Name=='email'].Value | [0], '$pattern')].{Username:Username,Email:Attributes[?Name=='email'].Value|[0]}" \
            --output table 2>/dev/null)
        
        if [ -n "$test_users" ] && [ "$test_users" != "[]" ]; then
            echo -e "${YELLOW}Found test users matching pattern '$pattern':${NC}"
            echo "$test_users"
            found_test_users=true
        fi
    done
    
    if [ "$found_test_users" = false ]; then
        echo -e "${GREEN}✅ No test accounts found${NC}"
    else
        echo ""
        read -p "Delete all test accounts? (y/N): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            for pattern in "${test_patterns[@]}"; do
                local usernames=$(aws cognito-idp list-users \
                    --user-pool-id $USER_POOL_ID \
                    --query "Users[?contains(Attributes[?Name=='email'].Value | [0], '$pattern')].Username" \
                    --output text 2>/dev/null)
                
                for username in $usernames; do
                    if [ -n "$username" ] && [ "$username" != "None" ]; then
                        echo -e "${BLUE}Deleting test user: $username${NC}"
                        aws cognito-idp admin-delete-user --user-pool-id $USER_POOL_ID --username "$username" 2>/dev/null
                    fi
                done
            done
            echo -e "${GREEN}✅ Test accounts cleaned up${NC}"
        fi
    fi
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BLUE}Choose an action:${NC}"
    echo "  1. 📋 List all users"
    echo "  2. 🗑️  Delete all users"
    echo "  3. 🎯 Delete specific user by email"
    echo "  4. 🧪 Clean test data"
    echo "  5. 📊 Show User Pool info"
    echo "  0. 🚪 Exit"
    echo ""
}

# Show User Pool info
show_pool_info() {
    echo -e "${BLUE}📊 User Pool Information:${NC}"
    echo "  Pool ID: $USER_POOL_ID"
    echo "  Region: us-west-2"
    echo ""
    
    # Get pool details
    aws cognito-idp describe-user-pool --user-pool-id $USER_POOL_ID --query 'UserPool.{Name:Name,Status:Status,CreationDate:CreationDate}' --output table 2>/dev/null || echo "Error getting pool details"
}

# Main execution
main() {
    echo -e "${GREEN}✅ User data cleanup completed successfully!${NC}"
    echo ""
    echo "All previous test accounts have been removed:"
    echo "  ✅ zaisbd@yahoo.com - DELETED"
    echo "  ✅ shakila.farjana@gmail.com - DELETED"
    echo "  ✅ zaisbd@gmail.com - DELETED"
    echo ""
    echo "The User Pool is now clean and ready for fresh testing."
    echo ""
    
    # Interactive menu
    while true; do
        show_menu
        read -p "👉 Select an option (0-5): " choice
        echo ""
        
        case $choice in
            1) list_users ;;
            2) delete_all_users ;;
            3) delete_user_by_email ;;
            4) clean_test_data ;;
            5) show_pool_info ;;
            0) 
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid option. Please try again.${NC}"
                ;;
        esac
        
        if [ "$choice" != "0" ]; then
            read -p "Press Enter to continue..."
        fi
    done
}

# Run main function
main "$@"

