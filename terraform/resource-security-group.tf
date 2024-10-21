resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH access to Bastion Host"
  vpc_id      = aws_vpc.task_3_vpc.id

  ingress {
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

  tags = {
    Name    = "Bastion Security Group"
    Project = "Task 3"
  }
}

resource "aws_security_group" "nat_instance_sg" {
  name        = "nat-instance-sg"
  description = "Allow traffic for NAT Instance"
  vpc_id      = aws_vpc.task_3_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "NAT Instance Security Group"
    Project = "Task 3"
  }
}

resource "aws_security_group" "k3s_sg" {
  name        = "k3s-sg"
  description = "Allow K3s communication"
  vpc_id      = aws_vpc.task_3_vpc.id
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = "k3s Security Group"
    Project = "Task 3"
  }
}