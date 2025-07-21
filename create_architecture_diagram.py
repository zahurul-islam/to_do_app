#!/usr/bin/env python3
"""
Create AWS Architecture Diagram for TaskFlow Application
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import Lambda
from diagrams.aws.database import Dynamodb
from diagrams.aws.network import CloudFront, APIGateway
from diagrams.aws.storage import S3
from diagrams.aws.security import Cognito, SecretsManager
from diagrams.aws.management import Cloudwatch
from diagrams.aws.general import Users
from diagrams.onprem.client import Client
from diagrams.programming.language import Python

# Diagram configuration
graph_attr = {
    "fontsize": "45",
    "bgcolor": "white",
    "pad": "0.5",
    "ranksep": "1.5",
    "nodesep": "1.0"
}

node_attr = {
    "fontsize": "14",
    "fontname": "Arial",
    "shape": "box",
    "style": "rounded,filled",
    "fillcolor": "lightblue"
}

with Diagram("TaskFlow - Serverless Todo Application Architecture", 
             filename="taskflow_architecture",
             show=False,
             direction="TB",
             graph_attr=graph_attr,
             node_attr=node_attr):
    
    # Users
    users = Users("End Users")
    
    # Frontend Layer
    with Cluster("Frontend Layer"):
        cloudfront = CloudFront("CloudFront\nDistribution")
        s3_bucket = S3("S3 Bucket\n(Static Website)")
        
    # API Layer
    with Cluster("API Gateway"):
        api_gateway = APIGateway("REST API\n/todos")
        api_ai = APIGateway("AI Endpoint\n/ai/extract")
    
    # Authentication
    with Cluster("Authentication"):
        cognito_pool = Cognito("User Pool")
        cognito_identity = Cognito("Identity Pool")
    
    # Compute Layer
    with Cluster("Lambda Functions"):
        todo_lambda = Lambda("Todo Handler\n(CRUD Operations)")
        ai_lambda = Lambda("AI Extractor\n(Gemini/OpenAI)")
        xray_lambda = Lambda("X-Ray Enabled\nHandler")
    
    # Data Layer
    with Cluster("Data Storage"):
        dynamodb = Dynamodb("Todos Table")
        secrets = SecretsManager("API Keys\n(Gemini/OpenAI)")
    
    # Monitoring
    with Cluster("Monitoring & Logging"):
        cloudwatch_logs = Cloudwatch("CloudWatch\nLogs")
        cloudwatch_metrics = Cloudwatch("CloudWatch\nMetrics")
        cloudwatch_alarms = Cloudwatch("CloudWatch\nAlarms")
    
    # Connections
    users >> Edge(label="HTTPS", style="bold") >> cloudfront
    cloudfront >> Edge(label="Static Content") >> s3_bucket
    
    users >> Edge(label="API Calls", style="dashed") >> api_gateway
    users >> Edge(label="AI Requests", style="dashed") >> api_ai
    
    # Authentication flow
    users >> Edge(label="Auth", color="darkgreen") >> cognito_pool
    cognito_pool >> Edge(color="darkgreen") >> cognito_identity
    
    # API Gateway to Lambda
    api_gateway >> Edge(label="Invoke") >> todo_lambda
    api_ai >> Edge(label="Invoke") >> ai_lambda
    
    # Lambda to DynamoDB
    todo_lambda >> Edge(label="Read/Write") >> dynamodb
    xray_lambda >> Edge(label="Read/Write") >> dynamodb
    
    # AI Lambda to Secrets
    ai_lambda >> Edge(label="Get API Keys") >> secrets
    
    # Monitoring connections
    todo_lambda >> Edge(style="dotted", color="gray") >> cloudwatch_logs
    ai_lambda >> Edge(style="dotted", color="gray") >> cloudwatch_logs
    api_gateway >> Edge(style="dotted", color="gray") >> cloudwatch_metrics
    dynamodb >> Edge(style="dotted", color="gray") >> cloudwatch_alarms

print("Architecture diagram created successfully!")
print("Output file: taskflow_architecture.png")