# 🔐 .env Configuration Guide for TaskFlow AI

## ✅ **Your API Key is Now Configured!**

Your Gemini API key has been successfully set up in the `.env` file:

```
GEMINI_API_KEY=AIzaSyA7i9p0S8QPgcZLAwmRRtC89RPiiJuqWNI
```

## 🚀 **Quick Deployment**

Your TaskFlow AI is now ready to deploy with full AI capabilities:

```bash
# Deploy with your configured API key
./deploy-ai-enhanced.sh
```

The deployment script will automatically:
- ✅ Load your Gemini API key from `.env`
- ✅ Configure the Lambda function with the API key
- ✅ Deploy the enhanced UI with AI features
- ✅ Set up all AWS infrastructure

## 🛠️ **Configuration Tools**

### **Test Your Setup**
```bash
./test-env.sh
```
Verifies your `.env` configuration and API key format.

### **Manage Configuration**
```bash
./configure-env.sh
```
Interactive tool to:
- View current configuration
- Update API keys
- Test API connectivity
- Add OpenAI fallback key

### **Quick Overview**
```bash
./quick-start.sh
```
Shows what's available and next steps.

## 📁 **.env File Structure**

Your `.env` file contains:

```bash
# TaskFlow AI Environment Configuration
GEMINI_API_KEY=AIzaSyA7i9p0S8QPgcZLAwmRRtC89RPiiJuqWNI
OPENAI_API_KEY=your_openai_api_key_here          # Optional
AWS_REGION=us-west-2
PROJECT_NAME=taskflow-ai
ENVIRONMENT=production
```

## 🔒 **Security Features**

- ✅ `.env` file is in `.gitignore` (won't be committed to git)
- ✅ API keys are marked as sensitive in Terraform
- ✅ Environment variables are encrypted in Lambda
- ✅ Fallback to AWS Secrets Manager if needed

## 🤖 **AI Features Enabled**

With your Gemini API key, TaskFlow AI can:

### **Smart Text Processing**
- Extract tasks from any text input
- Automatically categorize tasks (Work, Personal, Health, etc.)
- Detect priority levels (High, Medium, Low)
- Parse due dates from natural language

### **Multiple Extraction Modes**
- **Email Mode**: Process email content and meeting invitations
- **Notes Mode**: Extract action items from meeting notes
- **General Mode**: Handle any text with task-like content

### **Example Usage**
```
Input: "Meeting with Sarah about Q4 budget tomorrow at 2pm
        Call John regarding the project deadline by Friday
        Buy groceries for dinner tonight"

AI Output:
• Meeting with Sarah about Q4 budget (Work, High, Due: Tomorrow)
• Call John regarding project deadline (Work, High, Due: Friday)  
• Buy groceries for dinner (Shopping, Medium, Due: Today)
```

## 📊 **Technical Implementation**

### **Environment Variable Flow**
1. `.env` file stores your API key locally
2. Deployment script reads from `.env`
3. Terraform passes to Lambda as environment variable
4. Lambda uses environment variable first, AWS Secrets Manager as fallback

### **Lambda Configuration**
```python
# Lambda function checks environment variables first
gemini_api_key = os.environ.get('GEMINI_API_KEY')
if not gemini_api_key:
    # Fallback to secrets manager
    gemini_api_key = get_secret('gemini-api-key')
```

### **Terraform Variables**
```hcl
environment {
  variables = {
    GEMINI_API_KEY = var.gemini_api_key
    OPENAI_API_KEY = var.openai_api_key
  }
}
```

## 🧪 **Testing Your Configuration**

### **Pre-deployment Test**
```bash
./test-env.sh
```

### **Post-deployment Test**
```bash
./test-ai-functionality.sh
```

### **Manual API Test**
```bash
# Test Gemini API directly
curl -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"Extract tasks: Meeting tomorrow, buy groceries"}]}]}'
```

## 🔄 **Updating Configuration**

### **Change API Keys**
1. Edit `.env` file directly, or
2. Use `./configure-env.sh` for guided setup
3. Redeploy: `./deploy-ai-enhanced.sh`

### **Add OpenAI Fallback**
```bash
# Edit .env file
OPENAI_API_KEY=sk-your-openai-key-here

# Or use configuration tool
./configure-env.sh
```

## 🎯 **Next Steps**

1. **Deploy Now**: `./deploy-ai-enhanced.sh`
2. **Open Application**: Use the CloudFront URL provided after deployment
3. **Create Account**: Register with email verification
4. **Try AI Features**: Test task extraction with different text types
5. **Explore Categories**: See how AI categorizes different task types

## 💡 **Tips & Best Practices**

### **API Key Management**
- Keep your `.env` file secure and never commit it to git
- The API key is valid for your personal use
- Consider adding OpenAI as a fallback for redundancy

### **Performance Optimization**
- Gemini API is fast and free for reasonable usage
- Local fallback ensures the app works even without API keys
- Multiple extraction modes optimize for different content types

### **Troubleshooting**
- If deployment fails, check AWS credentials: `aws sts get-caller-identity`
- If AI doesn't work, verify API key in `.env` file
- If tests fail, try manual deployment steps in the script

## 🎉 **You're All Set!**

Your TaskFlow AI is configured and ready to deploy with:
- ✅ **Real AI Integration** using your Gemini API key
- ✅ **Modern Glassmorphism UI** with dark theme
- ✅ **Smart Task Processing** with categorization and priorities
- ✅ **Secure Configuration** with environment variables
- ✅ **Production-ready Architecture** on AWS

**Ready to experience AI-powered productivity?**

```bash
./deploy-ai-enhanced.sh
```

---

*Made with ❤️ and AI - Your intelligent todo app awaits!*
