import json
import boto3
import uuid
from datetime import datetime
from decimal import Decimal
import os

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE']
table = dynamodb.Table(table_name)

def handler(event, context):
    """
    Main Lambda handler for todo operations
    """
    try:
        # Get request details
        http_method = event['httpMethod']
        resource_path = event['resource']
        path_parameters = event.get('pathParameters', {})
        query_parameters = event.get('queryStringParameters', {})
        body = event.get('body', '')
        
        # Get user ID from Cognito claims
        user_id = get_user_id_from_event(event)
        
        # Parse request body if present
        request_body = {}
        if body:
            request_body = json.loads(body)
        
        # Route to appropriate handler
        if resource_path == '/todos':
            if http_method == 'GET':
                response = get_todos(user_id, query_parameters)
            elif http_method == 'POST':
                response = create_todo(user_id, request_body)
            else:
                response = create_error_response(405, 'Method Not Allowed')
        elif resource_path == '/todos/{id}':
            todo_id = path_parameters.get('id')
            if http_method == 'GET':
                response = get_todo(user_id, todo_id)
            elif http_method == 'PUT':
                response = update_todo(user_id, todo_id, request_body)
            elif http_method == 'DELETE':
                response = delete_todo(user_id, todo_id)
            else:
                response = create_error_response(405, 'Method Not Allowed')
        else:
            response = create_error_response(404, 'Not Found')
        
        return response
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return create_error_response(500, 'Internal Server Error')

def get_user_id_from_event(event):
    """
    Extract user ID from Cognito claims in the event
    """
    try:
        # Get user ID from Cognito authorizer context
        authorizer_context = event.get('requestContext', {}).get('authorizer', {})
        claims = authorizer_context.get('claims', {})
        user_id = claims.get('sub', claims.get('cognito:username', 'anonymous'))
        return user_id
    except Exception as e:
        print(f"Error extracting user ID: {str(e)}")
        return 'anonymous'

def get_todos(user_id, query_parameters):
    """
    Get all todos for a user
    """
    try:
        # Query todos for the user
        response = table.query(
            KeyConditionExpression='user_id = :user_id',
            ExpressionAttributeValues={
                ':user_id': user_id
            }
        )
        
        todos = response.get('Items', [])
        
        # Convert Decimal types to regular numbers for JSON serialization
        todos = convert_decimal_to_number(todos)
        
        return create_success_response({
            'todos': todos,
            'count': len(todos)
        })
    
    except Exception as e:
        print(f"Error getting todos: {str(e)}")
        return create_error_response(500, 'Error retrieving todos')

def create_todo(user_id, request_body):
    """
    Create a new todo
    """
    try:
        # Validate required fields
        if 'task' not in request_body:
            return create_error_response(400, 'Task is required')
        
        # Create new todo item
        todo_id = str(uuid.uuid4())
        todo_item = {
            'user_id': user_id,
            'id': todo_id,
            'task': request_body['task'],
            'status': request_body.get('status', 'pending'),
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat()
        }
        
        # Add optional fields
        if 'description' in request_body:
            todo_item['description'] = request_body['description']
        if 'due_date' in request_body:
            todo_item['due_date'] = request_body['due_date']
        
        # Save to DynamoDB
        table.put_item(Item=todo_item)
        
        # Convert Decimal types for response
        todo_item = convert_decimal_to_number(todo_item)
        
        return create_success_response({
            'todo': todo_item,
            'message': 'Todo created successfully'
        }, 201)
    
    except Exception as e:
        print(f"Error creating todo: {str(e)}")
        return create_error_response(500, 'Error creating todo')

def get_todo(user_id, todo_id):
    """
    Get a specific todo
    """
    try:
        # Get todo from DynamoDB
        response = table.get_item(
            Key={
                'user_id': user_id,
                'id': todo_id
            }
        )
        
        if 'Item' not in response:
            return create_error_response(404, 'Todo not found')
        
        todo = convert_decimal_to_number(response['Item'])
        
        return create_success_response({
            'todo': todo
        })
    
    except Exception as e:
        print(f"Error getting todo: {str(e)}")
        return create_error_response(500, 'Error retrieving todo')

def update_todo(user_id, todo_id, request_body):
    """
    Update an existing todo
    """
    try:
        # Check if todo exists
        response = table.get_item(
            Key={
                'user_id': user_id,
                'id': todo_id
            }
        )
        
        if 'Item' not in response:
            return create_error_response(404, 'Todo not found')
        
        # Prepare update expression
        update_expression = "SET updated_at = :updated_at"
        expression_attribute_values = {
            ':updated_at': datetime.utcnow().isoformat()
        }
        
        # Add fields to update
        if 'task' in request_body:
            update_expression += ", task = :task"
            expression_attribute_values[':task'] = request_body['task']
        
        if 'status' in request_body:
            update_expression += ", #status = :status"
            expression_attribute_values[':status'] = request_body['status']
        
        if 'description' in request_body:
            update_expression += ", description = :description"
            expression_attribute_values[':description'] = request_body['description']
        
        if 'due_date' in request_body:
            update_expression += ", due_date = :due_date"
            expression_attribute_values[':due_date'] = request_body['due_date']
        
        # Update the item
        expression_attribute_names = {}
        if 'status' in request_body:
            expression_attribute_names['#status'] = 'status'
        
        update_params = {
            'Key': {
                'user_id': user_id,
                'id': todo_id
            },
            'UpdateExpression': update_expression,
            'ExpressionAttributeValues': expression_attribute_values,
            'ReturnValues': 'ALL_NEW'
        }
        
        if expression_attribute_names:
            update_params['ExpressionAttributeNames'] = expression_attribute_names
        
        response = table.update_item(**update_params)
        
        updated_todo = convert_decimal_to_number(response['Attributes'])
        
        return create_success_response({
            'todo': updated_todo,
            'message': 'Todo updated successfully'
        })
    
    except Exception as e:
        print(f"Error updating todo: {str(e)}")
        return create_error_response(500, 'Error updating todo')

def delete_todo(user_id, todo_id):
    """
    Delete a todo
    """
    try:
        # Check if todo exists
        response = table.get_item(
            Key={
                'user_id': user_id,
                'id': todo_id
            }
        )
        
        if 'Item' not in response:
            return create_error_response(404, 'Todo not found')
        
        # Delete the item
        table.delete_item(
            Key={
                'user_id': user_id,
                'id': todo_id
            }
        )
        
        return create_success_response({
            'message': 'Todo deleted successfully'
        })
    
    except Exception as e:
        print(f"Error deleting todo: {str(e)}")
        return create_error_response(500, 'Error deleting todo')

def convert_decimal_to_number(obj):
    """
    Convert DynamoDB Decimal types to regular numbers for JSON serialization
    """
    if isinstance(obj, list):
        return [convert_decimal_to_number(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: convert_decimal_to_number(value) for key, value in obj.items()}
    elif isinstance(obj, Decimal):
        return float(obj)
    else:
        return obj

def create_success_response(data, status_code=200):
    """
    Create a successful HTTP response with CORS headers
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(data)
    }

def create_error_response(status_code, message):
    """
    Create an error HTTP response with CORS headers
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps({
            'error': message,
            'statusCode': status_code
        })
    }