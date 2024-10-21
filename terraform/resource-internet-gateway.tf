resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.task_3_vpc.id
  tags = {
    Name = "task_3_igw"
  }
}