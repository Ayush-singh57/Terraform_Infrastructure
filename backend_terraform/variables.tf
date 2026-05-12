variable "aws_region" {
  description = "The AWS region to deploy the infrastructure in"
  type        = string
  default     = "ap-south-1" 
}

variable "mongo_uri" {
  description = "MongoDB Connection String"
  type        = string
  default     = "mongodb+srv://ayush221018it_db_user:6fc4sZ9IZU707VN2@cluster0.w4v1jkr.mongodb.net/test"
}

variable "app_port" {
  description = "The port the Node.js app is running on (spotted 4000 in terminal)"
  type        = number
  default     = 4000
}