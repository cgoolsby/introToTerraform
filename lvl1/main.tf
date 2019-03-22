provider "http" {}
provider "aws" {
  region = "us-west-2"#TD
  access_key = "${var.access}"
  secret_key = "${var.secret}"
}

resource "aws_vpc" "EXAMPLE-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}
