# Architecture Documentation

## System Architecture Overview

The Serverless Todo Application follows a modern serverless architecture pattern using AWS cloud services. The architecture is designed for scalability, security, and cost-effectiveness while remaining within AWS Free Tier limits.

## Architecture Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   User Browser  │◄──►│  AWS Amplify   │◄──►│  Git Repository │
│                 │    │  (Frontend)     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │
│ Amazon Cognito  │    │   API Gateway   │
│ (Authentication)│    │   (REST API)    │
│                 │    │                 │
└─────────────────┘    └─────────────────┘
         │                        │
         │                        ▼
         │              ┌─────────────────┐
         │              │                 │
         └─────────────►│  AWS Lambda     │
                        │  (Backend Logic)│
                        │                 │
                        └─────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │                 │
                        │   DynamoDB      │
                        │   (Database)    │
                        │                 │
                        └─────────────────┘
```

## Components Detail

### 1. Frontend Layer (AWS Amplify)

**Purpose**: Hosts the React-based web application
**Technology**: React (CDN-hosted), HTML5, CSS3 (Tailwind)
**Features**:
- Single Page Application (SPA)
- Responsive design
- Real-time updates
- Client-side routing

**Key Files**:
- `index.html`: Main HTML entry point
- `app.js`: React application with authentication and todo management
- `amplify.yml`: Build specification for Amplify

### 2. Authentication Layer (Amazon Cognito)

**Purpose**: Manages user authentication and authorization
**Components**:
- **User Pool**: Manages user registration and authentication
- **User Pool Client**: Configures application access to the user pool

**Features**:
- Email-based user registration
- Password policy enforcement
- JWT token generation
- Secure password reset
- Account verification

**Configuration**:
```javascript
Password Policy:
- Minimum length: 8 characters
- Requires: lowercase, uppercase, numbers
- Optional: symbols
```

### 3. API Layer (Amazon API Gateway)

**Purpose**: Provides RESTful API endpoints
**Type**: Regional API Gateway
**Authentication**: Cognito User Pool Authorizer

**Endpoints**:
- `GET /todos` - Retrieve all todos for authenticated user
- `POST /todos` - Create a new todo
- `GET /todos/{id}` - Retrieve specific todo
- `PUT /todos/{id}` - Update specific todo
- `DELETE /todos/{id}` - Delete specific todo
- `OPTIONS /*` - CORS preflight requests

**Features**:
- CORS enabled for web application
- Request/response transformation
- Throttling and rate limiting
- Request validation

### 4. Backend Logic Layer (AWS Lambda)

**Purpose**: Processes business logic and database operations
**Runtime**: Python 3.9
**Handler**: `index.handler`
**Timeout**: 30 seconds
**Memory**: 128 MB (default)

**Functions**:
- `get_todos()`: Retrieves user's todos from DynamoDB
- `create_todo()`: Creates new todo item
- `get_todo()`: Retrieves specific todo
- `update_todo()`: Updates existing todo
- `delete_todo()`: Deletes todo item

**Error Handling**:
- Comprehensive exception handling
- Structured error responses
- CloudWatch logging integration

### 5. Database Layer (Amazon DynamoDB)

**Purpose**: Stores application data
**Type**: NoSQL database
**Billing**: On-demand (pay-per-request)

**Table Schema**:
```
Table Name: todos-table
Partition Key: user_id (String)
Sort Key: id (String)

Attributes:
- user_id: Cognito user identifier
- id: Unique todo identifier (UUID)
- task: Todo description
- status: "pending" | "completed"
- created_at: ISO timestamp
- updated_at: ISO timestamp
- description: Optional detailed description
- due_date: Optional due date
```

**Features**:
- Automatic scaling
- Built-in security
- Point-in-time recovery
- Global secondary indexes (if needed)

## Data Flow

### User Registration Flow
1. User accesses Amplify-hosted frontend
2. User submits registration form
3. Frontend calls Cognito User Pool
4. Cognito sends verification email
5. User verifies email and activates account

### Authentication Flow
1. User submits login credentials
2. Frontend calls Cognito for authentication
3. Cognito returns JWT tokens
4. Frontend stores tokens for API calls

### Todo Operations Flow
1. User performs action (create, read, update, delete)
2. Frontend makes authenticated API call to API Gateway
3. API Gateway validates JWT token with Cognito
4. API Gateway forwards request to Lambda function
5. Lambda function processes request and interacts with DynamoDB
6. Lambda returns response to API Gateway
7. API Gateway returns response to frontend
8. Frontend updates UI with new data

## Security Architecture

### Authentication & Authorization
- **Cognito User Pools**: Manages user identities
- **JWT Tokens**: Secure authentication tokens
- **API Gateway Authorizer**: Validates tokens on each request
- **IAM Roles**: Least privilege access for Lambda functions

### Data Protection
- **Encryption in Transit**: HTTPS for all communications
- **Encryption at Rest**: DynamoDB encryption enabled
- **Access Control**: User-specific data isolation
- **Token Expiration**: Short-lived access tokens

### Network Security
- **CORS**: Properly configured for web application
- **API Rate Limiting**: Prevents abuse
- **Regional Endpoints**: Reduces latency and improves security

## Performance Considerations

### Scalability
- **Lambda Concurrency**: Automatic scaling based on demand
- **DynamoDB**: On-demand scaling for read/write capacity
- **API Gateway**: Built-in throttling and caching options
- **Amplify**: Global CDN for static assets

### Optimization
- **Lambda Cold Start**: Minimized through efficient code
- **DynamoDB Queries**: Efficient partition key usage
- **Frontend Caching**: Browser caching for static assets
- **API Response Size**: Optimized payload sizes

## Cost Architecture

### Free Tier Utilization
- **Lambda**: 1M requests/month
- **API Gateway**: 1M API calls/month
- **DynamoDB**: 25GB storage, 25 RCU/WCU per month
- **Cognito**: 50,000 MAU
- **Amplify**: Integrated with other services

### Cost Optimization Strategies
- **Serverless**: Pay only for actual usage
- **On-demand DynamoDB**: No upfront costs
- **Efficient Lambda**: Optimized memory and timeout
- **Regional Resources**: Reduced data transfer costs

## Monitoring & Observability

### Logging
- **CloudWatch Logs**: Lambda function logs
- **API Gateway Logs**: Request/response logging
- **Amplify Logs**: Build and deployment logs

### Metrics
- **Lambda Metrics**: Duration, errors, invocations
- **DynamoDB Metrics**: Read/write capacity, throttles
- **API Gateway Metrics**: Request count, latency, errors
- **Cognito Metrics**: Authentication events

### Alerting
- **CloudWatch Alarms**: Configurable thresholds
- **SNS Notifications**: Alert delivery
- **Error Rate Monitoring**: Automatic detection

## Disaster Recovery

### Backup Strategy
- **DynamoDB**: Point-in-time recovery enabled
- **Code Repository**: Version control for all code
- **Infrastructure**: Terraform state management

### Regional Considerations
- **Single Region**: Deployed in us-west-2
- **Multi-Region**: Can be extended for global deployment
- **Data Replication**: DynamoDB Global Tables (if needed)

## Development & Deployment

### Infrastructure as Code
- **Terraform**: Declarative infrastructure management
- **Version Control**: All infrastructure code versioned
- **Environment Management**: Support for dev/staging/prod

### CI/CD Pipeline
- **Amplify**: Automatic deployment from Git
- **Terraform**: Infrastructure deployment
- **Testing**: Automated testing capabilities

## Future Enhancements

### Potential Improvements
1. **Real-time Updates**: WebSocket support via API Gateway
2. **Mobile App**: React Native application
3. **Offline Support**: Service workers and local storage
4. **Advanced Features**: Categories, priorities, attachments
5. **Analytics**: User behavior tracking
6. **Multi-tenancy**: Support for teams and organizations

### Scalability Enhancements
1. **Caching**: ElastiCache for frequently accessed data
2. **CDN**: CloudFront for global content delivery
3. **Load Balancing**: Application Load Balancer if needed
4. **Database Optimization**: Secondary indexes and query optimization

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | React, HTML5, CSS3, Tailwind | User interface |
| Authentication | Amazon Cognito | User management |
| API | Amazon API Gateway | RESTful API |
| Backend | AWS Lambda (Python) | Business logic |
| Database | Amazon DynamoDB | Data storage |
| Hosting | AWS Amplify | Frontend hosting |
| Infrastructure | Terraform | IaC deployment |
| Monitoring | CloudWatch | Logging & metrics |

This architecture provides a robust, scalable, and cost-effective solution for a serverless todo application while demonstrating modern cloud development practices.
