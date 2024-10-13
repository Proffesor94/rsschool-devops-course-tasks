# VPC Infrastructure with Terraform

This project uses Terraform to set up a VPC infrastructure in AWS, including public and private subnets, internet gateway, routing, security groups, and a bastion host.

## Infrastructure Overview

- VPC with 2 public and 2 private subnets across different Availability Zones
- Internet Gateway for public internet access
- NAT Instance for private subnet internet access
- Routing tables for public and private subnets
- Security Groups and Network ACLs
- Bastion host for secure access to private instances
- EC2 instances in both public and private subnets

## Prerequisites

- AWS account
- Terraform installed
- AWS CLI configured with appropriate credentials

## Project Structure
terraform/
├── main.tf
├── variables.tf
├── providers.tf
├── resource-vpc-setup.tf
├── resource-subnet.tf
├── resource-internet-gateway.tf
├── resource-route-table.tf
├── resource-route-table-association.tf
├── resource-security-group.tf
├── resource-ec2-setup.tf
├── outputs.tf
└── README.md


## Configuration Details

### VPC and Subnets

- VPC CIDR: 10.0.0.0/16
- Public Subnets: 10.0.1.0/24, 10.0.2.0/24
- Private Subnets: 10.0.3.0/24, 10.0.4.0/24

### Routing

- Public subnets route internet-bound traffic through the Internet Gateway
- Private subnets route internet-bound traffic through the NAT Instance

### Security

- Security Groups control inbound and outbound traffic at the instance level
- Network ACLs provide an additional layer of security at the subnet level

### NAT Configuration

A NAT Instance is used instead of a NAT Gateway for cost optimization. It's placed in the first public subnet and allows instances in private subnets to access the internet.

### Bastion Host

A bastion host is set up in the first public subnet to provide secure SSH access to instances in private subnets.

## Usage

1. Clone the repository
2. Navigate to the project directory
3. Initialize Terraform:
'''
terraform init
'''
4. Review the planned changes:
'''
terraform plan
'''
5. Apply the configuration:
'''
terraform apply
'''

## Verification

After applying the Terraform configuration:

1. Check the AWS Console to verify resource creation
2. Navigate to VPC -> Your VPCs -> your_VPC_name -> Resource map to view the VPC structure
3. Test connectivity between instances and to the internet as expected

## GitHub Actions

A GitHub Actions workflow is set up to automate the Terraform deployment process. It runs on push to the main branch and includes the following steps:

1. Checkout code
2. Set up Terraform
3. Initialize Terraform
4. Format check
5. Validate Terraform files
6. Plan Terraform changes
7. Apply Terraform changes (on manual approval)