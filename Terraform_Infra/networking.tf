data "aws_vpc" "target_peering_vpc" {
  id = "vpc-0f4d614772ca8d3f0"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main_vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_IGW"
  }
}

resource "aws_route" "internet_access" {
 route_table_id         = aws_vpc.main_vpc.main_route_table_id
 destination_cidr_block = "0.0.0.0/0"
 gateway_id             = aws_internet_gateway.gw.id
}


resource "aws_subnet" "sub_1_ec2_lb" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
  tags = {
    Name = "main_subnet"
  }
}

resource "aws_vpc_peering_connection" "vpc_gitlab_runner" {
  peer_vpc_id   = data.aws_vpc.target_peering_vpc.id
  vpc_id        = aws_vpc.main_vpc.id

  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_gitlab_runner.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}


# Create a route for the second VPC's CIDR block in the first VPC's route table
resource "aws_route" "main_vpc_route_to_k8s" {
  route_table_id            = "rtb-0cb9914b16f6618ed"
  destination_cidr_block    = "10.0.0.0/16" # Replace with the other VPC's CIDR block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_gitlab_runner.id
}



# Create a route for the first VPC's CIDR block in the second VPC's route table
resource "aws_route" "vpc2_route" {
  route_table_id            = aws_vpc.main_vpc.main_route_table_id
  destination_cidr_block    = "172.31.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_gitlab_runner.id
}