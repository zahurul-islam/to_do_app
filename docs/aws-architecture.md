# AWS Serverless Todo Application - Architectural Design

## 🏗️ System Architecture Overview

This document provides a comprehensive architectural design for the Serverless Todo Application deployed on AWS, showcasing modern serverless patterns and best practices.

## 📐 High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS CLOUD                                        │
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐             │
│  │                 │    │                 │    │                 │             │
│  │   PRESENTATION  │    │   APPLICATION   │    │      DATA       │             │
│  │      LAYER      │    │      LAYER      │    │     LAYER       │             │
│  │                 │    │                 │    │                 │             │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘             │
│           │                       │                       │                    │
│           ▼                       ▼                       ▼                    │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐             │
│  │  AWS Amplify    │    │  API Gateway    │    │   DynamoDB      │             │
│  │  (Frontend)     │    │  + Lambda       │    │  (Database)     │             │
│  │                 │    │  (Backend)      │    │                 │             │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘             │
│           │                       │                       │                    │
│           └───────────┬───────────┘                       │                    │
│                       │                                   │                    │
│  ┌─────────────────┐  │  ┌─────────────────┐             │                    │
│  │  Amazon Cognito │  │  │   CloudWatch    │             │                    │
│  │ (Authentication)│  │  │  (Monitoring)   │             │                    │
│  └─────────────────┘  │  └─────────────────┘             │                    │
│           │            │           │                      │                    │
│           └────────────┼───────────┴──────────────────────┘                    │
│                        │                                                       │
│  ┌─────────────────┐   │  ┌─────────────────┐                                 │
│  │      IAM        │   │  │   CloudFormation│                                 │
│  │  (Security)     │   │  │   (Infrastructure)                               │
│  └─────────────────┘   │  └─────────────────┘                                 │
│           │             │           │                                          │
│           └─────────────┴───────────┘                                          │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🏛️ Detailed Component Architecture

### 1. Presentation Layer - AWS Amplify

```
┌─────────────────────────────────────────────────────────────────┐
│                      AWS AMPLIFY HOSTING                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   React     │  │    HTML     │  │     CSS     │             │
│  │Application  │  │   Files     │  │  (Tailwind) │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│         │                │                │                    │
│         └────────────────┼────────────────┘                    │
│                          │                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              CloudFront CDN                             │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │   US-East   │ │   US-West   │ │   EU-West   │ ... │   │
│  │  │     Edge    │ │     Edge    │ │     Edge    │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                          │                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               S3 Bucket (Static Files)                 │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │ index.html  │ │   app.js    │ │   assets/   │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Features:**
- **Global CDN Distribution** via CloudFront
- **Automatic HTTPS** with SSL certificates
- **Git Integration** for CI/CD deployment
- **Branch-based Deployments** for different environments
- **Custom Domain Support** (optional)

### 2. Authentication Layer - Amazon Cognito

```
┌─────────────────────────────────────────────────────────────────┐
│                    AMAZON COGNITO ECOSYSTEM                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 COGNITO USER POOL                       │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │    Users    │ │   Groups    │ │  Policies   │      │   │
│  │  │ Management  │ │ Management  │ │ Management  │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  │                         │                             │   │
│  │  ┌─────────────────────────────────────────────────┐  │   │
│  │  │            PASSWORD POLICY                      │  │   │
│  │  │  • Min 8 characters                            │  │   │
│  │  │  • Uppercase + Lowercase required              │  │   │
│  │  │  • Numbers required                            │  │   │
│  │  │  • Advanced security mode                      │  │   │
│  │  └─────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              COGNITO USER POOL CLIENT                   │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │   Token     │ │ Auth Flows  │ │  Security   │      │   │
│  │  │ Management  │ │  Config     │ │   Config    │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              COGNITO IDENTITY POOL                      │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │ Federated   │ │    Role     │ │   Access    │      │   │
│  │  │ Identities  │ │  Mapping    │ │ Management  │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Token Flow:**
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   ACCESS    │    │   ID TOKEN  │    │   REFRESH   │
│   TOKEN     │    │   (Claims)  │    │    TOKEN    │
│  (1 hour)   │    │  (1 hour)   │    │  (30 days)  │
└─────────────┘    └─────────────┘    └─────────────┘
       │                  │                  │
       ▼                  ▼                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ API Gateway │    │  Frontend   │    │  Token      │
│Authorization│    │User Context │    │  Refresh    │
└─────────────┘    └─────────────┘    └─────────────┘
```

### 3. Application Layer - API Gateway + Lambda

```
┌─────────────────────────────────────────────────────────────────┐
│                    API GATEWAY + LAMBDA                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 API GATEWAY                             │   │
│  │                                                         │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │               COGNITO AUTHORIZER                │   │   │
│  │  │  ┌─────────────┐ ┌─────────────┐ ┌───────────┐ │   │   │
│  │  │  │JWT Token    │ │  Claims     │ │  Cache    │ │   │   │
│  │  │  │Validation   │ │ Extraction  │ │ (5 min)   │ │   │   │
│  │  │  └─────────────┘ └─────────────┘ └───────────┘ │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                         │                             │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │                API RESOURCES                    │   │   │
│  │  │                                                 │   │   │
│  │  │  /todos                    /todos/{id}          │   │   │
│  │  │  ├─ GET    (List todos)   ├─ GET    (Get todo)  │   │   │
│  │  │  ├─ POST   (Create todo)  ├─ PUT    (Update)    │   │   │
│  │  │  ├─ OPTIONS (CORS)        ├─ DELETE (Delete)    │   │   │
│  │  │  └─ 🔒 AUTH REQUIRED      ├─ OPTIONS (CORS)     │   │   │
│  │  │                          └─ 🔒 AUTH REQUIRED    │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                         │                             │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │                CORS CONFIGURATION               │   │   │
│  │  │  • Access-Control-Allow-Origin: *               │   │   │
│  │  │  • Access-Control-Allow-Methods: GET,POST,PUT... │   │   │
│  │  │  • Access-Control-Allow-Headers: Authorization  │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                         │                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  AWS LAMBDA                            │   │
│  │                                                         │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │              LAMBDA FUNCTION                    │   │   │
│  │  │                                                 │   │   │
│  │  │  Runtime: Python 3.9                           │   │   │
│  │  │  Memory: 128 MB                                 │   │   │
│  │  │  Timeout: 30 seconds                            │   │   │
│  │  │  Handler: index.handler                         │   │   │
│  │  │                                                 │   │   │
│  │  │  ┌─────────────────────────────────────────┐   │   │   │
│  │  │  │         BUSINESS LOGIC                  │   │   │   │
│  │  │  │  • User authentication validation      │   │   │   │
│  │  │  │  • Request routing (GET/POST/PUT/DELETE)│   │   │   │
│  │  │  │  • Data validation and sanitization    │   │   │   │
│  │  │  │  • DynamoDB operations                 │   │   │   │
│  │  │  │  • Error handling and logging          │   │   │   │
│  │  │  │  • Response formatting                 │   │   │   │
│  │  │  └─────────────────────────────────────────┘   │   │   │
│  │  │                                                 │   │   │
│  │  │  ┌─────────────────────────────────────────┐   │   │   │
│  │  │  │        ENVIRONMENT VARIABLES            │   │   │   │
│  │  │  │  • DYNAMODB_TABLE                      │   │   │   │
│  │  │  │  • COGNITO_USER_POOL_ID                │   │   │   │
│  │  │  │  • LOG_LEVEL                           │   │   │   │
│  │  │  └─────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4. Data Layer - Amazon DynamoDB

```
┌─────────────────────────────────────────────────────────────────┐
│                      AMAZON DYNAMODB                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   TODOS TABLE                           │   │
│  │                                                         │   │
│  │  Table Name: todos-table                                │   │
│  │  Billing Mode: On-Demand (Pay per request)             │   │
│  │                                                         │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │                TABLE SCHEMA                     │   │   │
│  │  │                                                 │   │   │
│  │  │  Partition Key: user_id (String)                │   │   │
│  │  │  Sort Key: id (String)                          │   │   │
│  │  │                                                 │   │   │
│  │  │  Attributes:                                    │   │   │
│  │  │  ├─ user_id (S)     - Cognito user identifier  │   │   │
│  │  │  ├─ id (S)          - Todo unique identifier   │   │   │
│  │  │  ├─ task (S)        - Todo description         │   │   │
│  │  │  ├─ status (S)      - "pending" | "completed"  │   │   │
│  │  │  ├─ created_at (S)  - ISO timestamp            │   │   │
│  │  │  ├─ updated_at (S)  - ISO timestamp            │   │   │
│  │  │  ├─ description (S) - Optional detailed desc   │   │   │
│  │  │  └─ due_date (S)    - Optional due date        │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │               ACCESS PATTERNS                   │   │   │
│  │  │                                                 │   │   │
│  │  │  Primary Access:                                │   │   │
│  │  │  ├─ Get all todos for user:                     │   │   │
│  │  │  │  Query(user_id = "abc123")                   │   │   │
│  │  │  │                                             │   │   │
│  │  │  ├─ Get specific todo:                          │   │   │
│  │  │  │  GetItem(user_id = "abc123", id = "todo1")   │   │   │
│  │  │  │                                             │   │   │
│  │  │  ├─ Create todo:                                │   │   │
│  │  │  │  PutItem({user_id, id, task, ...})          │   │   │
│  │  │  │                                             │   │   │
│  │  │  ├─ Update todo:                                │   │   │
│  │  │  │  UpdateItem(user_id, id, updates)           │   │   │
│  │  │  │                                             │   │   │
│  │  │  └─ Delete todo:                                │   │   │
│  │  │     DeleteItem(user_id, id)                    │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │             SECURITY & ISOLATION                │   │   │
│  │  │                                                 │   │   │
│  │  │  ✅ User Data Isolation:                        │   │   │
│  │  │     Each user can only access their own todos   │   │   │
│  │  │     via user_id partition key                   │   │   │
│  │  │                                                 │   │   │
│  │  │  ✅ Encryption:                                 │   │   │
│  │  │     Data encrypted at rest and in transit      │   │   │
│  │  │                                                 │   │   │
│  │  │  ✅ Backup:                                     │   │   │
│  │  │     Point-in-time recovery enabled             │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Sample Data Structure:**
```json
{
  "user_id": "us-west-2:abc123-def456-ghi789",
  "id": "todo_2024-01-15_001",
  "task": "Complete serverless project documentation",
  "status": "pending",
  "created_at": "2024-01-15T10:30:00.000Z",
  "updated_at": "2024-01-15T10:30:00.000Z",
  "description": "Write comprehensive documentation for the todo app",
  "due_date": "2024-01-20T00:00:00.000Z"
}
```

## 🔐 Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      SECURITY LAYERS                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                NETWORK SECURITY                         │   │
│  │                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │   HTTPS     │ │    CORS     │ │   CDN WAF   │      │   │
│  │  │ Everywhere  │ │ Protection  │ │ (Optional)  │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              AUTHENTICATION SECURITY                    │   │
│  │                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │  Cognito    │ │JWT Tokens   │ │ Multi-Factor│      │   │
│  │  │ User Pools  │ │ (Short TTL) │ │Auth Ready   │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               APPLICATION SECURITY                      │   │
│  │                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │ API Gateway │ │   Lambda    │ │   Input     │      │   │
│  │  │ Authorizer  │ │ Validation  │ │ Validation  │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                DATA SECURITY                            │   │
│  │                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │ DynamoDB    │ │    Data     │ │   Backup    │      │   │
│  │  │ Encryption  │ │ Isolation   │ │& Recovery   │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 IAM SECURITY                            │   │
│  │                                                         │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │   Least     │ │ Service     │ │   Policy    │      │   │
│  │  │ Privilege   │ │   Roles     │ │ Validation  │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Architecture

### Request Flow Diagram

```
┌─────────────┐
│   Browser   │
│   (User)    │
└─────────────┘
       │
       │ 1. HTTPS Request
       │
       ▼
┌─────────────┐
│ CloudFront  │
│    (CDN)    │
└─────────────┘
       │
       │ 2. Static Content
       │
       ▼
┌─────────────┐
│   Amplify   │
│  (Frontend) │
└─────────────┘
       │
       │ 3. API Request + JWT Token
       │
       ▼
┌─────────────┐
│    CORS     │
│  Preflight  │
└─────────────┘
       │
       │ 4. Authorized Request
       │
       ▼
┌─────────────┐
│ API Gateway │
│ Authorizer  │
└─────────────┘
       │
       │ 5. JWT Validation
       │
       ▼
┌─────────────┐
│   Cognito   │
│ User Pools  │
└─────────────┘
       │
       │ 6. Token Valid + User Claims
       │
       ▼
┌─────────────┐
│ API Gateway │
│   Routing   │
└─────────────┘
       │
       │ 7. Lambda Invocation
       │
       ▼
┌─────────────┐
│   Lambda    │
│  Function   │
└─────────────┘
       │
       │ 8. Database Query
       │
       ▼
┌─────────────┐
│  DynamoDB   │
│   Table     │
└─────────────┘
       │
       │ 9. Response Data
       │
       ▼
┌─────────────┐
│   Lambda    │
│  Response   │
└─────────────┘
       │
       │ 10. JSON Response
       │
       ▼
┌─────────────┐
│ API Gateway │
│  Response   │
└─────────────┘
       │
       │ 11. HTTP Response
       │
       ▼
┌─────────────┐
│   Browser   │
│    (User)   │
└─────────────┘
```

### Authentication Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    User     │    │  Frontend   │    │   Cognito   │    │     API     │
│             │    │             │    │ User Pool   │    │   Gateway   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                  │                  │                  │
       │ 1. Sign Up       │                  │                  │
       ├─────────────────►│                  │                  │
       │                  │ 2. Registration  │                  │
       │                  ├─────────────────►│                  │
       │                  │                  │ 3. Send Email    │
       │◄─────────────────┤                  │ Verification     │
       │ 4. Check Email   │                  │                  │
       │                  │                  │                  │
       │ 5. Enter Code    │                  │                  │
       ├─────────────────►│ 6. Confirm       │                  │
       │                  ├─────────────────►│                  │
       │                  │ 7. Confirmed     │                  │
       │◄─────────────────┤◄─────────────────┤                  │
       │                  │                  │                  │
       │ 8. Sign In       │                  │                  │
       ├─────────────────►│ 9. Authenticate  │                  │
       │                  ├─────────────────►│                  │
       │                  │ 10. JWT Tokens   │                  │
       │                  │◄─────────────────┤                  │
       │ 11. Redirect to  │                  │                  │
       │ Dashboard        │                  │                  │
       │◄─────────────────┤                  │                  │
       │                  │                  │                  │
       │ 12. API Request  │                  │                  │
       │ with JWT Token   │                  │                  │
       ├─────────────────►│ 13. Forward      │                  │
       │                  │ with Auth Header │                  │
       │                  ├─────────────────────────────────────►│
       │                  │                  │ 14. Validate JWT │
       │                  │                  │◄─────────────────┤
       │                  │                  │ 15. Token Valid  │
       │                  │                  ├─────────────────►│
       │                  │ 16. API Response │                  │
       │                  │◄─────────────────────────────────────┤
       │ 17. Data         │                  │                  │
       │◄─────────────────┤                  │                  │
```

## 🏗️ Infrastructure Architecture

### AWS Services Integration

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS SERVICES INTEGRATION                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐         ┌─────────────────┐               │
│  │   AWS Amplify   │◄────────┤  GitHub/Git     │               │
│  │                 │         │   Repository    │               │
│  │  ┌─────────────┐│         └─────────────────┘               │
│  │  │ Build & CI  ││                                           │
│  │  └─────────────┘│                                           │
│  │  ┌─────────────┐│         ┌─────────────────┐               │
│  │  │CloudFront   ││◄────────┤      S3         │               │
│  │  │Distribution ││         │   Bucket        │               │
│  │  └─────────────┘│         └─────────────────┘               │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐         ┌─────────────────┐               │
│  │  API Gateway    │◄────────┤   CloudWatch    │               │
│  │                 │         │    Logs         │               │
│  │  ┌─────────────┐│         └─────────────────┘               │
│  │  │ Cognito     ││                                           │
│  │  │ Authorizer  ││         ┌─────────────────┐               │
│  │  └─────────────┘│◄────────┤   Cognito       │               │
│  │  ┌─────────────┐│         │  User Pool      │               │
│  │  │ Lambda      ││         └─────────────────┘               │
│  │  │ Integration ││                                           │
│  │  └─────────────┘│                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐         ┌─────────────────┐               │
│  │  AWS Lambda     │◄────────┤   CloudWatch    │               │
│  │                 │         │    Metrics      │               │
│  │  ┌─────────────┐│         └─────────────────┘               │
│  │  │   Python    ││                                           │
│  │  │  Runtime    ││         ┌─────────────────┐               │
│  │  └─────────────┘│◄────────┤      IAM        │               │
│  │  ┌─────────────┐│         │     Roles       │               │
│  │  │Environment  ││         └─────────────────┘               │
│  │  │Variables    ││                                           │
│  │  └─────────────┘│                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐         ┌─────────────────┐               │
│  │   DynamoDB      │◄────────┤   CloudWatch    │               │
│  │                 │         │    Alarms       │               │
│  │  ┌─────────────┐│         └─────────────────┘               │
│  │  │   Todos     ││                                           │
│  │  │   Table     ││         ┌─────────────────┐               │
│  │  └─────────────┘│◄────────┤   Backup &      │               │
│  │  ┌─────────────┐│         │   Recovery      │               │
│  │  │   Global    ││         └─────────────────┘               │
│  │  │ Secondary   ││                                           │
│  │  │  Indexes    ││                                           │
│  │  └─────────────┘│                                           │
│  └─────────────────┘                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Region and Availability Zones

```
┌─────────────────────────────────────────────────────────────────┐
│                       AWS REGION: US-WEST-2                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │       AZ-A      │ │       AZ-B      │ │       AZ-C      │   │
│  │   us-west-2a    │ │   us-west-2b    │ │   us-west-2c    │   │
│  │                 │ │                 │ │                 │   │
│  │ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │   │
│  │ │ DynamoDB    │ │ │ │ DynamoDB    │ │ │ │ DynamoDB    │ │   │
│  │ │ Replica     │ │ │ │ Replica     │ │ │ │ Replica     │ │   │
│  │ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │   │
│  │                 │ │                 │ │                 │   │
│  │ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │   │
│  │ │ Lambda      │ │ │ │ Lambda      │ │ │ │ Lambda      │ │   │
│  │ │ Function    │ │ │ │ Function    │ │ │ │ Function    │ │   │
│  │ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │   │
│  │                 │ │                 │ │                 │   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                REGIONAL SERVICES                        │   │
│  │                                                         │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │   │
│  │ │ API Gateway │ │   Cognito   │ │ CloudWatch  │        │   │
│  │ │   (Region)  │ │   (Global)  │ │   (Region)  │        │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 GLOBAL SERVICES                         │   │
│  │                                                         │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │   │
│  │ │ CloudFront  │ │     IAM     │ │   Route 53  │        │   │
│  │ │ (Global CDN)│ │  (Global)   │ │  (Global)   │        │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📊 Performance Architecture

### Scalability Patterns

```
┌─────────────────────────────────────────────────────────────────┐
│                      SCALABILITY DESIGN                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  FRONTEND SCALING                       │   │
│  │                                                         │   │
│  │  CloudFront Edge Locations: 450+ globally              │   │
│  │  ├─ Automatic caching of static assets                  │   │
│  │  ├─ Gzip compression                                    │   │
│  │  ├─ HTTP/2 support                                      │   │
│  │  └─ Geographic distribution                             │   │
│  │                                                         │   │
│  │  S3 Bucket: 99.999999999% (11 9's) durability         │   │
│  │  ├─ Unlimited storage                                   │   │
│  │  ├─ Automatic versioning                                │   │
│  │  └─ Cross-region replication (if needed)               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 API LAYER SCALING                       │   │
│  │                                                         │   │
│  │  API Gateway: 10,000 requests/second default           │   │
│  │  ├─ Automatic scaling                                   │   │
│  │  ├─ Rate limiting and throttling                        │   │
│  │  ├─ Caching (5 minutes default)                         │   │
│  │  └─ Request/response validation                         │   │
│  │                                                         │   │
│  │  Lambda Concurrency: 1,000 concurrent executions       │   │
│  │  ├─ Automatic scaling based on requests                 │   │
│  │  ├─ Cold start optimization                             │   │
│  │  ├─ Memory scaling (128MB - 3GB)                        │   │
│  │  └─ Provisioned concurrency (if needed)                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 DATABASE SCALING                        │   │
│  │                                                         │   │
│  │  DynamoDB On-Demand: Automatic scaling                 │   │
│  │  ├─ Read: Up to 40,000 RCU/second                       │   │
│  │  ├─ Write: Up to 40,000 WCU/second                      │   │
│  │  ├─ Storage: Unlimited                                  │   │
│  │  └─ Global Secondary Indexes (if needed)               │   │
│  │                                                         │   │
│  │  Partition Strategy:                                    │   │
│  │  ├─ user_id as partition key (even distribution)       │   │
│  │  ├─ id as sort key (efficient queries)                 │   │
│  │  └─ Hot partition detection and mitigation              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Performance Optimization

```
┌─────────────────────────────────────────────────────────────────┐
│                   PERFORMANCE OPTIMIZATIONS                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 FRONTEND OPTIMIZATION                   │   │
│  │                                                         │   │
│  │  ✅ CDN Caching (CloudFront)                           │   │
│  │  ✅ Asset Minification                                  │   │
│  │  ✅ Gzip Compression                                    │   │
│  │  ✅ Browser Caching Headers                             │   │
│  │  ✅ Lazy Loading of Components                          │   │
│  │  ✅ Code Splitting (if needed)                          │   │
│  │  ✅ Image Optimization                                  │   │
│  │  ✅ Service Worker (offline capability)                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  API OPTIMIZATION                       │   │
│  │                                                         │   │
│  │  ✅ Response Caching (API Gateway)                      │   │
│  │  ✅ Request/Response Compression                        │   │
│  │  ✅ Connection Pooling                                  │   │
│  │  ✅ Efficient JSON Serialization                       │   │
│  │  ✅ Batch Operations (where applicable)                │   │
│  │  ✅ Pagination for Large Data Sets                     │   │
│  │  ✅ Field Selection in Queries                         │   │
│  │  ✅ ETags for Conditional Requests                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                LAMBDA OPTIMIZATION                      │   │
│  │                                                         │   │
│  │  ✅ Memory Right-Sizing (128MB optimal)                │   │
│  │  ✅ Cold Start Minimization                             │   │
│  │  ✅ Connection Reuse                                    │   │
│  │  ✅ Efficient Import Statements                         │   │
│  │  ✅ Environment Variable Caching                       │   │
│  │  ✅ Async/Await Optimization                            │   │
│  │  ✅ Error Handling and Retry Logic                     │   │
│  │  ✅ Structured Logging                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               DATABASE OPTIMIZATION                     │   │
│  │                                                         │   │
│  │  ✅ Efficient Key Design                                │   │
│  │  ✅ Query vs Scan Operations                            │   │
│  │  ✅ Projected Attributes                                │   │
│  │  ✅ Conditional Writes                                  │   │
│  │  ✅ Batch Operations                                    │   │
│  │  ✅ Connection Pooling                                  │   │
│  │  ✅ Read/Write Capacity Monitoring                     │   │
│  │  ✅ Hot Key Detection                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 💰 Cost Architecture

### AWS Free Tier Utilization

```
┌─────────────────────────────────────────────────────────────────┐
│                       AWS FREE TIER LIMITS                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   COMPUTE COSTS                         │   │
│  │                                                         │   │
│  │  AWS Lambda:                                            │   │
│  │  ├─ ✅ 1M requests/month (FREE)                         │   │
│  │  ├─ ✅ 400,000 GB-seconds compute/month (FREE)          │   │
│  │  ├─ Current usage: ~10K requests/month                  │   │
│  │  └─ Cost: $0.00/month                                   │   │
│  │                                                         │   │
│  │  API Gateway:                                           │   │
│  │  ├─ ✅ 1M API calls/month (FREE)                        │   │
│  │  ├─ Current usage: ~10K calls/month                     │   │
│  │  └─ Cost: $0.00/month                                   │   │
��  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   STORAGE COSTS                         │   │
│  │                                                         │   │
│  │  DynamoDB:                                              │   │
│  │  ├─ ✅ 25 GB storage/month (FREE)                       │   │
│  │  ├─ ✅ 25 WCU + 25 RCU/month (FREE)                     │   │
│  │  ├─ Current usage: ~1 GB storage                        │   │
│  │  └─ Cost: $0.00/month                                   │   │
│  │                                                         │   │
│  │  S3 (Amplify):                                          │   │
│  │  ├─ ✅ 5 GB storage/month (FREE)                        │   │
│  │  ├─ ✅ 20,000 GET requests/month (FREE)                 │   │
│  │  ├─ Current usage: ~10 MB                               │   │
│  │  └─ Cost: $0.00/month                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 AUTHENTICATION COSTS                    │   │
│  │                                                         │   │
│  │  Cognito User Pools:                                    │   │
│  │  ├─ ✅ 50,000 MAU (Monthly Active Users) (FREE)         │   │
│  │  ├─ Current usage: ~10 users                            │   │
│  │  └─ Cost: $0.00/month                                   │   │
│  │                                                         │   │
│  │  Cognito Identity Pools:                                │   │
│  │  ├─ ✅ 50,000 sync operations/month (FREE)              │   │
│  │  ├─ Current usage: ~100 operations                      │   │
│  │  └─ Cost: $0.00/month                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   HOSTING COSTS                         │   │
│  │                                                         │   │
│  │  AWS Amplify:                                           │   │
│  │  ├─ ✅ Build minutes included in other services         │   │
│  │  ├─ ✅ Hosting via S3 + CloudFront (FREE tier)         │   │
│  │  ├─ Current usage: ~10 builds/month                     │   │
│  │  └─ Cost: $0.00/month                                   │   │
│  │                                                         │   │
│  │  CloudFront CDN:                                        │   │
│  │  ├─ ✅ 50 GB data transfer/month (FREE)                 │   │
│  │  ├─ ✅ 2M requests/month (FREE)                         │   │
│  │  ├─ Current usage: ~1 GB transfer                       │   │
│  │  └─ Cost: $0.00/month                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   TOTAL MONTHLY COST                    │   │
│  │                                                         │   │
│  │  ✅ Current Total: $0.00/month                          │   │
│  │  📊 Projected with 1000 users: $0.00/month             │   │
│  │  🎯 Free Tier Expiration: 12 months                    │   │
│  │  💡 Post-Free Tier Estimate: ~$5-15/month              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Deployment Architecture

### Infrastructure as Code (Terraform)

```
┌─────────────────────────────────────────────────────────────────┐
│                     TERRAFORM ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 TERRAFORM MODULES                       │   │
│  │                                                         │   │
│  │  📁 terraform/                                          │   │
│  │  ├─ 📄 main.tf                 (Core infrastructure)    │   │
│  │  ├─ 📄 variables.tf            (Input variables)        │   │
│  │  ├─ 📄 outputs.tf              (Output values)          │   │
│  │  ├─ 📄 cognito-enhanced.tf     (Auth configuration)     │   │
│  │  ├─ 📁 lambda/                 (Function code)          │   │
│  │  │  └─ 📄 index.py                                      │   │
│  │  ├─ 📄 terraform.tfvars        (Variable values)        │   │
│  │  └─ 📄 .terraform.lock.hcl     (Provider versions)      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                RESOURCE DEPENDENCIES                    │   │
│  │                                                         │   │
│  │  IAM Roles & Policies                                   │   │
│  │           │                                             │   │
│  │           ▼                                             │   │
│  │  Cognito User Pool ──────┐                              │   │
│  │           │              │                              │   │
│  │           ▼              ▼                              │   │
│  │  User Pool Client   API Gateway                         │   │
│  │           │              │                              │   │
│  │           │              ▼                              │   │
│  │           │         Lambda Function                     │   │
│  │           │              │                              │   │
│  │           │              ▼                              │   │
│  │           │         DynamoDB Table                      │   │
│  │           │              │                              │   │
│  │           ▼              ▼                              │   │
│  │       Amplify App ◄──────┘                              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              TERRAFORM WORKFLOW                         │   │
│  │                                                         │   │
│  │  1. 🔧 terraform init                                   │   │
│  │     ├─ Download AWS provider                            │   │
│  │     ├─ Initialize backend                               │   │
│  │     └─ Create .terraform directory                      │   │
│  │                                                         │   │
│  │  2. 📋 terraform plan                                   │   │
│  │     ├─ Read current state                               │   │
│  │     ├─ Compare with desired state                       │   │
│  │     └─ Generate execution plan                          │   │
│  │                                                         │   │
│  │  3. 🚀 terraform apply                                  │   │
│  │     ├─ Create AWS resources                             │   │
│  │     ├─ Update state file                                │   │
│  │     └─ Output resource information                      │   │
│  │                                                         │   │
│  │  4. 📊 terraform output                                 │   │
│  │     └─ Display resource URLs and IDs                    │   │
│  │                                                         │   │
│  │  5. 🧹 terraform destroy                                │   │
│  │     └─ Clean up all resources                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

This comprehensive architectural design provides a complete view of the AWS Serverless Todo Application, demonstrating enterprise-level architecture patterns, security best practices, and cost-effective resource utilization within the AWS Free Tier.

The architecture showcases:
- ✅ **Modern Serverless Patterns** - Event-driven, scalable architecture
- ✅ **Security-First Design** - Multi-layered security implementation
- ✅ **High Availability** - Cross-AZ redundancy and automatic failover
- ✅ **Cost Optimization** - Efficient resource usage within free tiers
- ✅ **Performance Optimization** - CDN, caching, and efficient data access
- ✅ **Infrastructure as Code** - Reproducible and version-controlled deployment
- ✅ **Monitoring & Observability** - Comprehensive logging and metrics
- ✅ **Scalability** - Automatic scaling across all tiers

This architecture is production-ready and suitable for real-world applications requiring secure, scalable, and cost-effective serverless solutions.
