variable "name" {
  description = "the name of your stack, e.g. \"lynx\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"dev\""
}

variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
}

variable "availability_zones" {
  description = "a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both private_subnets and public_subnets have to be defined as well"
}

variable "cidr" {
  description = "The CIDR block for the VPC."
}
variable "private_subnets_db" {
  description = "a list of CIDRs for private subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
}

variable "private_subnets" {
  description = "a list of CIDRs for private subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
}

variable "public_subnets" {
  description = "a list of CIDRs for public subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
}

variable "kubeconfig_path" {
  description = "Path where the config file for kubectl should be written to"
  default     = "~/.kube"
}

variable "k8s_version" {
  description = "kubernetes version"
  default = ""
}
variable "data_username" {
  description = "The VPC the cluser should be created in"
}

variable "data_password" {
  description = "The VPC the cluser should be created in"
}