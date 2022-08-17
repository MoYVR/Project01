terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Region

provider "aws" {
  region = "us-east-1"
}

# VPC

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.env_code
  }
}

# Public_Subnet 1&2

resource "aws_subnet" "public" {
  count      = length(var.public_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_cidr[count.index]

  tags = {
    Name = "${var.env_code}-Public${count.index}"
  }
}

# Private_Subnet 1&2

resource "aws_subnet" "private" {
  count      = length(var.private_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_cidr[count.index]

  tags = {
    Name = "${var.env_code}-private${count.index}"
  }
}

# IGW
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.env_code
  }
}

# EIP
resource "aws_eip" "nat" {
  count = length(var.eip)
  vpc   = true

}



# NAT Gateway

resource "aws_nat_gateway" "main" {
  count         = length(var.nat_gateway)
  allocation_id = var.eip
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.env_code}-gw NAT${count.index}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table

resource "aws_route_table" "public" {
  count  = length(var.public_route_table)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.env_code}-public${count.index}"
  }
}

# Private Route Table

resource "aws_route_table" "private" {
  count  = length(var.private_route_table)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.env_code}-private${count.index}"
  }
}

# Public Route Tables Association

resource "aws_route_table_association" "public" {
  count          = length(var.public_route_table_association)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

#Private Route Table Association

resource "aws_route_table_association" "private" {
  count          = length(var.private_route_table_association)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


# Public EC2

resource "aws_instance" "public" {
  ami                         = "ami-090fa75af13c156b4"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.0.id
  key_name                    = "moz"

  tags = {
    Name = "${var.env_code}-Public"
  }
}

# Private EC2

resource "aws_instance" "private" {
  ami           = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.0.id
  key_name      = "moz"


  tags = {
    Name = "${var.env_code}-Private"
  }
}

 