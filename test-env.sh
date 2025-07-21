#!/bin/bash

# Test .env configuration and API key
# Quick validation script

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Testing .env Configuration${NC}"
echo ""

# Check if .env exists
if [[ -f ".env" ]]; then
    echo -e "${GREEN}✅ .env file found${NC}"
    
    # Load .env
    source .env
    
    # Test Gemini API key
    if [[ ! -z "$GEMINI_API_KEY" && "$GEMINI_API_KEY" != "your_gemini_api_key_here" ]]; then
        echo -e "${GREEN}✅ Gemini API key loaded${NC}"
        echo -e "${BLUE}🔑 Key: ${GEMINI_API_KEY:0:10}...${NC}"
        
        # Test API call
        echo -e "${BLUE}🧪 Testing API key...${NC}"
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GEMINI_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{"contents":[{"parts":[{"text":"Hello"}]}]}' 2>/dev/null || echo "000")
        
        if [[ $response == "200" ]]; then
            echo -e "${GREEN}✅ API key is working! Ready to deploy.${NC}"
        else
            echo -e "${YELLOW}⚠️  API test returned HTTP $response (might still work)${NC}"
        fi
    else
        echo -e "${RED}❌ Gemini API key not configured${NC}"
    fi
    
    # Check OpenAI key
    if [[ ! -z "$OPENAI_API_KEY" && "$OPENAI_API_KEY" != "your_openai_api_key_here" ]]; then
        echo -e "${GREEN}✅ OpenAI API key configured (fallback)${NC}"
    else
        echo -e "${YELLOW}ℹ️  OpenAI API key not configured (optional)${NC}"
    fi
    
else
    echo -e "${RED}❌ .env file not found${NC}"
    echo -e "${YELLOW}💡 Run: ./configure-env.sh${NC}"
fi

echo ""
echo -e "${BLUE}🚀 Ready to deploy? Run: ./deploy-ai-enhanced.sh${NC}"
