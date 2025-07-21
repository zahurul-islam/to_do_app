#!/bin/bash

# Modern UI Update Script for TaskFlow
# Applies the modern AI-powered interface

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_step() { echo -e "${PURPLE}🚀 $1${NC}"; }

echo ""
echo "🎨 TaskFlow Modern UI Update"
echo "============================"
echo "✨ Upgrading to AI-powered interface with modern design"
echo ""

# Check if modern files exist
if [ ! -f "frontend/app-modern.js" ] || [ ! -f "frontend/index-modern.html" ]; then
    log_warning "Modern UI files not found. Please ensure you have the latest version."
    exit 1
fi

log_step "Creating backup of current interface..."

# Create backup
BACKUP_DIR="backup_ui_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR/frontend"

if [ -f "frontend/app.js" ]; then
    cp "frontend/app.js" "$BACKUP_DIR/frontend/app.js.backup"
    log_success "Backed up app.js"
fi

if [ -f "frontend/index.html" ]; then
    cp "frontend/index.html" "$BACKUP_DIR/frontend/index.html.backup"
    log_success "Backed up index.html"
fi

log_step "Applying modern AI-powered interface..."

# Apply modern interface
cp "frontend/app-modern.js" "frontend/app.js"
cp "frontend/index-modern.html" "frontend/index.html"

log_success "Modern interface applied successfully!"

echo ""
echo "🎉 TaskFlow UI Update Complete!"
echo "==============================="
echo ""
echo "🆕 New Features:"
echo "   ✨ Modern Tailwind CSS design"
echo "   🧠 AI-powered todo extraction from text"
echo "   📱 Enhanced mobile responsive design"
echo "   🎨 Beautiful gradients and animations"
echo "   📊 Smart task categorization and prioritization"
echo "   🔍 Intelligent text analysis for action items"
echo "   ⚡ Improved performance and interactions"
echo ""
echo "🧠 AI Features:"
echo "   📧 Extract todos from emails"
echo "   📝 Parse meeting notes for action items"
echo "   📄 Analyze any text for tasks and deadlines"
echo "   🎯 Auto-categorize and prioritize extracted tasks"
echo "   💡 Smart confidence scoring for extracted items"
echo ""
echo "🎨 Modern Design:"
echo "   • Tailwind CSS for consistent styling"
echo "   • Glassmorphism effects and modern gradients"
echo "   • Smooth animations and micro-interactions"
echo "   • Enhanced accessibility and focus states"
echo "   • Mobile-first responsive design"
echo ""
echo "📋 Backup Information:"
echo "   📁 Previous interface backed up to: $BACKUP_DIR"
echo "   🔄 To rollback: cp $BACKUP_DIR/frontend/*.backup frontend/"
echo ""
echo "🚀 Next Steps:"
echo "   1. Refresh your browser to see the new interface"
echo "   2. Try the AI extraction feature with sample text"
echo "   3. Test the modern responsive design on mobile"
echo "   4. Explore the enhanced todo management features"
echo ""

if command -v open &> /dev/null; then
    echo "🌐 Would you like to open the app now? (y/n)"
    read -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        log_info "Opening TaskFlow in your default browser..."
        if [ -f "terraform/terraform.tfstate" ]; then
            cd terraform
            FRONTEND_URL=$(terraform output -raw website_url 2>/dev/null || terraform output -raw cloudfront_distribution_url 2>/dev/null || echo "")
            cd ..
            if [ -n "$FRONTEND_URL" ]; then
                open "$FRONTEND_URL" 2>/dev/null || echo "Please visit: $FRONTEND_URL"
            else
                echo "Please deploy first with: ./deploy.sh"
            fi
        else
            echo "Please deploy first with: ./deploy.sh"
        fi
    fi
fi

echo ""
log_success "Modern TaskFlow is ready! 🎉"
