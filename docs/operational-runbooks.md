# Operational Runbooks for Serverless Todo Application

## 🚨 Incident Response Playbooks

### 1. High Error Rate Alert

#### **Symptoms**
- CloudWatch alarm: `todo-lambda-error-rate-dev` triggered
- Users reporting 500 errors
- API Gateway showing increased 5XX responses

#### **Investigation Steps**

1. **Check Lambda Function Logs**
   ```bash
   # View recent errors
   aws logs filter-log-events \
     --log-group-name "/aws/lambda/todo-handler" \
     --start-time $(date -d '1 hour ago' +%s)000 \
     --filter-pattern "ERROR"
   ```

2. **Check API Gateway Logs**
   ```bash
   # Check API Gateway execution logs
   aws logs describe-log-groups \
     --log-group-name-prefix "API-Gateway-Execution-Logs"
   ```

3. **Check DynamoDB Metrics**
   ```bash
   # Check for throttling
   aws cloudwatch get-metric-statistics \
     --namespace AWS/DynamoDB \
     --metric-name ThrottledRequests \
     --dimensions Name=TableName,Value=todos-table \
     --start-time $(date -d '1 hour ago' --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 300 \
     --statistics Sum
   ```

#### **Resolution Steps**

1. **If Lambda Memory Issues**
   ```bash
   # Increase Lambda memory
   aws lambda update-function-configuration \
     --function-name todo-handler \
     --memory-size 256
   ```

2. **If DynamoDB Throttling**
   ```bash
   # Check current capacity
   aws dynamodb describe-table --table-name todos-table
   
   # If needed, temporarily increase capacity (for provisioned mode)
   aws dynamodb update-table \
     --table-name todos-table \
     --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10
   ```

3. **If External Service Issues**
   ```bash
   # Check Cognito service status
   aws cognito-idp describe-user-pool --user-pool-id YOUR_POOL_ID
   ```

#### **Post-Incident**
- Document root cause
- Update monitoring thresholds if needed
- Review and update this runbook

---

### 2. High Latency Alert

#### **Symptoms**
- CloudWatch alarm: `todo-lambda-duration-dev` triggered
- Users reporting slow response times
- API Gateway latency metrics elevated

#### **Investigation Steps**

1. **Analyze Lambda Performance**
   ```bash
   # Get duration statistics
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Lambda \
     --metric-name Duration \
     --dimensions Name=FunctionName,Value=todo-handler \
     --start-time $(date -d '1 hour ago' --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 300 \
     --statistics Average,Maximum
   ```

2. **Check DynamoDB Latency**
   ```bash
   # Check DynamoDB response times
   aws cloudwatch get-metric-statistics \
     --namespace AWS/DynamoDB \
     --metric-name SuccessfulRequestLatency \
     --dimensions Name=TableName,Value=todos-table Name=Operation,Value=Query \
     --start-time $(date -d '1 hour ago' --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 300 \
     --statistics Average
   ```

3. **Review X-Ray Traces** (if enabled)
   ```bash
   # Get trace summaries
   aws xray get-trace-summaries \
     --time-range-type TimeRangeByStartTime \
     --start-time $(date -d '1 hour ago' --iso-8601) \
     --end-time $(date --iso-8601)
   ```

#### **Resolution Steps**

1. **Optimize Lambda Performance**
   - Increase memory allocation
   - Review code for inefficiencies
   - Enable provisioned concurrency if needed

2. **Optimize DynamoDB Access**
   - Review query patterns
   - Consider adding Global Secondary Indexes
   - Optimize item size

3. **Enable Caching**
   ```bash
   # Enable API Gateway caching
   aws apigateway put-stage \
     --rest-api-id YOUR_API_ID \
     --stage-name prod \
     --patch-ops op=replace,path=/caching/enabled,value=true
   ```

---

### 3. Authentication Issues

#### **Symptoms**
- Users unable to sign in
- 401 Unauthorized errors
- Cognito-related errors in logs

#### **Investigation Steps**

1. **Check Cognito User Pool Status**
   ```bash
   # Verify user pool configuration
   aws cognito-idp describe-user-pool --user-pool-id YOUR_POOL_ID
   
   # Check user pool client settings
   aws cognito-idp describe-user-pool-client \
     --user-pool-id YOUR_POOL_ID \
     --client-id YOUR_CLIENT_ID
   ```

2. **Check API Gateway Authorizer**
   ```bash
   # Verify authorizer configuration
   aws apigateway get-authorizers --rest-api-id YOUR_API_ID
   ```

3. **Test Authentication Flow**
   ```bash
   # Test user sign-in
   aws cognito-idp admin-initiate-auth \
     --user-pool-id YOUR_POOL_ID \
     --client-id YOUR_CLIENT_ID \
     --auth-flow ADMIN_NO_SRP_AUTH \
     --auth-parameters USERNAME=test@example.com,PASSWORD=TestPassword123!
   ```

#### **Resolution Steps**

1. **Reset User Password** (if user-specific)
   ```bash
   aws cognito-idp admin-set-user-password \
     --user-pool-id YOUR_POOL_ID \
     --username test@example.com \
     --password NewPassword123! \
     --permanent
   ```

2. **Verify JWT Token Configuration**
   - Check token expiration settings
   - Verify API Gateway authorizer configuration
   - Ensure CORS is properly configured

---

## 🔧 Operational Procedures

### Daily Operations Checklist

#### **Morning Health Check** (5 minutes)

1. **Check Dashboard**
   ```bash
   # View CloudWatch dashboard
   echo "Check: https://console.aws.amazon.com/cloudwatch/home#dashboards:name=TodoApp-dev"
   ```

2. **Verify Core Metrics**
   ```bash
   # Lambda invocations last 24h
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Lambda \
     --metric-name Invocations \
     --dimensions Name=FunctionName,Value=todo-handler \
     --start-time $(date -d '24 hours ago' --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 86400 \
     --statistics Sum
   
   # API Gateway requests last 24h
   aws cloudwatch get-metric-statistics \
     --namespace AWS/ApiGateway \
     --metric-name Count \
     --dimensions Name=ApiName,Value=todo-api \
     --start-time $(date -d '24 hours ago' --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 86400 \
     --statistics Sum
   ```

3. **Check Error Rates**
   ```bash
   # Lambda errors last 24h
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Lambda \
     --metric-name Errors \
     --dimensions Name=FunctionName,Value=todo-handler \
     --start-time $(date -d '24 hours ago' --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 86400 \
     --statistics Sum
   ```

#### **Weekly Operations** (30 minutes)

1. **Review Cost and Usage**
   ```bash
   # Get cost and usage report
   aws ce get-cost-and-usage \
     --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
     --granularity DAILY \
     --metrics BlendedCost \
     --group-by Type=DIMENSION,Key=SERVICE
   ```

2. **Security Review**
   ```bash
   # Check CloudTrail for unusual activity
   aws cloudtrail lookup-events \
     --start-time $(date -d '7 days ago' --iso-8601) \
     --lookup-attributes AttributeKey=EventName,AttributeValue=CreateUser
   ```

3. **Performance Review**
   ```bash
   # Review slow queries
   aws logs start-query \
     --log-group-name "/aws/lambda/todo-handler" \
     --start-time $(date -d '7 days ago' +%s) \
     --end-time $(date +%s) \
     --query-string 'fields @timestamp, @duration | filter @duration > 5000 | sort @duration desc'
   ```

### Backup and Recovery Procedures

#### **Manual Backup Creation**

1. **Create DynamoDB Backup**
   ```bash
   # Create on-demand backup
   aws dynamodb create-backup \
     --table-name todos-table \
     --backup-name "todos-table-manual-$(date +%Y%m%d-%H%M%S)"
   ```

2. **Export User Pool Configuration**
   ```bash
   # Backup Cognito User Pool settings
   aws cognito-idp describe-user-pool \
     --user-pool-id YOUR_POOL_ID > cognito-backup-$(date +%Y%m%d).json
   ```

#### **Recovery Procedures**

1. **Restore DynamoDB Table**
   ```bash
   # List available backups
   aws dynamodb list-backups --table-name todos-table
   
   # Restore from backup
   aws dynamodb restore-table-from-backup \
     --target-table-name todos-table-restored \
     --backup-arn arn:aws:dynamodb:region:account:table/todos-table/backup/BACKUP_ID
   ```

2. **Disaster Recovery - Full Stack**
   ```bash
   # Redeploy infrastructure
   cd terraform
   terraform init
   terraform plan -var-file="recovery.tfvars"
   terraform apply -var-file="recovery.tfvars"
   ```

### Scaling Procedures

#### **Handle Traffic Spikes**

1. **Monitor Real-time Metrics**
   ```bash
   # Watch Lambda concurrency
   watch -n 5 'aws cloudwatch get-metric-statistics \
     --namespace AWS/Lambda \
     --metric-name ConcurrentExecutions \
     --dimensions Name=FunctionName,Value=todo-handler \
     --start-time $(date -d "5 minutes ago" --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 60 \
     --statistics Maximum'
   ```

2. **Temporary Scaling Actions**
   ```bash
   # Increase Lambda provisioned concurrency
   aws lambda put-provisioned-concurrency-config \
     --function-name todo-handler \
     --qualifier $LATEST \
     --provisioned-concurrency-executions 10
   
   # Enable API Gateway caching
   aws apigateway put-stage \
     --rest-api-id YOUR_API_ID \
     --stage-name prod \
     --patch-ops op=replace,path=/caching/enabled,value=true
   ```

### Security Procedures

#### **Security Incident Response**

1. **Immediate Actions**
   ```bash
   # Disable compromised user
   aws cognito-idp admin-disable-user \
     --user-pool-id YOUR_POOL_ID \
     --username COMPROMISED_USER
   
   # Revoke all refresh tokens
   aws cognito-idp admin-user-global-sign-out \
     --user-pool-id YOUR_POOL_ID \
     --username COMPROMISED_USER
   ```

2. **Investigation**
   ```bash
   # Check CloudTrail for user activity
   aws cloudtrail lookup-events \
     --lookup-attributes AttributeKey=Username,AttributeValue=COMPROMISED_USER \
     --start-time $(date -d '24 hours ago' --iso-8601)
   ```

#### **Regular Security Maintenance**

1. **Rotate Secrets** (if any)
   ```bash
   # Example: Rotate API keys (if using external services)
   # aws secretsmanager rotate-secret --secret-id prod/todoapp/apikey
   ```

2. **Review Access Logs**
   ```bash
   # Analyze access patterns
   aws logs filter-log-events \
     --log-group-name "/aws/lambda/todo-handler" \
     --filter-pattern "{ $.level = \"INFO\" && $.message = \"Authentication:\" }" \
     --start-time $(date -d '7 days ago' +%s)000
   ```

### Deployment Procedures

#### **Blue-Green Deployment**

1. **Create New Version**
   ```bash
   # Create Lambda version
   aws lambda publish-version \
     --function-name todo-handler \
     --description "Production deployment $(date)"
   
   # Create alias for new version
   aws lambda create-alias \
     --function-name todo-handler \
     --name BLUE \
     --function-version $LATEST
   ```

2. **Gradual Traffic Shift**
   ```bash
   # Route 10% traffic to new version
   aws lambda update-alias \
     --function-name todo-handler \
     --name PROD \
     --routing-config AdditionalVersionWeights={2=0.1}
   ```

3. **Rollback if Needed**
   ```bash
   # Immediate rollback
   aws lambda update-alias \
     --function-name todo-handler \
     --name PROD \
     --function-version 1
   ```

### Monitoring and Alerting Maintenance

#### **Update Alert Thresholds**

1. **Analyze Historical Data**
   ```bash
   # Get 30-day baseline for Lambda duration
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Lambda \
     --metric-name Duration \
     --dimensions Name=FunctionName,Value=todo-handler \
     --start-time $(date -d '30 days ago' --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 86400 \
     --statistics Average,Maximum
   ```

2. **Update Alarm Thresholds**
   ```bash
   # Update alarm threshold based on analysis
   aws cloudwatch put-metric-alarm \
     --alarm-name "todo-lambda-duration-dev" \
     --alarm-description "Updated threshold based on 30-day analysis" \
     --metric-name Duration \
     --namespace AWS/Lambda \
     --statistic Average \
     --period 300 \
     --threshold 8000 \
     --comparison-operator GreaterThanThreshold \
     --evaluation-periods 2
   ```

## 📱 Mobile Response Procedures

### Emergency Contact Script

```bash
#!/bin/bash
# Emergency notification script
# Usage: ./emergency-notify.sh "Critical: Lambda function down"

MESSAGE="$1"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Send SNS notification
aws sns publish \
  --topic-arn "arn:aws:sns:us-west-2:ACCOUNT:todo-app-alerts-dev" \
  --message "[$TIMESTAMP] $MESSAGE" \
  --subject "TodoApp Emergency Alert"

# Log to CloudWatch
aws logs put-log-events \
  --log-group-name "/aws/operational/emergency" \
  --log-stream-name "emergency-$(date +%Y%m%d)" \
  --log-events timestamp=$(date +%s)000,message="[$TIMESTAMP] $MESSAGE"

echo "Emergency notification sent: $MESSAGE"
```

This comprehensive operational runbook provides step-by-step procedures for managing the serverless todo application in production, covering incident response, daily operations, backup/recovery, scaling, security, and deployment procedures.
