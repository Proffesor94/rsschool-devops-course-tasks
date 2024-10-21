resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnets[0].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnets[0].id
  route_table_id = aws_route_table.private_route_table.id
}