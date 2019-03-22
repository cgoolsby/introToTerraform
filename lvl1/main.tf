provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "EXAMPLE-vpc" {
  cidr_block = "10.0.0.0/16"
}
