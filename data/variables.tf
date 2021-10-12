
variable "name" {
  description = "the name of stack, e.g. \"lynx\""
}

variable "environment" {
  description = "the name of environment, e.g. \"dev\""
}

variable "cidr" {
  description = "The CIDR block for the VPC."
}

variable "public_subnets" {
  description = "List of public subnets"
}

variable "private_subnets" {
  description = "List of private subnets"
}
variable "availability_zones" {
  description = "List of availability zones"
}

variable "vpc_id" {
  description = "The VPC the cluser should be created in"
}

variable "data_username" {
  description = "The VPC the cluser should be created in"
}

variable "data_password" {
  description = "The VPC the cluser should be created in"
}