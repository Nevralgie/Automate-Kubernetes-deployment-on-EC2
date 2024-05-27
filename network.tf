resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "Nat_eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.sub_1_ec2_lb.id
  tags = {
    Name = "NAT_GW"
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_vpc.main_vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# The ignore_changes and delete lifecycle blocks are used to prevent Terraform from recreating the route when it's deleted.
resource "aws_route" "delete_internet_access" {
  route_table_id         = aws_vpc.main_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
  lifecycle {
    ignore_changes = [gateway_id]
  }
  timeouts {
    delete = "5m"
  }
}