provider "aws" {
    profile   = var.aws_profile
    region    = var.aws_region
}

terraform {
  backend "local" {
    path = "../state/vpc/terraform.tfstate"
  }
}

resource "aws_vpc" "notes" {
  cidr_block       = var.vpc_cidr
  // Commenting these out solved this issue:
  // 
  // The VPC vpc-09c034a9fa6822106 in region us-west-2 has already been associated with the hosted zone Z05400872H500XXEPLD0D with the same domain name. (Service: AmazonRoute53; Status Code: 400; Error Code: ConflictingDomainExists; Request ID: 0ec590ea-9a57-4287-a61e-92099634eab3; Proxy: null)
  //
  // enable_dns_support = var.enable_dns_support
  // enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.notes.id

  tags = {
    Name =  "${var.project_name}-IGW"
  }
}

resource "aws_route" "route-public" {
  route_table_id         = aws_vpc.notes.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.notes.id
  cidr_block = var.public1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-net-public1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.notes.id
  cidr_block = var.public2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-net-public2"
  }
}

/* resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.notes.id
  cidr_block = var.private1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-net-private1"
  }
} */

/* resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.notes.id
  cidr_block = var.private2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-net-private2"
  }
} */

resource "aws_eip" "gw" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name =  "${var.project_name}-EIP"
  }
}

resource "aws_nat_gateway" "gw" {
  subnet_id     = aws_subnet.public1.id
  allocation_id = aws_eip.gw.id

  tags = {
    Name =  "${var.project_name}-NAT"
  }
}

/* resource "aws_route_table" "private" {
  vpc_id = aws_vpc.notes.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name =  "${var.project_name}-rt-private"
  }
} */

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_vpc.notes.main_route_table_id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_vpc.notes.main_route_table_id
}

/* resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
} */

/* resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
} */
