resource "aws_vpc" "task_3_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "task_3_vpc"
  }
}