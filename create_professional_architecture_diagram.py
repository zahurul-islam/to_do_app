#!/usr/bin/env python3
"""
Create Professional AWS Architecture Diagram for TaskFlow Application
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Circle, Rectangle, FancyArrowPatch, Polygon
import matplotlib.lines as mlines
import numpy as np

# Create figure and axis
fig, ax = plt.subplots(1, 1, figsize=(20, 14))
ax.set_xlim(0, 100)
ax.set_ylim(0, 100)
ax.axis('off')

# Define AWS colors
aws_orange = '#FF9900'
aws_dark_blue = '#232F3E'
aws_light_blue = '#146EB4'
aws_green = '#7AA116'
aws_purple = '#9D5AAE'
aws_red = '#D13212'
light_gray = '#F5F5F5'
white = '#FFFFFF'

# Set background
fig.patch.set_facecolor(white)
ax.set_facecolor(white)

# Title
plt.title('TaskFlow - Serverless Todo Application Architecture on AWS', 
          fontsize=28, fontweight='bold', pad=30, color=aws_dark_blue)

# Helper function to create AWS-style service boxes
def create_service_box(ax, x, y, width, height, service_name, service_type, icon_color):
    # Main box
    box = FancyBboxPatch((x, y), width, height,
                         boxstyle="round,pad=0.3",
                         facecolor=white,
                         edgecolor=icon_color,
                         linewidth=3)
    ax.add_patch(box)
    
    # Icon circle
    icon = Circle((x + width/2, y + height - height/3), height/5,
                  facecolor=icon_color, edgecolor='none')
    ax.add_patch(icon)
    
    # Service name
    ax.text(x + width/2, y + height/4, service_name, 
            ha='center', va='center', fontsize=11, 
            fontweight='bold', color=aws_dark_blue)
    
    # Service type
    ax.text(x + width/2, y + height/10, service_type, 
            ha='center', va='center', fontsize=8, 
            style='italic', color='gray')
    
    return box

# Helper function to create section headers
def create_section_header(ax, x, y, width, text, color):
    header = Rectangle((x, y), width, 3,
                      facecolor=color, edgecolor='none', alpha=0.8)
    ax.add_patch(header)
    ax.text(x + width/2, y + 1.5, text,
            ha='center', va='center', fontsize=14,
            fontweight='bold', color=white)

# Helper function to create arrows with labels
def create_labeled_arrow(ax, x1, y1, x2, y2, label='', color=aws_dark_blue, style='solid'):
    arrow = FancyArrowPatch((x1, y1), (x2, y2),
                           connectionstyle="arc3,rad=0.2",
                           arrowstyle='-|>',
                           mutation_scale=25,
                           linewidth=2.5,
                           linestyle=style,
                           color=color)
    ax.add_patch(arrow)
    if label:
        mid_x = (x1 + x2) / 2
        mid_y = (y1 + y2) / 2
        # Add white background for label
        bbox_props = dict(boxstyle="round,pad=0.3", facecolor=white, edgecolor='none', alpha=0.8)
        ax.text(mid_x, mid_y + 1, label, ha='center', va='center', 
                fontsize=9, bbox=bbox_props, color=aws_dark_blue)

# Create regions/sections
# User section
create_section_header(ax, 5, 90, 90, 'Users & Client Applications', aws_dark_blue)

# Frontend section
frontend_bg = Rectangle((10, 70), 35, 18, 
                       facecolor=light_gray, edgecolor=aws_orange, 
                       linewidth=2, alpha=0.3)
ax.add_patch(frontend_bg)
ax.text(27.5, 86, 'Frontend Layer', ha='center', fontsize=12, 
        fontweight='bold', color=aws_orange)

# Backend section
backend_bg = Rectangle((55, 70), 35, 18, 
                      facecolor=light_gray, edgecolor=aws_light_blue, 
                      linewidth=2, alpha=0.3)
ax.add_patch(backend_bg)
ax.text(72.5, 86, 'Authentication', ha='center', fontsize=12, 
        fontweight='bold', color=aws_light_blue)

# API section
api_bg = Rectangle((10, 45), 80, 20, 
                   facecolor=light_gray, edgecolor=aws_purple, 
                   linewidth=2, alpha=0.3)
ax.add_patch(api_bg)
ax.text(50, 63, 'API Layer', ha='center', fontsize=12, 
        fontweight='bold', color=aws_purple)

# Compute section
compute_bg = Rectangle((10, 20), 80, 20, 
                      facecolor=light_gray, edgecolor=aws_orange, 
                      linewidth=2, alpha=0.3)
ax.add_patch(compute_bg)
ax.text(50, 38, 'Compute Layer', ha='center', fontsize=12, 
        fontweight='bold', color=aws_orange)

# Storage section
storage_bg = Rectangle((10, 2), 35, 15, 
                      facecolor=light_gray, edgecolor=aws_green, 
                      linewidth=2, alpha=0.3)
ax.add_patch(storage_bg)
ax.text(27.5, 15, 'Storage & Data', ha='center', fontsize=12, 
        fontweight='bold', color=aws_green)

# Monitoring section
monitoring_bg = Rectangle((55, 2), 35, 15, 
                         facecolor=light_gray, edgecolor=aws_red, 
                         linewidth=2, alpha=0.3)
ax.add_patch(monitoring_bg)
ax.text(72.5, 15, 'Monitoring & Logging', ha='center', fontsize=12, 
        fontweight='bold', color=aws_red)

# Add services
# Users
users_icon = Circle((50, 95), 2, facecolor=aws_dark_blue, edgecolor='none')
ax.add_patch(users_icon)
ax.text(50, 91, 'End Users', ha='center', fontsize=11, fontweight='bold')

# Frontend services
cloudfront = create_service_box(ax, 15, 74, 12, 10, 'CloudFront', 'CDN', aws_orange)
s3 = create_service_box(ax, 30, 74, 12, 10, 'S3 Bucket', 'Static Hosting', aws_green)

# Authentication services
cognito_pool = create_service_box(ax, 60, 74, 12, 10, 'Cognito', 'User Pool', aws_light_blue)
cognito_identity = create_service_box(ax, 75, 74, 12, 10, 'Cognito', 'Identity Pool', aws_light_blue)

# API Gateway
api_main = create_service_box(ax, 25, 50, 15, 10, 'API Gateway', 'REST API', aws_purple)
api_ai = create_service_box(ax, 45, 50, 15, 10, 'API Gateway', 'AI Endpoint', aws_purple)
api_authorizer = create_service_box(ax, 65, 50, 15, 10, 'Authorizer', 'Cognito', aws_purple)

# Lambda functions
lambda_todo = create_service_box(ax, 15, 25, 12, 10, 'Lambda', 'Todo Handler', aws_orange)
lambda_ai = create_service_box(ax, 30, 25, 12, 10, 'Lambda', 'AI Extractor', aws_orange)
lambda_xray = create_service_box(ax, 45, 25, 12, 10, 'Lambda', 'X-Ray Tracer', aws_orange)

# Storage services
dynamodb = create_service_box(ax, 15, 6, 12, 8, 'DynamoDB', 'NoSQL DB', aws_green)
secrets = create_service_box(ax, 30, 6, 12, 8, 'Secrets Mgr', 'API Keys', aws_red)

# Monitoring services
cloudwatch_logs = create_service_box(ax, 60, 6, 12, 8, 'CloudWatch', 'Logs', aws_red)
cloudwatch_metrics = create_service_box(ax, 75, 6, 12, 8, 'CloudWatch', 'Metrics/Alarms', aws_red)

# Add connections
# User flows
create_labeled_arrow(ax, 50, 93, 27, 84, 'HTTPS', aws_dark_blue)
create_labeled_arrow(ax, 50, 93, 66, 84, 'Sign Up/In', aws_light_blue)
create_labeled_arrow(ax, 48, 91, 32.5, 60, 'API Calls', aws_purple, 'dashed')

# Frontend connections
create_labeled_arrow(ax, 21, 74, 36, 74, 'Static Files', aws_green)

# Auth flow
create_labeled_arrow(ax, 66, 74, 81, 74, '', aws_light_blue)
create_labeled_arrow(ax, 72, 60, 72, 74, 'Validate', aws_light_blue)

# API to Lambda
create_labeled_arrow(ax, 32.5, 50, 21, 35, 'Invoke', aws_orange)
create_labeled_arrow(ax, 52.5, 50, 36, 35, 'Invoke', aws_orange)

# Lambda to Storage
create_labeled_arrow(ax, 21, 25, 21, 14, 'Read/Write', aws_green)
create_labeled_arrow(ax, 36, 25, 36, 14, 'Get Keys', aws_red)

# Lambda to Monitoring
create_labeled_arrow(ax, 51, 30, 66, 14, 'Logs', aws_red, 'dotted')
create_labeled_arrow(ax, 51, 28, 81, 14, 'Metrics', aws_red, 'dotted')

# Add AWS logo
ax.text(95, 2, 'AWS', fontsize=20, fontweight='bold', 
        ha='right', color=aws_orange)

# Add legend
legend_elements = [
    mlines.Line2D([0], [0], color=aws_dark_blue, lw=2.5, label='Data Flow'),
    mlines.Line2D([0], [0], color=aws_purple, lw=2.5, linestyle='dashed', label='API Requests'),
    mlines.Line2D([0], [0], color=aws_red, lw=2.5, linestyle='dotted', label='Monitoring'),
    mlines.Line2D([0], [0], color=aws_light_blue, lw=2.5, label='Authentication')
]
legend = ax.legend(handles=legend_elements, loc='lower left', 
                  frameon=True, fancybox=True, shadow=True)
legend.get_frame().set_facecolor(white)
legend.get_frame().set_edgecolor(aws_dark_blue)

# Add key features text
features_text = """Key Features:
• Serverless architecture
• Auto-scaling
• High availability
• Cost-effective
• AI-powered task extraction"""

ax.text(5, 35, features_text, fontsize=10, 
        bbox=dict(boxstyle="round,pad=0.5", facecolor=white, 
                  edgecolor=aws_dark_blue, linewidth=2))

# Save the diagram
plt.tight_layout()
plt.savefig('taskflow_architecture_professional.png', dpi=300, bbox_inches='tight', 
            facecolor=white, edgecolor='none')
print("Professional architecture diagram created successfully!")
print("Output file: taskflow_architecture_professional.png")