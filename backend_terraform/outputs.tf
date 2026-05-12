output "backend_url" {
  description = "The URL of the Backend Load Balancer (Use this in your React frontend .env file)"
  value       = "http://${module.backend_ecs.alb_dns_name}"
}

output "ecr_repository_uri" {
  description = "The URI of the Elastic Container Registry"
  value       = module.backend_ecs.ecr_repository_url
}

# FOR GITHUB SECRETS
output "SECRET_ECR_REPOSITORY" {
  description = "Name the GitHub Secret exactly: ECR_REPOSITORY"
  value       = "nodejs-backend-repo"
}

output "SECRET_ECS_CLUSTER_NAME" {
  description = "Name the GitHub Secret exactly: ECS_CLUSTER_NAME"
  value       = "nodejs-backend-cluster"
}

output "SECRET_ECS_SERVICE_NAME" {
  description = "Name the GitHub Secret exactly: ECS_SERVICE_NAME"
  value       = "nodejs-backend-service"
}

output "SECRET_ECS_TASK_FAMILY" {
  description = "Name the GitHub Secret exactly: ECS_TASK_FAMILY"
  value       = "nodejs-backend-task"
}