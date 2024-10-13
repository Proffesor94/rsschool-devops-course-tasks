resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.task_2_vpc.id

  tags = {
    Name = "task_2_igw"
  }
}