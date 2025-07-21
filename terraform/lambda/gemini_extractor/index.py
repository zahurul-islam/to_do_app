import json
import os
import boto3
import logging
import re
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
secrets_client = boto3.client('secretsmanager')

def get_secret(secret_name: str) -> str:
    """Retrieve secret from AWS Secrets Manager or environment variables"""
    try:
        # First try environment variables (for development and simple deployment)
        env_key = secret_name.replace('-', '_').upper()
        if env_key in os.environ:
            return os.environ[env_key]
        
        # Fallback to AWS Secrets Manager
        response = secrets_client.get_secret_value(SecretId=secret_name)
        return response['SecretString']
    except Exception as e:
        logger.error(f"Error retrieving secret {secret_name}: {e}")
        raise e

class AITaskExtractor:
    """Enhanced AI task extractor with multiple AI providers and smart categorization"""
    
    def __init__(self):
        self.categories = {
            'work': {
                'keywords': ['meeting', 'call', 'email', 'project', 'deadline', 'client', 'presentation', 'report', 'conference', 'office'],
                'color': '#667eea',
                'icon': '💼'
            },
            'personal': {
                'keywords': ['home', 'family', 'personal', 'clean', 'organize', 'birthday', 'anniversary', 'friend'],
                'color': '#f093fb',
                'icon': '👤'
            },
            'health': {
                'keywords': ['doctor', 'dentist', 'gym', 'exercise', 'medicine', 'appointment', 'health', 'fitness', 'workout'],
                'color': '#4facfe',
                'icon': '🏃'
            },
            'learning': {
                'keywords': ['learn', 'study', 'read', 'course', 'book', 'tutorial', 'practice', 'skill', 'education'],
                'color': '#43e97b',
                'icon': '📚'
            },
            'shopping': {
                'keywords': ['buy', 'purchase', 'store', 'shop', 'get', 'order', 'groceries', 'online'],
                'color': '#fa709a',
                'icon': '🛒'
            },
            'other': {
                'keywords': [],
                'color': '#a8edea',
                'icon': '📝'
            }
        }
        
        self.priorities = {
            'high': ['urgent', 'asap', 'important', 'critical', 'deadline', 'immediately', 'priority'],
            'medium': ['soon', 'next week', 'this week', 'moderate'],
            'low': ['later', 'sometime', 'maybe', 'consider', 'eventually', 'when possible']
        }
        
        # Date extraction patterns
        self.date_patterns = {
            'today': 0,
            'tomorrow': 1,
            'next week': 7,
            'monday': None,  # Will be calculated
            'tuesday': None,
            'wednesday': None,
            'thursday': None,
            'friday': None,
            'saturday': None,
            'sunday': None
        }

    def extract_with_gemini(self, text: str, api_key: str, mode: str = 'general') -> List[Dict[str, Any]]:
        """Extract tasks using OpenRouter API (Kimi K2 model)"""
        try:
            logger.info(f"Starting OpenRouter API call with text length: {len(text)}")
            url = "https://openrouter.ai/api/v1/chat/completions"
            logger.info(f"OpenRouter API URL: {url}")
            
            # Create a comprehensive prompt based on mode
            if mode == 'email':
                prompt = f"""
                Analyze the following email/message content and extract actionable tasks. For each task, provide:
                - The task title (clear and concise)
                - Category (work, personal, health, learning, shopping, other)
                - Priority (high, medium, low)
                - Due date if mentioned (YYYY-MM-DD format)
                - Any additional context

                Email content:
                {text}

                Please format your response as a JSON array of tasks. Each task should have these fields:
                - title: string
                - category: string
                - priority: string
                - dueDate: string (YYYY-MM-DD format, null if not specified)
                - context: string (optional additional information)

                Only extract clear, actionable tasks. Ignore pleasantries, signatures, and non-actionable content.
                """
            else:
                prompt = f"""
                Analyze the following text and extract actionable tasks/todos. For each task, provide:
                - The task title (clear and concise)
                - Category (work, personal, health, learning, shopping, other)
                - Priority (high, medium, low)
                - Due date if mentioned (YYYY-MM-DD format)

                Text to analyze:
                {text}

                Please format your response as a JSON array of tasks. Each task should have these fields:
                - title: string
                - category: string
                - priority: string
                - dueDate: string (YYYY-MM-DD format, null if not specified)

                Examples of good task extraction:
                - "Call John about the project" -> title: "Call John about the project", category: "work", priority: "medium"
                - "Buy groceries for dinner tonight" -> title: "Buy groceries for dinner", category: "shopping", priority: "high"
                - "Schedule dentist appointment next week" -> title: "Schedule dentist appointment", category: "health", priority: "medium"
                """

            # Format for OpenRouter API
            payload = {
                "model": "moonshotai/kimi-k2:free",
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a helpful assistant that extracts actionable tasks from text. Always respond with valid JSON arrays."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                "temperature": 0.1,
                "max_tokens": 2048
            }

            headers = {
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {api_key}'
            }

            logger.info("Making request to OpenRouter API...")
            response = requests.post(url, json=payload, headers=headers, timeout=10)
            logger.info(f"OpenRouter API response status: {response.status_code}")
            response.raise_for_status()

            result = response.json()
            
            if 'choices' in result and result['choices']:
                generated_text = result['choices'][0]['message']['content']
                
                # Try to extract JSON from the response
                json_match = re.search(r'\[.*\]', generated_text, re.DOTALL)
                if json_match:
                    try:
                        tasks_data = json.loads(json_match.group())
                        return self._process_extracted_tasks(tasks_data)
                    except json.JSONDecodeError:
                        logger.warning("Failed to parse JSON from OpenRouter response, falling back to text parsing")
                        return self._fallback_text_extraction(generated_text)
                else:
                    logger.warning("No JSON found in OpenRouter response, falling back to text parsing")
                    return self._fallback_text_extraction(generated_text)
            else:
                logger.warning("No choices in OpenRouter response")
                return self._fallback_text_extraction(text)

        except Exception as e:
            logger.error(f"OpenRouter API error: {e}")
            # Fallback to local extraction
            return self._fallback_text_extraction(text)

    def extract_with_openai(self, text: str, api_key: str, mode: str = 'general') -> List[Dict[str, Any]]:
        """Extract tasks using OpenAI API as fallback"""
        try:
            url = "https://api.openai.com/v1/chat/completions"
            
            system_prompt = """You are an AI assistant that extracts actionable tasks from text. 
            Return only valid JSON array format with tasks containing: title, category, priority, dueDate fields.
            Categories: work, personal, health, learning, shopping, other
            Priorities: high, medium, low
            Date format: YYYY-MM-DD or null"""
            
            user_prompt = f"""Extract actionable tasks from this text:\n\n{text}"""
            
            payload = {
                "model": "gpt-3.5-turbo",
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                "temperature": 0.1,
                "max_tokens": 1000
            }
            
            headers = {
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json'
            }
            
            response = requests.post(url, json=payload, headers=headers, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            
            if 'choices' in result and result['choices']:
                generated_text = result['choices'][0]['message']['content']
                
                # Try to extract JSON
                json_match = re.search(r'\[.*\]', generated_text, re.DOTALL)
                if json_match:
                    try:
                        tasks_data = json.loads(json_match.group())
                        return self._process_extracted_tasks(tasks_data)
                    except json.JSONDecodeError:
                        return self._fallback_text_extraction(text)
                        
            return self._fallback_text_extraction(text)
            
        except Exception as e:
            logger.error(f"OpenAI API error: {e}")
            return self._fallback_text_extraction(text)

    def _fallback_text_extraction(self, text: str) -> List[Dict[str, Any]]:
        """Fallback method for text extraction when AI APIs fail"""
        tasks = []
        lines = text.split('\n')
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
                
            # Remove common prefixes
            task_text = re.sub(r'^[-•*]\s*', '', line)
            task_text = re.sub(r'^\d+\.\s*', '', task_text)
            task_text = task_text.strip()
            
            if len(task_text) < 3:  # Skip very short tasks
                continue
                
            # Smart categorization
            category = self._categorize_task(task_text)
            priority = self._prioritize_task(task_text)
            due_date = self._extract_due_date(task_text)
            
            task = {
                'id': f'extracted_{int(datetime.now().timestamp() * 1000)}_{len(tasks)}',
                'title': task_text,
                'category': category,
                'priority': priority,
                'dueDate': due_date,
                'completed': False,
                'source': 'AI_Fallback'
            }
            
            tasks.append(task)
            
        return tasks

    def _process_extracted_tasks(self, tasks_data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Process and validate extracted tasks"""
        processed_tasks = []
        
        for i, task_data in enumerate(tasks_data):
            try:
                # Ensure required fields
                title = task_data.get('title', '').strip()
                if not title:
                    continue
                    
                category = task_data.get('category', 'other').lower()
                if category not in self.categories:
                    category = 'other'
                    
                priority = task_data.get('priority', 'medium').lower()
                if priority not in ['high', 'medium', 'low']:
                    priority = 'medium'
                    
                due_date = task_data.get('dueDate')
                if due_date and not self._validate_date_format(due_date):
                    due_date = None
                    
                task = {
                    'id': f'extracted_{int(datetime.now().timestamp() * 1000)}_{i}',
                    'title': title,
                    'category': category,
                    'priority': priority,
                    'dueDate': due_date,
                    'completed': False,
                    'source': 'AI',
                    'createdAt': datetime.now().isoformat()
                }
                
                processed_tasks.append(task)
                
            except Exception as e:
                logger.warning(f"Error processing task {i}: {e}")
                continue
                
        return processed_tasks

    def _categorize_task(self, text: str) -> str:
        """Categorize task based on keywords"""
        text_lower = text.lower()
        
        category_scores = {}
        for category, data in self.categories.items():
            if category == 'other':
                continue
            score = sum(1 for keyword in data['keywords'] if keyword in text_lower)
            if score > 0:
                category_scores[category] = score
                
        if category_scores:
            return max(category_scores, key=category_scores.get)
        return 'other'

    def _prioritize_task(self, text: str) -> str:
        """Determine task priority based on keywords"""
        text_lower = text.lower()
        
        for priority, keywords in self.priorities.items():
            if any(keyword in text_lower for keyword in keywords):
                return priority
                
        return 'medium'

    def _extract_due_date(self, text: str) -> Optional[str]:
        """Extract due date from text"""
        text_lower = text.lower()
        
        # Simple date extraction
        for date_phrase, days_offset in self.date_patterns.items():
            if date_phrase in text_lower:
                if days_offset is not None:
                    target_date = datetime.now() + timedelta(days=days_offset)
                    return target_date.strftime('%Y-%m-%d')
                    
        # Could add more sophisticated date parsing here
        return None

    def _validate_date_format(self, date_str: str) -> bool:
        """Validate date format YYYY-MM-DD"""
        try:
            datetime.strptime(date_str, '%Y-%m-%d')
            return True
        except ValueError:
            return False

def handler(event, context):
    """Enhanced Lambda handler for AI task extraction"""
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        text_to_extract = body.get('text', '').strip()
        extraction_mode = body.get('mode', 'general')  # general, email, notes
        
        if not text_to_extract:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST,OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
                },
                'body': json.dumps({'error': 'Text to extract is required'})
            }
        
        # Initialize extractor
        extractor = AITaskExtractor()
        extracted_tasks = []
        
        try:
            # Try environment variable first
            gemini_api_key = os.environ.get('GEMINI_API_KEY')
            if not gemini_api_key:
                # Fallback to secrets manager
                gemini_api_key = get_secret(os.environ.get('GEMINI_API_KEY_SECRET_NAME', 'gemini-api-key'))
            
            extracted_tasks = extractor.extract_with_gemini(text_to_extract, gemini_api_key, extraction_mode)
            logger.info(f"Successfully extracted {len(extracted_tasks)} tasks using Gemini")
            
        except Exception as gemini_error:
            logger.warning(f"Gemini extraction failed: {gemini_error}")
            
            # Try OpenAI as fallback
            try:
                openai_api_key = os.environ.get('OPENAI_API_KEY')
                if not openai_api_key:
                    # Fallback to secrets manager
                    openai_api_key = get_secret(os.environ.get('OPENAI_API_KEY_SECRET_NAME', 'openai-api-key'))
                
                extracted_tasks = extractor.extract_with_openai(text_to_extract, openai_api_key, extraction_mode)
                logger.info(f"Successfully extracted {len(extracted_tasks)} tasks using OpenAI fallback")
                
            except Exception as openai_error:
                logger.warning(f"OpenAI extraction failed: {openai_error}")
                
                # Use local fallback
                extracted_tasks = extractor._fallback_text_extraction(text_to_extract)
                logger.info(f"Successfully extracted {len(extracted_tasks)} tasks using local fallback")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST,OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
            },
            'body': json.dumps({
                'todos': extracted_tasks,
                'count': len(extracted_tasks),
                'extractionMode': extraction_mode,
                'timestamp': datetime.now().isoformat()
            })
        }
        
    except Exception as e:
        logger.error(f"Error in Lambda handler: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST,OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }
