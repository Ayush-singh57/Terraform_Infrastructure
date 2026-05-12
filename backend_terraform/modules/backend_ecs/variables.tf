variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "app_port" { type = number }
variable "mongo_uri" { type = string }

variable "app_name" {
  type    = string
  default = "nodejs-backend"
}