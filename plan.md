Context Engineering Prompt: Serverless Web App Capstone Project
Project Overview
The goal is to build a serverless web application (e.g., a to-do list or simple blog) that demonstrates modern cloud architecture using AWS Free Tier services. The application will include user authentication, a database for storing data, and serverless backend logic, all deployed using infrastructure as code with Terraform (using the AWS provider v6.2.0). The project must be innovative, scalable, cost-free within the AWS Free Tier, and suitable for a capstone project showcasing cloud computing skills.
Objective
Develop a full-stack serverless web application with the following features:

A frontend interface for users to interact with the application (e.g., create, view, update, and delete to-do items or blog posts).
User authentication to secure access to the application.
A serverless backend to handle CRUD (Create, Read, Update, Delete) operations.
A NoSQL database to store application data.
Infrastructure defined and deployed using Terraform (AWS provider v6.2.0) to ensure reproducibility and scalability.
Deployment within the AWS Free Tier to avoid costs.

AWS Services
Use the following AWS Free Tier services:

AWS Amplify: Host the frontend and manage backend integration, leveraging other AWS services.
Amazon Cognito: Provide user authentication and authorization (50,000 monthly active users and 15,000 monthly email messages for free in the Free Tier).
Amazon DynamoDB: Store application data (25 GB storage, 25 read/write capacity units/month for free in the Free Tier).
Amazon API Gateway: Create RESTful APIs for backend communication (1 million free API calls/month in the Free Tier).
AWS Lambda: Handle backend logic (1 million free requests and 400,000 GB-seconds of compute time/month in the Free Tier).

Innovation
The project showcases:

Serverless Architecture: Eliminates server management, enabling scalability and cost efficiency.
Full-Stack Development: Integrates frontend, backend, and database in a cohesive application.
Infrastructure as Code: Uses Terraform to define and deploy AWS resources, demonstrating modern DevOps practices.
Real-World Application: Addresses common use cases like task management or content creation, relevant for portfolios or real-world scenarios.

Requirements

Frontend:

Build a simple web interface using React (preferred for its component-based structure) to allow users to perform CRUD operations (e.g., add, view, edit, delete to-do items or blog posts).
Use AWS Amplify to host the frontend and connect to backend services.
Ensure the interface is responsive and user-friendly.


Authentication:

Implement user sign-up, sign-in, and sign-out using Amazon Cognito User Pools.
Secure API endpoints to allow only authenticated users to perform actions.


Backend:

Create RESTful APIs using Amazon API Gateway to handle CRUD operations.
Use AWS Lambda to implement backend logic (e.g., processing requests to create or retrieve data).
Store data in Amazon DynamoDB, designed as a NoSQL table (e.g., for to-do items: id, user_id, task, status, created_at).


Infrastructure as Code:

Use Terraform (AWS provider v6.2.0, as specified in hashicorp/terraform-provider-aws) to define and deploy all AWS resources (Amplify, Cognito, DynamoDB, API Gateway, Lambda).
Organize Terraform code in modular files (e.g., main.tf, variables.tf, outputs.tf) for clarity and reusability.
Ensure Terraform code includes necessary configurations for IAM roles, permissions, and resource dependencies.


Free Tier Compliance:

Keep usage within AWS Free Tier limits:
Lambda: 1 million requests/month.
API Gateway: 1 million API calls/month.
DynamoDB: 25 GB storage, 25 read/write capacity units/month.
Cognito: 50,000 monthly active users.
Amplify: Usage within limits of integrated services.


Monitor usage with AWS Cost Explorer to avoid charges.


Deliverables:

Frontend React code for the web application.
Terraform scripts to deploy all AWS resources (AWS provider v6.2.0).
Documentation explaining the architecture, setup instructions, and how to deploy the application.
A simple test plan to verify functionality (e.g., user can sign up, create a to-do item, and retrieve it).



Constraints

Cost: Must remain within AWS Free Tier limits to avoid charges. Avoid services outside the Free Tier (e.g., SageMaker, Personalize).
Scope: Keep the project small-scale (e.g., support a few users, limited API calls) to stay within Free Tier limits and capstone project scope.
React and JSX:
Use CDN-hosted React (e.g., via cdn.jsdelivr.net) for compatibility.
Prefer JSX over React.createElement.
Use Tailwind CSS for styling (via CDN).
Avoid <form> onSubmit due to sandbox restrictions; use button click handlers instead.
Use className instead of class for JSX attributes.


Terraform:
Use AWS provider v6.2.0 (hashicorp/terraform-provider-aws).
Ensure all resources are defined in Terraform, including IAM roles and policies.
Test Terraform scripts to confirm they deploy without errors.



Success Criteria

The application allows users to sign up, sign in, and perform CRUD operations on data (e.g., to-do items or blog posts).
All AWS resources are deployed successfully using Terraform without manual configuration.
The application remains fully functional within AWS Free Tier limits.
The code is well-documented, modular, and reusable, with clear setup instructions.
The project demonstrates innovation through serverless architecture, authentication, and infrastructure as code.

Suggested Architecture

Frontend: React app hosted on AWS Amplify, communicating with API Gateway.
Authentication: Cognito User Pool for user management, integrated with API Gateway for secure endpoints.
Backend: API Gateway routes requests to Lambda functions, which interact with DynamoDB for data storage.
Database: DynamoDB table with a partition key (e.g., user_id) and sort key (e.g., id) for efficient queries.
Infrastructure: Terraform scripts defining Amplify, Cognito, API Gateway, Lambda, and DynamoDB, with IAM roles for secure access.

Example Workflow

User signs up/in via Cognito through the React frontend.
User submits a to-do item via the frontend, which sends a request to API Gateway.
API Gateway triggers a Lambda function to validate the request and store the item in DynamoDB.
User retrieves their to-do items, with Lambda querying DynamoDB and returning data via API Gateway.
Terraform scripts deploy all resources, and Amplify hosts the frontend.

Deliverable Structure

Frontend Code: React application in a folder (e.g., frontend/), including index.html, App.js, and Tailwind CSS.
Terraform Code: Modular Terraform files (e.g., main.tf, variables.tf, outputs.tf) defining all AWS resources.
Documentation: Markdown file with architecture diagram, setup instructions, and test plan.
Test Plan: Steps to verify functionality (e.g., sign-up, create item, retrieve item).

Notes

Use the AWS Free Tier documentation (https://aws.amazon.com/free/) to verify service limits.
Refer to Terraform AWS provider v6.2.0 documentation (https://registry.terraform.io/providers/hashicorp/aws/6.2.0) for resource configurations.
Test the application locally before deploying to ensure functionality.
Monitor AWS usage to avoid exceeding Free Tier limits.

