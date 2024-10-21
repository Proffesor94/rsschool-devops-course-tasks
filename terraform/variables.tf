variable "aws_region" {
  description = "AWS provider region"
  type        = string
  default     = "eu-north-1"
}

variable "aws_linux_ami" {
  description = "Ubuntu Server 24.04 LTS (HVM)"
  type        = string
  default     = "ami-089146c5626baa6bf"
}

variable "aws_linux_instance_type" {
  description = "AWS main server instance type"
  type        = string
  default     = "t3.micro"
}

variable "aws_s3_bucket" {
  description = "AWS S3 bucket name"
  type        = string
  default     = "terraform-states-bucket01"
}

variable "aws_s3_key_path" {
  description = "AWS S3 state file path"
  type        = string
  default     = "state/terraform.tfstate"
}

variable "aws_iam_github_actions_role" {
  description = "IAM role for GitHub Actions"
  type        = string
  default     = "GithubActionsRole"
}

variable "vpc_cidr_block" {
  description = "AWS VPC's CIDR value"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cidr_public_subnet" {
  description = "Public Subnet CIDR values"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "cidr_private_subnet" {
  description = "Private Subnet CIDR values"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "eu_availability_zone" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]
}

variable "ssh_key_name" {
  description = "SSH key to access EC2 instances"
  type        = string
  default     = "aws-key" # Replace with your actual AWS key name
}

variable "aws_nat_ami" {
  description = "Amazon Linux 2 AMI (HVM)"
  type        = string
  default     = "ami-070fe338fb2265e00"
}

variable "k3s_token" {
  description = "K3S token"
  type        = string
  sensitive   = true
}