resource "aws_eip" "nat_eip" {
  instance = aws_instance.nat_instance.id
}