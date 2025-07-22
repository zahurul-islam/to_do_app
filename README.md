# TaskFlow: An AI-Powered To-Do App

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

TaskFlow is an AI-powered, serverless to-do web application built on AWS. This project serves as a practical demonstration of modern cloud architecture, infrastructure as code, and DevOps principles. It is a fully functional, scalable, and secure to-do management system, designed to be cost-effective by operating entirely within the AWS Free Tier.

![Architecture Diagram](architecture.png)

## 🚀 Live Demo

[Link to your deployed application]

## ✨ Features

*   **Secure User Management**: Robust user authentication and authorization powered by Amazon Cognito, featuring secure sign-up, sign-in, and sign-out.
*   **Complete CRUD Functionality**: Full support for Creating, Reading, Updating, and Deleting (CRUD) to-do items.
*   **Responsive & Modern UI**: A sleek, mobile-friendly, and responsive user interface built with React and Tailwind CSS.
*   **Scalable Serverless Backend**: A highly scalable and resilient backend built with AWS Lambda and Amazon API Gateway.
*   **Automated Cloud Provisioning**: The entire cloud infrastructure is managed through Terraform, enabling automated, consistent, and repeatable deployments.
*   **CI/CD Ready**: The project is structured to be easily integrated into a CI/CD pipeline for automated testing and deployment.

## 🏛️ Architecture

The application is built on a serverless architecture, leveraging a suite of powerful AWS services:

*   **Frontend**: A responsive single-page application (SPA) built with **React** and hosted on **AWS Amplify**.
*   **Authentication**: User authentication and authorization are managed by **Amazon Cognito**.
*   **Backend Logic**: **AWS Lambda** functions, written in Python, handle the application's business logic.
*   **API**: A RESTful API is exposed via **Amazon API Gateway**, connecting the frontend with the backend services.
*   **Database**: **Amazon DynamoDB** provides a scalable and flexible NoSQL database for storing to-do items.
*   **Infrastructure as Code (IaC)**: The entire infrastructure is defined and managed using **Terraform**, promoting automation and consistency.

## 💻 Technology Stack

| Category      | Technology                               |
|---------------|------------------------------------------|
| **Frontend**  | React, Tailwind CSS                      |
| **Backend**   | Python, AWS Lambda                       |
| **Database**  | Amazon DynamoDB                          |
| **API**       | Amazon API Gateway                       |
| **Auth**      | Amazon Cognito                           |
| **Hosting**   | AWS Amplify                              |
| **IaC**       | Terraform                                |

## 📁 Project Structure

```
.
├── frontend/         # React frontend application
├── terraform/        # Terraform configuration files
│   ├── lambda/       # Python source code for Lambda functions
│   └── ...
├── scripts/          # Deployment and utility scripts
├── README.md         # This file
└── ...
```

## 🏁 Getting Started

To get the application up and running in your own AWS account, follow these steps.

### Prerequisites

*   An AWS account with administrator privileges.
*   The [AWS CLI](https://aws.amazon.com/cli/) installed and configured.
*   [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
*   [Node.js and npm](https://nodejs.org/en/download/) installed on your local machine.

### Setup

The `setup.sh` script prepares your environment for deployment. It installs frontend dependencies, configures AWS credentials for Terraform, and initializes the Terraform workspace.

```bash
./setup.sh
```

### Deployment

The `deploy.sh` script deploys the entire application stack to your AWS account using Terraform.

```bash
./deploy.sh
```

Once the deployment is complete, the script will output the URL of the deployed frontend application.

### Cleanup

The `cleanup.sh` script will destroy all the AWS resources created by the deployment, preventing any further charges.

```bash
./cleanup.sh
```

## 🔧 Usage

Once the application is deployed, you can access it using the URL provided by the deployment script. You will be able to:

1.  Create a new user account.
2.  Log in with your newly created account.
3.  Add, view, update, and delete your to-do items.

## 🧪 Testing

The project includes a test plan located in `docs/test-plan.md`. To test the authentication flow, you can use the `test-auth.sh` script.

```bash
./test-auth.sh
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## 📞 Contact

Mohammad Zahurul Islam - zaisbd@gmail.com

Project Link: [https://github.com/zahurul-islam/to_do_app](https://github.com/zahurul-islam/to_do_app)

## 💰 Cost Analysis

This project is designed to be highly cost-effective, leveraging the AWS Free Tier for initial development and small-scale deployment.

### AWS Free Tier

For typical development and testing, the application is designed to operate entirely **within the AWS Free Tier**, resulting in **$0 monthly cost**. The Free Tier provides significant annual savings, estimated at over **$66 for a development environment** and **$700 for a small business** scenario.

### Cost Beyond the Free Tier

For scaling beyond the Free Tier, a detailed cost analysis has been prepared. The cost scales efficiently with the number of users.

| Scenario | Users | Monthly Cost | Annual Cost | Cost per User |
|----------|-------|--------------|-------------|---------------|
| **Development** | 10 | **$5.52** | $66.25 | $0.552 |
| **Small Business** | 1,000 | **$58.70** | $704.36 | $0.0587 |
| **Medium Business** | 10,000 | **$547.30** | $6,567.59 | $0.0547 |
| **Enterprise** | 100,000 | **$5,433.32** | $65,199.89 | $0.0543 |

The primary cost drivers at scale are **CloudFront** (70-80%), **DynamoDB** (10-15%), and **Cognito** (5-10%).

For a complete breakdown, including cost scaling analysis, major cost drivers, and optimization strategies, please see the full report: [AWS Cost Analysis - Without Free Tier](AWS_COST_ANALYSIS_NO_FREE_TIER.md).