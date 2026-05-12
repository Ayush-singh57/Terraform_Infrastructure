variable "aws_region" {
  description = "The AWS region to deploy the infrastructure in"
  type        = string
  default     = "ap-south-1" # Mumbai!
}

variable "app_name" {
  description = "Name of the frontend application"
  type        = string
  default     = "react-frontend"
}