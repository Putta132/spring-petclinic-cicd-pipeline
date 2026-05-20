terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── Security Group ────────────────────────────────────────────────────────────
# Single SG — opens all required ports for Jenkins, SonarQube, Nexus, Tomcat
resource "aws_security_group" "cicd" {
  name        = "cicd-pipeline-sg"
  description = "Security group for CI/CD pipeline EC2 instances"

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Nexus"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Tomcat"
    from_port   = 8085
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "cicd-pipeline-sg" }
}

# ── 4 EC2 Instances ───────────────────────────────────────────────────────────

resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.cicd.id]
  user_data              = file("${path.module}/../scripts/jenkins-setup.sh")
  tags                   = { Name = "jenkins" }
}

resource "aws_instance" "sonarqube" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.cicd.id]
  user_data              = file("${path.module}/../scripts/sonarqube-setup.sh")
  tags                   = { Name = "sonarqube" }
}

resource "aws_instance" "nexus" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.cicd.id]
  user_data              = file("${path.module}/../scripts/nexus-setup.sh")
  tags                   = { Name = "nexus" }
}

resource "aws_instance" "tomcat" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.cicd.id]
  user_data              = file("${path.module}/../scripts/tomcat-setup.sh")
  tags                   = { Name = "tomcat" }
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "jenkins_url"   { value = "http://${aws_instance.jenkins.public_ip}:8080" }
output "sonarqube_url" { value = "http://${aws_instance.sonarqube.public_ip}:9000" }
output "nexus_url"     { value = "http://${aws_instance.nexus.public_ip}:8081" }
output "tomcat_url"    { value = "http://${aws_instance.tomcat.public_ip}:8085" }
