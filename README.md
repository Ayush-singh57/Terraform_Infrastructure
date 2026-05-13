🚀 Overview

This repository contains the completely decoupled AWS cloud infrastructure for the Amazona e-commerce platform.

By strictly following the Dedicated Infrastructure Repository pattern, the Terraform configurations are isolated from the application code. This ensures zero-downtime deployments, independent CI/CD pipelines, and a minimal blast radius for infrastructure updates.

📊 Architecture & Traffic Flow

The following flowchart illustrates the lifecycle of a user request, demonstrating how the CloudFront Reverse Proxy securely routes traffic to either the static frontend or the dynamic serverless backend.

graph TD
    %% Define User
    User((🧑‍💻 User Browser))

    %% Define AWS Cloud
    subgraph "AWS Cloud (ap-south-1)"
        CF[🌐 CloudFront CDN <br/> <i>(Reverse Proxy)</i>]
        
        subgraph "Frontend Domain"
            S3[(📦 Private S3 Bucket <br/> <i>React SPA</i>)]
        end
        
        subgraph "Backend Domain"
            ALB[🔀 Application Load Balancer]
            ECS[⚙️ ECS Fargate <br/> <i>Node.js / Express</i>]
        end
    end

    %% External
    DB[(🍃 MongoDB Atlas)]

    %% Connections
    User -- "HTTPS Request" --> CF
    CF -- "Path: /* \n(Origin Access Control)" --> S3
    CF -- "Path: /api/* \n(Secure Tunnel)" --> ALB
    ALB -- "Port 80" --> ECS
    ECS -- "Mongoose Auth" --> DB

    %% Styling
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:white;
    classDef db fill:#4ea94b,stroke:#3c823a,stroke-width:2px,color:white;
    class CF,S3,ALB,ECS aws;
    class DB db;


The Reverse Proxy Advantage: This design allows the backend ALB to "piggyback" on CloudFront's default wildcard SSL certificate, providing end-to-end encryption and a unified API domain (d3vno...cloudfront.net/api) out of the box without purchasing custom domains.

🏗️ Infrastructure Components

The environment is split into two distinct, independently manageable domains.

Domain

Component

AWS Service

Purpose

Backend

Networking

VPC, Subnets, NAT

Custom virtual network isolating the compute resources. Private subnets protect the API servers, while NAT Gateways allow outbound image pulls.

Backend

Compute

ECS (Fargate)

Fully serverless container orchestration running Node.js. No EC2 instances to manage or patch.

Backend

Registry

ECR

Private container registry for securely storing backend Docker images.

Backend

Traffic Routing

ALB

Application Load Balancer distributes API traffic across healthy Fargate tasks.

Frontend

Storage

S3

Private bucket storing the compiled React static assets.

Frontend

CDN / Proxy

CloudFront

Global Content Delivery Network with edge caching. Also acts as the API reverse proxy.

Frontend

Security

OAC

Origin Access Control locks down the S3 bucket so it can only be accessed via CloudFront.

📁 Repository Structure

.
├── backend_terraform/
│   ├── main.tf          # ECS, VPC, ALB, and Security Groups
│   ├── variables.tf     # Configurable backend variables
│   └── outputs.tf       # Exposes the ALB DNS URL
│
└── frontend_terraform/
    ├── main.tf          # S3, CloudFront, and OAC configs
    ├── variables.tf     # Configurable frontend variables
    ├── outputs.tf       # Exposes the live CDN Domain
    └── modules/         # Reusable CDN Terraform modules


⚙️ Deployment Protocol (Strict Order)

Because the frontend proxy dynamically routes API traffic to the backend, the environments must be applied in the following order:

Step 1: Provision the Backend

cd backend_terraform
terraform init
terraform apply -auto-approve


Wait for completion and copy the outputted alb_dns_name.

Step 2: Provision the Frontend

cd ../frontend_terraform
terraform init


Provide the alb_dns_name when prompted (or via a .tfvars file) to establish the reverse proxy routing rules, then apply:

terraform apply -auto-approve


🔐 CI/CD Pipeline Secrets

To enable the automated GitHub Actions pipelines, the following secrets must be added to the respective application repositories:

Backend Repository Secrets

Secret Name

Description

AWS_ACCESS_KEY_ID

AWS IAM User access key for Terraform/Deployment.

AWS_SECRET_ACCESS_KEY

AWS IAM User secret key.

ECR_REPOSITORY

Name of the Amazon ECR repository (from Terraform output).

ECS_CLUSTER_NAME

Name of the ECS cluster.

ECS_SERVICE_NAME

Name of the ECS service managing the tasks.

ECS_TASK_FAMILY

The family name of the ECS Task Definition.

DOCKER_PASSWORD

Docker Hub Personal Access Token (prevents rate limiting).

DOCKER_USERNAME

Docker Hub username.

Frontend Repository Secrets

Secret Name

Description

AWS_ACCESS_KEY_ID

AWS IAM User access key.

AWS_SECRET_ACCESS_KEY

AWS IAM User secret key.

SECRET_S3_BUCKET_NAME

The private S3 bucket name (from Terraform output).

SECRET_CLOUDFRONT_DIST_ID

The CloudFront Distribution ID (used for cache invalidation).

🛠️ State Management

Currently configured for local state execution (terraform.tfstate). For multi-developer collaboration, this repository is ready to be upgraded to an Amazon S3 backend with DynamoDB state locking.