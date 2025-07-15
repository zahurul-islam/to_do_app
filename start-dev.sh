#!/bin/bash

# Quick Development Server Launcher for AWS Todo App
# Fixes the config.json loading issue and provides local development environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 AWS Todo App - Development Server${NC}"
echo "=================================="
echo ""

# Check if we're in the right directory
if [ ! -d "frontend" ]; then
    echo -e "${RED}❌ Error: Please run this script from the project root directory${NC}"
    echo "Expected to find 'frontend' directory here."
    exit 1
fi

# Check if required files exist
echo -e "${BLUE}🔍 Checking required files...${NC}"
required_files=("frontend/index.html" "frontend/config.json" "frontend/app-fixed.js")
missing_files=()

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  ✅ $file${NC}"
    else
        echo -e "${RED}  ❌ $file${NC}"
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -ne 0 ]; then
    echo ""
    echo -e "${RED}❌ Missing required files. Please ensure the project is complete.${NC}"
    exit 1
fi

# Check if Python is available
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo -e "${RED}❌ Error: Python is not installed or not in PATH${NC}"
    echo "Please install Python 3 to run the development server."
    exit 1
fi

echo ""
echo -e "${GREEN}✅ All checks passed!${NC}"
echo ""

# Start the development server
echo -e "${BLUE}🌐 Starting development server...${NC}"
echo "Server will be available at: http://localhost:8000"
echo "Press Ctrl+C to stop the server"
echo ""

# Run the Python development server
exec $PYTHON_CMD start-dev-server.py

