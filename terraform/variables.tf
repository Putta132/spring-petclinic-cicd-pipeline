variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI (ap-south-1)"
  type        = string
  default     = "ami-0f5ee92e2d63afc18"
}

variable "instance_type" {
  description = "EC2 instance type for all servers"
  type        = string
  default     = "c7i.large"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}
