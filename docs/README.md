# Serverless Todo Application

A full-stack serverless web application built with AWS services, demonstrating modern cloud architecture using Infrastructure as Code (Terraform) and serverless technologies.

## Architecture Overview

This application uses AWS serverless services to create a scalable, cost-effective todo management system:

- **Frontend**: React application hosted on AWS Amplify
- **Authentication**: Amazon Cognito User Pools
- **API**: Amazon API Gateway with RESTful endpoints
- **Backend Logic**: AWS Lambda functions (Python)
- **Database**: Amazon DynamoDB (NoSQL)
- **Infrastructure**: Terraform for Infrastructure as Code

## Features

- **🔐 Secure Authentication** - Amazon Cognito User Pools with email verification
- **📝 Todo Management** - Create, read, update, and delete todos
- **🔒 User Data Isolation** - Each user only sees their own todos
- **📱 Responsive Design** - Works on desktop and mobile devices
- **⚡ Real-time Updates** - Immediate UI updates for all operations
- **🏗️ Serverless Architecture** - Automatic scaling and high availability
- **💰 Cost-Efficient** - Stays within AWS Free Tier limits

## Authentication & Security

This application implements enterprise-grade authentication using Amazon Cognito User Pools:

### 🔐 **Authentication Features**
- **Email-based Registration** - Users sign up with email addresses
- **Email Verification** - Required email verification before first login
- **Strong Password Policy** - Minimum 8 characters with complexity requirements
- **JWT Token Authentication** - Secure token-based API access
- **Automatic Token Refresh** - Seamless session management
- **Secure Sign Out** - Complete session termination

### 🛡️ **Security Implementation**
- **API Protection** - All endpoints require authentication (401 for unauthorized access)
- **User Data Isolation** - Users can only access their own data
- **CORS Security** - Proper cross-origin resource sharing configuration
- **Advanced Security Mode** - Cognito risk detection and monitoring
- **Encrypted Communication** - HTTPS for all data transmission

### 🧪 **Authentication Testing**
```bash
# Test complete authentication system
./test-auth.sh

# Quick authentication reference
cat docs/auth-quick-reference.md
```

**📚 Detailed Authentication Documentation**: [docs/authentication.md](authentication.md)

## Prerequisites

Before deploying this application, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with your credentials
3. **Terraform** installed (version >= 1.0)
4. **Git** for version control (optional but recommended)

## Project Structure

```
serverless-todo-app/
├── frontend/
│   ├── index.html          # Main HTML file
│   └── app.js              # React application
├── terraform/
│   ├── main.tf             # Main Terraform configuration
│   ├── variables.tf        # Variable definitions
│   ├── outputs.tf          # Output definitions
│   └── lambda/
│       └── index.py        # Lambda function code
├── docs/
│   ├── README.md           # This file
│   ├── architecture.md     # Architecture documentation
│   └── test-plan.md        # Testing procedures
├── amplify.yml             # Amplify build specification
└── plan.md                 # Project plan document
```

## Deployment Instructions

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd serverless-todo-app
```

### Step 2: Configure AWS Credentials

Ensure your AWS CLI is configured with the necessary credentials:

```bash
aws configure
```

### Step 3: Deploy Infrastructure with Terraform

Navigate to the terraform directory and initialize Terraform:

```bash
cd terraform
terraform init
```

Plan the deployment to review what will be created:

```bash
terraform plan
```

Apply the configuration to create the AWS resources:

```bash
terraform apply
```

Review the planned changes and type `yes` to confirm.

### Step 4: Get the Terraform Outputs

After successful deployment, get the output values:

```bash
terraform output
```

### Step 5: Update Frontend Configuration

Update the frontend configuration in `frontend/app.js` with the values from Terraform outputs:

```javascript
const AWS_CONFIG = {
    region: 'us-west-2',
    userPoolId: '<USER_POOL_ID_FROM_TERRAFORM_OUTPUT>',
    userPoolClientId: '<USER_POOL_CLIENT_ID_FROM_TERRAFORM_OUTPUT>',
    apiGatewayUrl: '<API_GATEWAY_URL_FROM_TERRAFORM_OUTPUT>'
};
```

### Step 6: Deploy Frontend to Amplify

If using Amplify with a Git repository:

1. Push your code to a Git repository
2. Update the `amplify_repository_url` variable in `terraform/variables.tf`
3. Run `terraform apply` again to configure Amplify

Alternatively, you can manually deploy by uploading the frontend files to the Amplify console.

## AWS Services Used

### Free Tier Limits

This application is designed to stay within AWS Free Tier limits:

- **AWS Lambda**: 1 million requests/month
- **API Gateway**: 1 million API calls/month
- **DynamoDB**: 25 GB storage, 25 read/write capacity units/month
- **Cognito**: 50,000 monthly active users
- **Amplify**: Included in other service limits

### Resource Configuration

- **DynamoDB**: Configured with on-demand billing
- **Lambda**: Python 3.9 runtime with 30-second timeout
- **API Gateway**: Regional endpoints with CORS enabled
- **Cognito**: Email-based authentication with secure password policy

## Security Features

- **Authentication**: Cognito User Pools with JWT tokens
- **Authorization**: API Gateway with Cognito authorizer
- **CORS**: Properly configured for web application
- **IAM**: Least privilege access for Lambda functions
- **HTTPS**: All communications encrypted in transit

## Monitoring and Logging

- **CloudWatch Logs**: Automatic logging for Lambda functions
- **API Gateway Logging**: Request/response logging available
- **DynamoDB Metrics**: Built-in CloudWatch metrics
- **Amplify Metrics**: Deployment and access metrics

## Cost Optimization

- **Serverless Architecture**: Pay only for what you use
- **DynamoDB On-Demand**: No upfront costs
- **Lambda Provisioned Concurrency**: Not used to save costs
- **API Gateway Caching**: Disabled to stay in Free Tier

## Troubleshooting

### Common Issues

1. **Terraform Apply Fails**
   - Check AWS credentials and permissions
   - Verify region availability for all services
   - Ensure unique resource names

2. **Frontend Not Loading**
   - Verify Amplify deployment status
   - Check browser console for JavaScript errors
   - Confirm API Gateway URL is correct

3. **Authentication Issues**
   - Verify Cognito configuration
   - Check user pool and client settings
   - Confirm API Gateway authorizer setup

4. **API Calls Failing**
   - Check Lambda function logs in CloudWatch
   - Verify DynamoDB table configuration
   - Confirm CORS settings

### Debugging Steps

1. **Check AWS Console**
   - Review each service's configuration
   - Check CloudWatch logs for errors
   - Verify IAM permissions

2. **Test Individual Components**
   - Test Lambda function directly
   - Use API Gateway test console
   - Check DynamoDB table access

3. **Frontend Debugging**
   - Use browser developer tools
   - Check network tab for API calls
   - Verify authentication tokens

## Cleanup

To avoid ongoing costs, destroy the infrastructure when no longer needed:

```bash
cd terraform
terraform destroy
```

Type `yes` to confirm deletion of all resources.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the troubleshooting section
- Review AWS documentation
- Check Terraform provider documentation
- Open an issue in the repository

## Additional Resources

- [AWS Free Tier Documentation](https://aws.amazon.com/free/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS Amplify Documentation](https://docs.amplify.aws/)
- [Amazon Cognito Documentation](https://docs.aws.amazon.com/cognito/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Amazon DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [Amazon API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
