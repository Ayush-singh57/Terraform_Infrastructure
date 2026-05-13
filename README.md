<div align="center">

<br/>


### ☁️ E-Commerce Cloud Infrastructure

** AWS Infrastructure Repository**

<br/>

[![Terraform](https://img.shields.io/badge/Terraform-≥_1.0-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-ap--south--1-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![ECS Fargate](https://img.shields.io/badge/ECS-Fargate-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/fargate/)
[![CloudFront](https://img.shields.io/badge/CloudFront-CDN_+_Proxy-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/cloudfront/)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com/atlas)

<br/>

</div>

---

## 🚀 Overview

This repository contains the **completely decoupled** AWS cloud infrastructure for the **Amazona** e-commerce platform.

By strictly following the **Dedicated Infrastructure Repository** pattern, the Terraform configurations are isolated from the application code. This ensures:

- 🛡️ **Zero-downtime deployments** — infra changes never block app releases
- 🔁 **Independent CI/CD pipelines** — app and infra ship on separate cadences
- 💥 **Minimal blast radius** — a broken infra change never takes down application code

---

## 📊 Architecture & Traffic Flow

The following diagram illustrates the full lifecycle of a user request — showing how the **CloudFront Reverse Proxy** securely routes traffic to either the static frontend or the dynamic serverless backend.

```
                          ┌─────────────────────────────────────────────────────────┐
                          │              AWS Cloud  (ap-south-1)                    │
                          │                                                         │
  🧑‍💻 User Browser          │   ┌──────────────────────────────────────────────────┐  │
       │                  │   │         🌐 CloudFront CDN  (Reverse Proxy)         │  │
       │  HTTPS Request   │   │                                                    │  │
       └──────────────────┼──▶│   Path: /*          Path: /api/*                  │  │
                          │   │   (OAC Protected)   (Secure Tunnel)               │  │
                          │   └────────┬─────────────────────┬────────────────────┘  │
                          │            │                     │                        │
                          │            ▼                     ▼                        │
                          │   ┌─────────────────┐  ┌────────────────────────────┐   │
                          │   │ ── Frontend ──  │  │ ──────── Backend ────────  │   │
                          │   │                 │  │                            │   │
                          │   │  📦 Private S3  │  │  🔀 App Load Balancer     │   │
                          │   │  (React SPA)    │  │         │  Port 80         │   │
                          │   │                 │  │         ▼                  │   │
                          │   └─────────────────┘  │  ⚙️  ECS Fargate          │   │
                          │                        │     (Node.js/Express)     │   │
                          │                        └────────────┬───────────────┘   │
                          └─────────────────────────────────────┼───────────────────┘
                                                                │  Mongoose Auth
                                                                ▼
                                                      🍃 MongoDB Atlas
```

> **The Reverse Proxy Advantage:** This design allows the backend ALB to piggyback on CloudFront's default wildcard SSL certificate, providing end-to-end encryption and a unified API domain (`d3vno...cloudfront.net/api`) out of the box — **without purchasing custom domains**.

---

## 🏗️ Infrastructure Components

The environment is split into two **distinct, independently manageable** domains.

### 🖥️ Backend Domain

| Component | AWS Service | Purpose |
|---|---|---|
| **Networking** | VPC, Subnets, NAT | Custom virtual network isolating compute resources. Private subnets protect the API servers, while NAT Gateways allow outbound image pulls. |
| **Compute** | ECS (Fargate) | Fully serverless container orchestration running Node.js. No EC2 instances to manage or patch. |
| **Registry** | ECR | Private container registry for securely storing backend Docker images. |
| **Traffic Routing** | ALB | Application Load Balancer distributes API traffic across healthy Fargate tasks. |

### 🌍 Frontend Domain

| Component | AWS Service | Purpose |
|---|---|---|
| **Storage** | S3 | Private bucket storing the compiled React static assets. |
| **CDN / Proxy** | CloudFront | Global CDN with edge caching. Also acts as the API reverse proxy. |
| **Security** | OAC | Origin Access Control locks down S3 so it can only be accessed via CloudFront. |

---

## 📁 Repository Structure

```
amazona-infrastructure/
│
├── 📂 backend_terraform/
│   ├── 📂 modules/
│   │   ├── 📂 backend_ecs/          # ECS Fargate + ECR module
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   │
│   │   └── 📂 networking/           # VPC, Subnets, NAT, Security Groups
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       └── variables.tf
│   │
│   ├── .terraform.lock.hcl
│   ├── main.tf                      # Root: wires modules together + ALB
│   ├── outputs.tf                   # Exposes: alb_dns_name
│   └── variables.tf                 # Configurable backend variables
│
├── 📂 frontend_terraform/
│   ├── 📂 modules/
│   │   └── 📂 frontend_cdn/         # CloudFront + S3 + OAC module
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       └── variables.tf
│   │
│   ├── .terraform.lock.hcl
│   ├── main.tf                      # Root: wires CDN module together
│   ├── outputs.tf                   # Exposes: cloudfront_domain_name
│   └── variables.tf                 # Configurable frontend variables
│
├── .gitignore
└── README.md
```

---

## ⚙️ Deployment Protocol

> ⚠️ **Strict Order Required.** Because the frontend CloudFront proxy dynamically routes `/api/*` traffic to the backend ALB, the environments **must** be applied in the following order.

### Step 1 — Provision the Backend

```bash
cd backend_terraform
terraform init
terraform apply -auto-approve
```

Wait for completion and **copy the outputted value:**

```
Outputs:
  alb_dns_name = "amazona-alb-XXXXXXXXXX.ap-south-1.elb.amazonaws.com"
```

---

### Step 2 — Provision the Frontend

```bash
cd ../frontend_terraform
terraform init
```

Provide the `alb_dns_name` when prompted (or via a `.tfvars` file) to establish the reverse proxy routing rules, then apply:

```bash
# Option A: inline variable
terraform apply -auto-approve \
  -var="alb_dns_name=amazona-alb-XXXXXXXXXX.ap-south-1.elb.amazonaws.com"

# Option B: tfvars file
echo 'alb_dns_name = "amazona-alb-XXXXXXXXXX.ap-south-1.elb.amazonaws.com"' \
  >> terraform.tfvars
terraform apply -auto-approve
```

---

## 🔐 CI/CD Pipeline Secrets

To enable the automated **GitHub Actions** pipelines, the following secrets must be configured in the respective application repositories.

### Backend Repository Secrets

| Secret Name | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS IAM User access key for Terraform/Deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM User secret key |
| `ECR_REPOSITORY` | Name of the Amazon ECR repository *(from Terraform output)* |
| `ECS_CLUSTER_NAME` | Name of the ECS cluster |
| `ECS_SERVICE_NAME` | Name of the ECS service managing the tasks |
| `ECS_TASK_FAMILY` | The family name of the ECS Task Definition |
| `DOCKER_PASSWORD` | Docker Hub Personal Access Token *(prevents rate limiting)* |
| `DOCKER_USERNAME` | Docker Hub username |

### Frontend Repository Secrets

| Secret Name | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS IAM User access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM User secret key |
| `SECRET_S3_BUCKET_NAME` | The private S3 bucket name *(from Terraform output)* |
| `SECRET_CLOUDFRONT_DIST_ID` | The CloudFront Distribution ID *(used for cache invalidation)* |

---

## 🛠️ State Management

| Mode | Status | Notes |
|---|---|---|
| **Local** | ✅ Active | `terraform.tfstate` stored locally per module |
| **Remote (S3 + DynamoDB)** | 🔜 Recommended | Enables state locking for multi-developer teams |

To upgrade to remote state, add the following backend block to each root `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "amazona-terraform-state"
    key            = "backend/terraform.tfstate"   # use "frontend/" for the other
    region         = "ap-south-1"
    dynamodb_table = "amazona-terraform-locks"
    encrypt        = true
  }
}
```

---

<div align="center">

</div>