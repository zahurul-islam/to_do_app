#!/usr/bin/env python3
"""
Create AWS Architecture Diagram for TaskFlow Application using matplotlib
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Rectangle, FancyArrowPatch
import matplotlib.lines as mlines

# Create figure and axis
fig, ax = plt.subplots(1, 1, figsize=(16, 12))
ax.set_xlim(0, 100)
ax.set_ylim(0, 100)
ax.axis('off')

# Define colors
aws_orange = '#FF9900'
aws_blue = '#232F3E'
light_blue = '#E6F3FF'
light_gray = '#F0F0F0'

# Title
plt.title('TaskFlow - Serverless Todo Application Architecture', 
          fontsize=24, fontweight='bold', pad=20)

# Helper function to create boxes
def create_box(ax, x, y, width, height, text, color=light_blue, textcolor='black'):
    box = FancyBboxPatch((x, y), width, height,
                         boxstyle="round,pad=0.1",
                         facecolor=color,
                         edgecolor='black',
                         linewidth=2)
    ax.add_patch(box)
    ax.text(x + width/2, y + height/2, text, 
            ha='center', va='center', fontsize=10, 
            fontweight='bold', color=textcolor, wrap=True)
    return box

# Helper function to create arrows
def create_arrow(ax, x1, y1, x2, y2, label='', style='solid'):
    arrow = FancyArrowPatch((x1, y1), (x2, y2),
                           connectionstyle="arc3,rad=0.1",
                           arrowstyle='-|>',
                           mutation_scale=20,
                           linewidth=2,
                           linestyle=style,
                           color='black')
    ax.add_patch(arrow)
    if label:
        mid_x = (x1 + x2) / 2
        mid_y = (y1 + y2) / 2
        ax.text(mid_x, mid_y, label, ha='center', va='bottom', fontsize=8)

# Users
create_box(ax, 45, 90, 10, 5, 'End Users', aws_orange)

# Frontend Layer
ax.text(50, 82, 'Frontend Layer', ha='center', fontsize=12, fontweight='bold')
create_box(ax, 40, 72, 20, 6, 'CloudFront\nDistribution', light_blue)
create_box(ax, 40, 64, 20, 6, 'S3 Bucket\n(Static Website)', light_blue)

# API Gateway
ax.text(25, 55, 'API Gateway', ha='center', fontsize=12, fontweight='bold')
create_box(ax, 15, 45, 20, 6, 'REST API\n/todos', light_blue)
create_box(ax, 15, 37, 20, 6, 'AI Endpoint\n/ai/extract', light_blue)

# Authentication
ax.text(75, 55, 'Authentication', ha='center', fontsize=12, fontweight='bold')
create_box(ax, 65, 45, 20, 6, 'Cognito\nUser Pool', '#FFD700')
create_box(ax, 65, 37, 20, 6, 'Cognito\nIdentity Pool', '#FFD700')

# Lambda Functions
ax.text(25, 28, 'Lambda Functions', ha='center', fontsize=12, fontweight='bold')
create_box(ax, 10, 18, 15, 6, 'Todo Handler\n(CRUD)', '#FFA500')
create_box(ax, 30, 18, 15, 6, 'AI Extractor\n(Gemini)', '#FFA500')
create_box(ax, 50, 18, 15, 6, 'X-Ray\nHandler', '#FFA500')

# Data Storage
ax.text(25, 10, 'Data Storage', ha='center', fontsize=12, fontweight='bold')
create_box(ax, 10, 2, 15, 5, 'DynamoDB\nTodos Table', '#3369E7')
create_box(ax, 30, 2, 15, 5, 'Secrets Mgr\nAPI Keys', '#3369E7')

# Monitoring
ax.text(75, 28, 'Monitoring', ha='center', fontsize=12, fontweight='bold')
create_box(ax, 70, 18, 15, 6, 'CloudWatch\nLogs', '#759EE0')
create_box(ax, 70, 10, 15, 6, 'CloudWatch\nMetrics', '#759EE0')
create_box(ax, 70, 2, 15, 6, 'CloudWatch\nAlarms', '#759EE0')

# Create connections
# User to Frontend
create_arrow(ax, 50, 90, 50, 78, 'HTTPS')

# Frontend connections
create_arrow(ax, 50, 72, 50, 70)

# User to API
create_arrow(ax, 45, 88, 25, 51, 'API Calls', 'dashed')
create_arrow(ax, 45, 88, 25, 43, 'AI Requests', 'dashed')

# User to Auth
create_arrow(ax, 55, 88, 75, 51, 'Auth')

# Auth connections
create_arrow(ax, 75, 45, 75, 43)

# API to Lambda
create_arrow(ax, 25, 45, 17.5, 24, 'Invoke')
create_arrow(ax, 25, 37, 37.5, 24, 'Invoke')

# Lambda to Data
create_arrow(ax, 17.5, 18, 17.5, 7, 'R/W')
create_arrow(ax, 57.5, 18, 17.5, 7, 'R/W')
create_arrow(ax, 37.5, 18, 37.5, 7, 'Get Keys')

# Lambda to Monitoring
create_arrow(ax, 25, 21, 70, 21, '', 'dotted')
create_arrow(ax, 45, 21, 70, 21, '', 'dotted')

# Legend
legend_elements = [
    mlines.Line2D([0], [0], color='black', lw=2, label='Data Flow'),
    mlines.Line2D([0], [0], color='black', lw=2, linestyle='dashed', label='API Calls'),
    mlines.Line2D([0], [0], color='black', lw=2, linestyle='dotted', label='Monitoring')
]
ax.legend(handles=legend_elements, loc='lower right')

# Add AWS services labels
ax.text(2, 95, 'AWS Services Used:', fontsize=10, fontweight='bold')
services = [
    '• CloudFront (CDN)',
    '• S3 (Static Hosting)',
    '• API Gateway',
    '• Lambda Functions',
    '• DynamoDB',
    '• Cognito (Auth)',
    '• Secrets Manager',
    '• CloudWatch'
]
for i, service in enumerate(services):
    ax.text(2, 92 - i*2.5, service, fontsize=8)

# Save the diagram
plt.tight_layout()
plt.savefig('taskflow_architecture.png', dpi=300, bbox_inches='tight', 
            facecolor='white', edgecolor='none')
print("Architecture diagram created successfully!")
print("Output file: taskflow_architecture.png")