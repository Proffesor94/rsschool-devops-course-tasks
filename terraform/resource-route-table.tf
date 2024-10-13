resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.task_2_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "Public Route Table"
    Project = "Task 2"
  }
}

resource "aws_route_table" "private_route_table" {
  count  = length(var.cidr_private_subnet)
  vpc_id = aws_vpc.task_2_vpc.id

  tags = {
    Name    = "Private Route Table ${count.index + 1}"
    Project = "Task 2"
  }
}

resource "aws_route" "private_route" {
  count                  = length(var.cidr_private_subnet)
  route_table_id         = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat_instance.primary_network_interface_id
}
