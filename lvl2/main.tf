provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "EXAMPLE-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_instance" "web" {
  count = 1

  instance_type = "t2.micro"
  ami           = "${data.aws_ami.ubuntu.id}"
}

data "aws_ami" "ubuntu" {
    most_recent = true
filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
}

filter {
    name   = "virtualization-type"
    values = ["hvm"]
}

owners = ["099720109477"] # Canonical
}
