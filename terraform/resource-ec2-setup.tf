resource "aws_instance" "ec2_in_public_subnet" {
  count         = length(var.cidr_public_subnet)
  ami           = var.aws_linux_ami
  instance_type = var.aws_linux_instance_type
  key_name      = var.ssh_key_name

  subnet_id              = element(aws_subnet.public_subnets[*].id, count.index)
  vpc_security_group_ids = [aws_security_group.security_group.id]

  tags = {
    Name = "EC2 for Public Subnet #${count.index + 1}"
  }
}

data "aws_subnet" "public_subnet" { 
  count = length(var.cidr_public_subnet)
  
  filter {
    name   = "tag:Name"
    values = ["Public Subnet #${count.index + 1}"]
  }

  depends_on = [
    aws_route_table_association.public_subnet_association
  ]
}

resource "aws_instance" "bastion" {
  ami           = var.aws_linux_ami
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnets[0].id
  key_name      = var.ssh_key_name
  associate_public_ip_address = true
  
  tags = {
    Name    = "Bastion Host"
    Owner   = "Pavel Shumilin"
    Project = "Task 2"
  }

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
}

resource "aws_instance" "private_instance" {
  count         = length(var.cidr_private_subnet)
  ami           = var.aws_linux_ami
  instance_type = var.aws_linux_instance_type
  subnet_id     = element(aws_subnet.private_subnets[*].id, count.index)
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.private_instance_sg.id]

  tags = {
    Name = "Private EC2 Instance #${count.index + 1}"
  }
}

resource "aws_instance" "nat_instance" {
  ami                    = var.aws_nat_ami
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnets[0].id
  key_name               = var.ssh_key_name
  associate_public_ip_address = true

  source_dest_check = false
  
  tags = {
    Name    = "NAT Instance"
    Project = "Task 2"
  }

  vpc_security_group_ids = [aws_security_group.nat_instance_sg.id]
}