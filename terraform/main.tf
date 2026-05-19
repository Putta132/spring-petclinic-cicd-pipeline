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

# ── VPC ───────────────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-public-subnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Security Groups ───────────────────────────────────────────────────────────

# Jenkins SG — port 8080 from anywhere, SSH from admin only
resource "aws_security_group" "jenkins" {
  name   = "${var.project_name}-jenkins-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins UI"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH from admin"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-jenkins-sg" }
}

# SonarQube SG — port 9000 from Jenkins SG only
resource "aws_security_group" "sonarqube" {
  name   = "${var.project_name}-sonarqube-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
    description     = "SonarQube from Jenkins only"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH from admin"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-sonarqube-sg" }
}

# Nexus SG — port 8081 from Jenkins SG only
resource "aws_security_group" "nexus" {
  name   = "${var.project_name}-nexus-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
    description     = "Nexus from Jenkins only"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH from admin"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-nexus-sg" }
}

# Tomcat SG — port 8080 from anywhere (public app)
resource "aws_security_group" "tomcat" {
  name   = "${var.project_name}-tomcat-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tomcat app — public access"
  }
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
    description     = "Tomcat deploy from Jenkins"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH from admin"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-tomcat-sg" }
}

# ── EC2 Instances ─────────────────────────────────────────────────────────────

resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"   # Jenkins needs at least 2GB RAM
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name               = var.key_name
  user_data              = file("${path.module}/../scripts/jenkins-setup.sh")
  tags                   = { Name = "${var.project_name}-jenkins" }
}

resource "aws_instance" "sonarqube" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"   # SonarQube needs at least 2GB RAM
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sonarqube.id]
  key_name               = var.key_name
  user_data              = file("${path.module}/../scripts/sonarqube-setup.sh")
  tags                   = { Name = "${var.project_name}-sonarqube" }
}

resource "aws_instance" "nexus" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.nexus.id]
  key_name               = var.key_name
  user_data              = file("${path.module}/../scripts/nexus-setup.sh")
  tags                   = { Name = "${var.project_name}-nexus" }
}

resource "aws_instance" "tomcat" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.tomcat.id]
  key_name               = var.key_name
  user_data              = file("${path.module}/../scripts/tomcat-setup.sh")
  tags                   = { Name = "${var.project_name}-tomcat" }
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "jenkins_url"   { value = "http://${aws_instance.jenkins.public_ip}:8080" }
output "sonarqube_url" { value = "http://${aws_instance.sonarqube.public_ip}:9000" }
output "nexus_url"     { value = "http://${aws_instance.nexus.public_ip}:8081" }
output "tomcat_url"    { value = "http://${aws_instance.tomcat.public_ip}:8080" }
