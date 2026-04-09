variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type_web" {
  description = "Instance type for web/bastion servers"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_db" {
  description = "Instance type for DB server"
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair"
  type        = string
}

variable "my_ip" {
  description = "IP address with /32 (e.g. 1.2.3.4/32)"
  type        = string
}