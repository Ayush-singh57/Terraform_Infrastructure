<div align="center">

```
    _   __  ______   ___   ______ ____  _   ______
   / | / / / ____/  /   | /_  __// __ \/ | / / __ |
  /  |/ / / __/    / /| |  / /  / / / /  |/ / / / /
 / /|  / / /___   / ___ | / /  / /_/ / /|  / /_/ /
/_/ |_/ /_____/  /_/  |_|/_/   \____/_/ |_/\____/
```

# ☁️ Amazona E-Commerce Infrastructure

**Infrastructure as Code for the Amazona MERN-Stack Platform**

[![Terraform](https://img.shields.io/badge/Terraform-≥1.0-7B42BC?style=flat-square&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?style=flat-square&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![ECS Fargate](https://img.shields.io/badge/ECS-Fargate-FF9900?style=flat-square&logo=amazonaws&logoColor=white)](https://aws.amazon.com/fargate/)
[![CloudFront](https://img.shields.io/badge/CloudFront-CDN-FF9900?style=flat-square&logo=amazonaws&logoColor=white)](https://aws.amazon.com/cloudfront/)
[![Pattern](https://img.shields.io/badge/Pattern-Dedicated%20IaC%20Repo-0080FF?style=flat-square)](https://developer.hashicorp.com/terraform/tutorials)

> This repository strictly follows the **Dedicated Infrastructure Repository** pattern — separating Terraform configurations from application code to ensure safer deployments, decoupled CI/CD pipelines, and isolated state management.

</div>

---

## 🏗️ Architecture Overview

The infrastructure is divided into **two distinct domains** to minimize blast radius and ensure independent scalability.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Internet / Users                             │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Amazon CloudFront (CDN)                          │
│                                                                     │
│    ┌─────────────────────┐       ┌──────────────────────────────┐  │
│    │   Path: /*          │       │   Path: /api/*               │  │
│    │   → S3 React SPA    │       │   → Backend ALB (Proxy)      │  │
│    └─────────────────────┘       └──────────────────────────────┘  │
└──────────────┬────────────────────────────────┬─────────────────────┘
               │                                │
               ▼                                ▼
┌──────────────────────────┐    ┌───────────────────────────────────┐
│    Amazon S3 (Private)   │    │        Amazon VPC                 │
│                          │    │  ┌─────────────────────────────┐  │
│  React Static Assets     │    │  │   Application Load Balancer │  │
│  (OAC Protected)         │    │  └──────────────┬──────────────┘  │
│                          │    │                 │                  │
└──────────────────────────┘    │  ┌──────────────▼──────────────┐  │
                                │  │     ECS Fargate Cluster      │  │
                                │  │   (Node.js / Express API)   │  │
                                │  └─────────────────────────────┘  │
                                │                                    │
                                │  ┌─────────────────────────────┐  │
                                │  │     Amazon ECR              │  │
                                │  │   (Docker Image Registry)   │  │
                                │  └─────────────────────────────┘  │
                                └───────────────────────────────────┘
```

---

### 1. 🖥️ Backend Infrastructure (`/backend_terraform`)

Provisions the networking and compute resources required to run the Node.js/Express API.

| Resource | Service | Purpose |
|---|---|---|
| 🌐 | **Amazon VPC** | Custom virtual network with public/private subnets |
| 🐳 | **Amazon ECS (Fargate)** | Serverless container orchestration for the Node.js backend |
| 📦 | **Amazon ECR** | Container registry for storing backend Docker images |
| ⚖️ | **Application Load Balancer** | Distributes incoming API traffic across ECS tasks |

---

### 2. 🌍 Frontend Infrastructure (`/frontend_terraform`)

Provisions the secure, globally distributed hosting environment for the React SPA.

| Resource | Service | Purpose |
|---|---|---|
| 🗂️ | **Amazon S3** | Private bucket storing the compiled React static assets |
| 🚀 | **Amazon CloudFront** | Global CDN serving the application over HTTPS |
| 🔒 | **Origin Access Control (OAC)** | Secures S3 — only accessible via CloudFront |

---

## 🔐 The CloudFront Reverse Proxy

To solve browser **Mixed Content** (HTTP vs HTTPS) security blocks — without requiring a custom domain for the ALB — this architecture uses **CloudFront as a reverse proxy**.

```
  User Request
       │
       ▼
  CloudFront Distribution
  ┌────────────────────────────────────────────────┐
  │                                                │
  │   /*       ──────────────▶  S3 Bucket          │
  │            (React SPA)                         │
  │                                                │
  │   /api/*   ──────────────▶  Backend ALB        │
  │            (Node.js API)   (HTTPS tunnel)      │
  │                                                │
  └────────────────────────────────────────────────┘
```

This pattern:
- ✅ Eliminates mixed-content browser errors
- ✅ Avoids the cost of a custom ACM certificate on the ALB
- ✅ Keeps all traffic under a single HTTPS origin
- ✅ Enables path-based routing at the CDN layer

---

## 📁 Repository Structure

```
amazona-infrastructure/
│
├── 📂 backend_terraform/
│   ├── main.tf          # ECS, VPC, ALB configurations
│   ├── variables.tf     # Backend input variables
│   └── outputs.tf       # Outputs: alb_dns_name
│
└── 📂 frontend_terraform/
    ├── main.tf          # S3, CloudFront, OAC configurations
    ├── variables.tf     # Frontend input variables
    ├── outputs.tf       # Outputs: cloudfront_domain_name
    └── modules/
        └── cdn/         # Reusable CloudFront/CDN modules
```

---

## 🚀 Deployment Order

> ⚠️ **Critical:** The environments are decoupled and **must be applied in order**. The Frontend CloudFront distribution requires the Backend ALB's DNS URL to configure the `/api/*` reverse proxy.

### Step 1 — Provision the Backend

```bash
cd backend_terraform
terraform init
terraform apply -auto-approve
```

Wait for completion, then **copy the output value:**

```
Outputs:
  alb_dns_name = "amazona-alb-XXXXXXXXXX.us-east-1.elb.amazonaws.com"
```

---

### Step 2 — Provision the Frontend

```bash
cd ../frontend_terraform
terraform init
```

Before applying, pass the `alb_dns_name` into your variables so CloudFront knows where to route API traffic:

```bash
terraform apply -auto-approve \
  -var="alb_dns_name=amazona-alb-XXXXXXXXXX.us-east-1.elb.amazonaws.com"
```

Or set it in `terraform.tfvars`:

```hcl
# frontend_terraform/terraform.tfvars
alb_dns_name = "amazona-alb-XXXXXXXXXX.us-east-1.elb.amazonaws.com"
```

Then run:

```bash
terraform apply -auto-approve
```

---

## 🛠️ State Management

| Mode | Status | Notes |
|---|---|---|
| **Local** | ✅ Current | `terraform.tfstate` stored locally per module |
| **Remote (S3 + DynamoDB)** | 🔜 Recommended for teams | Enables state locking and collaboration |

To migrate to a remote backend, add the following to each module's `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "amazona-terraform-state"
    key            = "backend/terraform.tfstate"   # or frontend/
    region         = "us-east-1"
    dynamodb_table = "amazona-terraform-locks"
    encrypt        = true
  }
}
```

---

## 🧩 Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.0`
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate IAM permissions
- Docker (for building and pushing backend images to ECR)

---

<div align="center">

Built with ☁️ on AWS &nbsp;•&nbsp; IaC by Terraform &nbsp;•&nbsp; Part of the **Amazona** platform

</div>