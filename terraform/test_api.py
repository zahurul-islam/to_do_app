#!/usr/bin/env python3
"""
Test script for the Todo API
This script demonstrates how to:
1. Create a user in Cognito
2. Authenticate and get tokens
3. Test the API endpoints
"""

import boto3
import requests
import json
import sys
from botocore.exceptions import ClientError

# Configuration - Update these values from your Terraform outputs
API_BASE_URL = "https://gaxp7bppj0.execute-api.us-west-2.amazonaws.com/prod"
USER_POOL_ID = "us-west-2_PJ2VDWBG0"
CLIENT_ID = "17951lnrtafd2dia35qcftvfl0"
AWS_REGION = "us-west-2"

class TodoAPITester:
    def __init__(self):
        self.cognito_client = boto3.client('cognito-idp', region_name=AWS_REGION)
        self.access_token = None
        self.username = None
        
    def create_user(self, username, password, email):
        """Create a new user in Cognito User Pool"""
        try:
            print(f"Creating user: {username}")
            
            # Create user
            response = self.cognito_client.admin_create_user(
                UserPoolId=USER_POOL_ID,
                Username=username,
                UserAttributes=[
                    {'Name': 'email', 'Value': email},
                    {'Name': 'email_verified', 'Value': 'true'}
                ],
                TemporaryPassword=password,
                MessageAction='SUPPRESS'  # Don't send welcome email
            )
            
            print(f"User created successfully: {response['User']['Username']}")
            
            # Set permanent password
            self.cognito_client.admin_set_user_password(
                UserPoolId=USER_POOL_ID,
                Username=username,
                Password=password,
                Permanent=True
            )
            
            print("Permanent password set successfully")
            return True
            
        except ClientError as e:
            if e.response['Error']['Code'] == 'UsernameExistsException':
                print(f"User {username} already exists")
                return True
            else:
                print(f"Error creating user: {e}")
                return False
    
    def authenticate_user(self, username, password):
        """Authenticate user and get access token"""
        try:
            print(f"Authenticating user: {username}")
            
            response = self.cognito_client.admin_initiate_auth(
                UserPoolId=USER_POOL_ID,
                ClientId=CLIENT_ID,
                AuthFlow='ADMIN_NO_SRP_AUTH',
                AuthParameters={
                    'USERNAME': username,
                    'PASSWORD': password
                }
            )
            
            if 'AuthenticationResult' in response:
                self.access_token = response['AuthenticationResult']['IdToken']  # Use ID token for API Gateway
                self.username = username
                print("Authentication successful!")
                return True
            else:
                print("Authentication failed - no tokens returned")
                return False
                
        except ClientError as e:
            print(f"Authentication error: {e}")
            return False
    
    def get_headers(self):
        """Get headers with authentication token"""
        if not self.access_token:
            raise Exception("No access token available. Please authenticate first.")
        
        return {
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        }
    
    def test_create_todo(self):
        """Test creating a new todo"""
        print("\n=== Testing Create Todo ===")
        
        todo_data = {
            "task": "Learn AWS Lambda",
            "description": "Complete the serverless todo app tutorial",
            "status": "pending"
        }
        
        try:
            response = requests.post(
                f"{API_BASE_URL}/todos",
                headers=self.get_headers(),
                json=todo_data
            )
            
            print(f"Status Code: {response.status_code}")
            print(f"Response: {response.json()}")
            
            if response.status_code == 201:
                return response.json()['todo']['id']
            return None
            
        except Exception as e:
            print(f"Error creating todo: {e}")
            return None
    
    def test_get_todos(self):
        """Test getting all todos"""
        print("\n=== Testing Get All Todos ===")
        
        try:
            response = requests.get(
                f"{API_BASE_URL}/todos",
                headers=self.get_headers()
            )
            
            print(f"Status Code: {response.status_code}")
            print(f"Response: {response.json()}")
            
        except Exception as e:
            print(f"Error getting todos: {e}")
    
    def test_get_todo(self, todo_id):
        """Test getting a specific todo"""
        print(f"\n=== Testing Get Todo {todo_id} ===")
        
        try:
            response = requests.get(
                f"{API_BASE_URL}/todos/{todo_id}",
                headers=self.get_headers()
            )
            
            print(f"Status Code: {response.status_code}")
            print(f"Response: {response.json()}")
            
        except Exception as e:
            print(f"Error getting todo: {e}")
    
    def test_update_todo(self, todo_id):
        """Test updating a todo"""
        print(f"\n=== Testing Update Todo {todo_id} ===")
        
        update_data = {
            "status": "completed",
            "description": "Tutorial completed successfully!"
        }
        
        try:
            response = requests.put(
                f"{API_BASE_URL}/todos/{todo_id}",
                headers=self.get_headers(),
                json=update_data
            )
            
            print(f"Status Code: {response.status_code}")
            print(f"Response: {response.json()}")
            
        except Exception as e:
            print(f"Error updating todo: {e}")
    
    def test_delete_todo(self, todo_id):
        """Test deleting a todo"""
        print(f"\n=== Testing Delete Todo {todo_id} ===")
        
        try:
            response = requests.delete(
                f"{API_BASE_URL}/todos/{todo_id}",
                headers=self.get_headers()
            )
            
            print(f"Status Code: {response.status_code}")
            print(f"Response: {response.json()}")
            
        except Exception as e:
            print(f"Error deleting todo: {e}")

def main():
    """Main test function"""
    print("Todo API Tester")
    print("=" * 50)
    
    # Test configuration
    username = "test@example.com"  # Use email as username
    password = "TempPassword123!"
    email = "test@example.com"
    
    tester = TodoAPITester()
    
    # Step 1: Create user
    if not tester.create_user(username, password, email):
        print("Failed to create user")
        sys.exit(1)
    
    # Step 2: Authenticate
    if not tester.authenticate_user(username, password):
        print("Failed to authenticate user")
        sys.exit(1)
    
    # Step 3: Test API endpoints
    print("\n" + "=" * 50)
    print("Testing API Endpoints")
    print("=" * 50)
    
    # Test create todo
    todo_id = tester.test_create_todo()
    
    # Test get all todos
    tester.test_get_todos()
    
    if todo_id:
        # Test get specific todo
        tester.test_get_todo(todo_id)
        
        # Test update todo
        tester.test_update_todo(todo_id)
        
        # Test get todo after update
        tester.test_get_todo(todo_id)
        
        # Test delete todo
        tester.test_delete_todo(todo_id)
        
        # Test get all todos after deletion
        tester.test_get_todos()
    
    print("\n" + "=" * 50)
    print("Testing completed!")
    print("=" * 50)

if __name__ == "__main__":
    main()