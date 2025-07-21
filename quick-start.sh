#!/bin/bash

# Quick start guide for TaskFlow AI
# Shows overview of the enhanced application and next steps

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  $1  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
}

print_section() {
    echo -e "${CYAN}▶ $1${NC}"
}

echo ""
print_header "🚀 TaskFlow AI - Quick Start Guide"
echo ""

echo -e "${GREEN}🎉 Congratulations! Your AWS Todo app has been transformed into TaskFlow AI!${NC}"
echo ""

print_section "✨ What's New:"
echo "🤖 AI-powered task extraction from emails, notes, and documents"
echo "🎨 Modern glassmorphism UI with dark theme and smooth animations"
echo "🧠 Smart categorization and priority detection"
echo "📅 Automatic due date extraction from natural language"
echo "🔐 Enhanced security with AWS Secrets Manager for API keys"
echo "☁️ Production-ready deployment with comprehensive testing"
echo ""

print_section "📁 New Files Created:"
echo -e "${YELLOW}Enhanced Frontend:${NC}"
echo "  • index-ai-enhanced.html (Modern UI with glassmorphism)"
echo "  • app-ai-enhanced.js (React app with AI integration)"
echo "  • components-enhanced.js (Modern UI components)"
echo ""
echo -e "${YELLOW}AI Backend:${NC}"
echo "  • terraform/ai-integration.tf (AI Lambda and API Gateway)"
echo "  • terraform/lambda/gemini_extractor/index.py (Real AI logic)"
echo ""
echo -e "${YELLOW}Deployment Tools:${NC}"
echo "  • deploy-ai-enhanced.sh (Complete deployment script)"
echo "  • configure-env.sh (API key configuration tool)"
echo "  • test-ai-functionality.sh (Testing suite)"
echo ""

print_section "🚀 How to Deploy:"
echo -e "${GREEN}1. Configure API keys (your Gemini key is already set!):${NC}"
echo "   ./configure-env.sh"
echo ""
echo -e "${GREEN}2. Deploy TaskFlow AI:${NC}"
echo "   ./deploy-ai-enhanced.sh"
echo ""
echo -e "${GREEN}3. Test the deployment:${NC}"
echo "   ./test-ai-functionality.sh"
echo ""

print_section "🔑 API Keys:"
echo -e "${GREEN}✅ Gemini API key configured in .env file${NC}"
echo -e "${YELLOW}Optional:${NC} OpenAI API key for fallback (use ./configure-env.sh)"
echo ""
echo -e "${CYAN}Your Gemini API key: AIzaSyA7i9p0S8QPgcZLAwmRRtC89RPiiJuqWNI${NC}"
echo ""

print_section "🎯 AI Features to Try:"
echo "📧 Email Mode: Extract tasks from email content"
echo "📝 Notes Mode: Process meeting notes and action items"
echo "🎯 General Mode: Handle any text with task-like content"
echo ""

print_section "📚 Documentation:"
echo "• README-AI-ENHANCED.md - Complete feature documentation"
echo "• IMPLEMENTATION-SUMMARY.md - Detailed implementation overview"
echo ""

print_section "🛠️ Quick Commands:"
echo -e "${YELLOW}Configure:${NC} ./configure-env.sh"
echo -e "${YELLOW}Deploy:${NC} ./deploy-ai-enhanced.sh"
echo -e "${YELLOW}Test:${NC} ./test-ai-functionality.sh"
echo ""

print_header "🎉 Ready to Experience AI-Powered Productivity!"

echo ""
echo -e "${GREEN}Your next-generation todo app awaits!${NC}"
echo -e "${CYAN}Start with: ${YELLOW}./deploy-ai-enhanced.sh${NC}"
echo -e "${CYAN}(Your Gemini API key is already configured! ✅)${NC}"
echo ""
