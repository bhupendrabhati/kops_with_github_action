# Minimal VPC suitable for a demo. You can skip creating a VPC to use the AWS default VPC.
resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "idp-vpc-${var.env}" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.demo.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "idp-subnet-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.demo.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags = { Name = "idp-subnet-private-b" }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.demo.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}c"
  tags = { Name = "idp-subnet-private-c" }
}
