# VPC PRINCIPAL
resource "aws_vpc" "vpc" {
  cidr_block           = "10.110.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-project-docker"
  }
}

# SUB REDE PUBLICA
resource "aws_subnet" "subnet-public-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.110.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-public-a"
  }
}

resource "aws_subnet" "subnet-public-b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.110.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet-public-b"
  }
}

# SUB REDE PRIVADA
resource "aws_subnet" "subnet-private-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.110.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-private-a"
  }
}

resource "aws_subnet" "subnet-private-b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.110.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet-private-b"
  }
}
