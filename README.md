☁️ Amazona E-Commerce Infrastructure

This repository contains the Infrastructure as Code (IaC) required to provision the AWS cloud environment for the Amazona MERN-stack e-commerce platform.

This project strictly follows the Dedicated Infrastructure Repository pattern, separating Terraform configurations from application code to ensure safer deployments, decoupled CI/CD pipelines, and isolated state management.

🏗️ Architecture Overview

The infrastructure is divided into two distinct domains to minimize blast radius and ensure independent scalability:

1. Backend Infrastructure (/backend_terraform)

Provisions the networking and compute resources required to run the Node.js/Express API.

Amazon VPC: Custom virtual network with public/private subnets.

Amazon ECS (Fargate): Serverless container orchestration for the Node.js backend.

Amazon ECR: Container registry for storing backend Docker images.

Application Load Balancer (ALB): Distributes incoming API traffic across ECS tasks.

2. Frontend Infrastructure (/frontend_terraform)

Provisions the secure, globally distributed hosting environment for the React Single Page Application (SPA).

Amazon S3: Private bucket storing the compiled React static assets.

Amazon CloudFront: Global Content Delivery Network (CDN) serving the application over HTTPS.

Origin Access Control (OAC): Secures the S3 bucket, ensuring it can only be accessed via CloudFront.

🔐 The CloudFront Reverse Proxy

To solve browser "Mixed Content" (HTTP vs HTTPS) security blocks without requiring a custom domain for the ALB, this architecture utilizes CloudFront as a reverse proxy.

Traffic hitting /* is routed to the S3 Bucket (React UI).

Traffic hitting /api/* is securely tunneled to the Backend ALB (Node.js API).

📁 Repository Structure

.
├── backend_terraform/
│   ├── main.tf          # ECS, VPC, ALB configurations
│   ├── variables.tf     # Backend variables
│   └── outputs.tf       # Outputs ALB DNS name
│
└── frontend_terraform/
    ├── main.tf          # S3, CloudFront, OAC configurations
    ├── variables.tf     # Frontend variables
    ├── outputs.tf       # Outputs CloudFront Distribution Domain
    └── modules/         # Reusable CDN modules


🚀 Deployment Order (Crucial)

Because the environments are decoupled, they must be applied in a specific order. The Frontend CloudFront distribution requires the Backend Load Balancer's DNS URL to establish the /api/* reverse proxy.

Step 1: Provision the Backend

cd backend_terraform
terraform init
terraform apply -auto-approve


Wait for completion and copy the alb_dns_name output.

Step 2: Provision the Frontend

cd ../frontend_terraform
terraform init


Before applying, pass the alb_dns_name into your variables so CloudFront knows where to route API traffic:

terraform apply -auto-approve


🛠️ State Management

Currently, state is stored locally (terraform.tfstate). For team collaboration, configure an S3 backend with DynamoDB state locking.