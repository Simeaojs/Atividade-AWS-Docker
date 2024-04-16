#internet gateway
resource "aws_internet_gateway" "igw" {
  count  = 1
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw-project-docker ${count.index}-${var.environment}"
  }
}

#public route table
resource "aws_route_table" "rt-public_a" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Route Table Public_A ${var.environment}"
  }
}

resource "aws_route_table" "rt-public_b" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Route Table Public_B ${var.environment}"
  }
}

# public route table association
resource "aws_route_table_association" "association-rt-public_a" {
  subnet_id      = aws_subnet.subnet-public-a.id
  route_table_id = aws_route_table.rt-public_a.id
}

resource "aws_route_table_association" "association-rt-public_b" {
  subnet_id      = aws_subnet.subnet-public-b.id
  route_table_id = aws_route_table.rt-public_b.id
}

# public routing for subnet A outbound to the internet
resource "aws_route" "rota_default_public_a" {
  route_table_id         = aws_route_table.rt-public_a.id
  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.igw[0].id
}
# public routing for subnet B outbound to the internet 
resource "aws_route" "rota_default_public_b" {
  route_table_id         = aws_route_table.rt-public_b.id
  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.igw[0].id
}

#elastic ip
resource "aws_eip" "nat_gateway_eip" {
  count = 1
  tags = {
    Name = "elastic_ip_${count.index} ${var.environment}"
  }
}
#nat gateway
resource "aws_nat_gateway" "nat_gateway" {
  count         = 1
  allocation_id = aws_eip.nat_gateway_eip[count.index].id
  subnet_id     = aws_subnet.subnet-public-a.id
  tags = {
    Name = "nat_gateway_${count.index} ${var.environment}"
  }
}

#private route table
resource "aws_route_table" "rt-private_a" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Route Table Private_A ${var.environment}"
  }
}

resource "aws_route_table" "rt-private_b" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Route Table Private_B ${var.environment}"
  }
}

# private route table association 
resource "aws_route_table_association" "association-rt-private_a" {
  subnet_id      = aws_subnet.subnet-private-a.id
  route_table_id = aws_route_table.rt-private_a.id
}

resource "aws_route_table_association" "association-rt-private_b" {
  subnet_id      = aws_subnet.subnet-private-b.id
  route_table_id = aws_route_table.rt-private_b.id
}

# Private routing for subnet A outbound to the internet
resource "aws_route" "rota_internet_private_a" {
  route_table_id         = aws_route_table.rt-private_a.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.nat_gateway[0].id
}

# Private routing for subnet B outbound to the internet.
resource "aws_route" "rota_internet_private_b" {
  route_table_id         = aws_route_table.rt-private_b.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.nat_gateway[0].id
}
