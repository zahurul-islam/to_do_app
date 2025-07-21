# Serverless Todo Application

This project is a complete serverless web application built on AWS, demonstrating modern cloud architecture and DevOps practices. It's a fully functional todo management system designed to be scalable, secure, and cost-effective by operating within the AWS Free Tier.

![Architecture Diagram](architecture.png)

## Table of Contents

- [Architecture](#architecture)
- [Features](#features)
- [Technologies Used](#technologies-used)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Setup](#setup)
  - [Deployment](#deployment)
  - [Cleanup](#cleanup)
- [Usage](#usage)
- [Testing](#testing)
- [License](#license)
- [Future Enhancements](#future-enhancements)

## Architecture

The application follows a serverless architecture, leveraging a suite of AWS services to provide a scalable and resilient platform:

-   **Frontend**: A React-based single-page application hosted on **AWS Amplify**.
-   **Authentication**: User authentication and authorization are handled by **Amazon Cognito**.
-   **Backend Logic**: **AWS Lambda** functions, written in Python, execute the backend business logic.
-   **API**: A RESTful API is exposed through **Amazon API Gateway** to connect the frontend with the backend services.
-   **Database**: **Amazon DynamoDB** is used as the NoSQL database for storing todo items.
-   **Infrastructure as Code**: The entire infrastructure is defined and managed using **Terraform**, enabling automated and repeatable deployments.

## Features

-   **User Authentication**: Secure sign-up, sign-in, and sign-out functionality.
-   **CRUD Operations**: Create, Read, Update, and Delete todo items.
-   **Responsive UI**: A mobile-friendly and responsive user interface.
-   **Serverless Backend**: A fully serverless backend that scales automatically.
-   **Automated Deployment**: Infrastructure and application deployment are automated with shell scripts and Terraform.

## Technologies Used

-   **Frontend**: React, Tailwind CSS
-   **Backend**: Python, AWS Lambda
-   **Database**: Amazon DynamoDB
-   **API**: Amazon API Gateway
-   **Authentication**: Amazon Cognito
-   **Hosting**: AWS Amplify
-   **Infrastructure as Code**: Terraform

## Getting Started

Follow these instructions to get the application up and running in your own AWS account.

### Prerequisites

-   An AWS account with administrator access.
-   The AWS CLI installed and configured on your local machine.
-   Terraform installed on your local machine.
-   Node.js and npm installed on your local machine.

### Setup

The `setup.sh` script prepares the environment for deployment. It performs the following actions:

1.  Installs frontend dependencies.
2.  Configures AWS credentials for Terraform.
3.  Initializes the Terraform workspace.

To run the setup script, execute the following command:

```bash
./setup.sh
```

### Deployment

The `deploy.sh` script deploys the entire application stack to your AWS account using Terraform.

To deploy the application, run:

```bash
./deploy.sh
```

After the deployment is complete, the script will output the URL of the deployed frontend application.

### Cleanup

The `cleanup.sh` script destroys all the AWS resources created by the deployment, preventing any ongoing costs.

To remove the application from your AWS account, run:

```bash
./cleanup.sh
```

## Usage

Once the application is deployed, you can access it using the URL provided at the end of the deployment script. You will be able to:

1.  Create a new user account.
2.  Log in with your new account.
3.  Add, view, update, and delete your todo items.

## Testing

The project includes a test plan located in `docs/test-plan.md`. The `test-auth.sh` script can be used to test the authentication flow.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Future Enhancements

-   Real-time collaboration on todo lists.
-   Support for multiple todo lists per user.
-   Integration with third-party calendar services.
