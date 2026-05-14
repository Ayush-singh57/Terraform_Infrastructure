variable "aws_region" {
  description = "The AWS region to deploy the infrastructure in"
  type        = string
}

variable "mongo_uri" {
  description = "MongoDB Connection String"
  type        = string
  sensitive   = true
}

variable "app_port" {
  description = "The port the Node.js app is running on (spotted 4000 in terminal)"
  type        = number
}