resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true
  
}

resource "aws_subnet" "public_blue" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true          

}

resource "aws_subnet" "private_blue" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "eu-central-1a"

}

resource "aws_subnet" "public_green" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_green" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.20.0/24"
  availability_zone = "eu-central-1b"

}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat_blue" {
  domain = "vpc"
}

resource "aws_eip" "nat_green" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_blue" {
  allocation_id = aws_eip.nat_blue.id
  subnet_id = aws_subnet.public_blue.id

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat_green" {
  allocation_id = aws_eip.nat_green.id
  subnet_id = aws_subnet.public_green.id

  depends_on = [aws_internet_gateway.gw]
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

}

resource "aws_route_table_association" "public_blue" {
  subnet_id = aws_subnet.public_blue.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_green" {
  subnet_id = aws_subnet.public_green.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_blue_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_blue.id
  }

}

resource "aws_route_table_association" "private_blue" {
  subnet_id = aws_subnet.private_blue.id
  route_table_id = aws_route_table.private_blue_rt.id
}

resource "aws_route_table" "private_green_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_green.id
  }

}

resource "aws_route_table_association" "private_green" {
  subnet_id = aws_subnet.private_green.id
  route_table_id = aws_route_table.private_green_rt.id
}