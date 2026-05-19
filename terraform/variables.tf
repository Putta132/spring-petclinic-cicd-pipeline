variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "petclinic-cicd"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI (ap-south-1)"
  type        = string
  default     = "ami-0f5ee92e2d63afc18"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your IP in CIDR notation for SSH access — e.g. 203.0.113.10/32"
  type        = string
}
