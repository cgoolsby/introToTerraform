provider "http" {}
provider "aws" {
  region = "us-west-2"#TD
}

resource "aws_vpc" "EXAMPLE-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

variable "key_name" {}
variable "count" {}

resource "aws_instance" "web" {
  count = "${var.count}"

  instance_type = "t2.micro"
  ami           = "${data.aws_ami.ubuntu.id}"
  
  key_name = "${var.key_name}"	
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"	
  vpc_security_group_ids = ["${aws_security_group.TotallyOpen.id}"]	
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

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.EXAMPLE-vpc.id}"
}

resource "aws_subnet" "public" {
  count = "${var.count}"
  vpc_id = "${aws_vpc.EXAMPLE-vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  tags {
    Name = "Public Subnet-[count.index}"
  }
}

#resource "aws_route_table" "public-rt" {
#  vpc_id = "${aws_vpc.EXAMPLE-vpc.id}"
#  depends_on = ["aws_internet_gateway.igw"]
#  tags {
#    Name = "${terraform.workspace}-public-rt"
#  }
#}
#resource "aws_route" "intoInstance" {
#  route_table_id = "${aws_route_table.public-rt.id}"
#  depends_on = ["aws_route_table.public-rt"]
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id = "${aws_internet_gateway.igw.id}"
#}
#resource "aws_route_table_association" "public-rt" {
#  subnet_id = "${aws_subnet.public.id}"
#  route_table_id = "${aws_route_table.public-rt.id}"
#}
resource "aws_route_table" "public" {
  vpc_id       = "${aws_vpc.EXAMPLE-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}
resource "aws_security_group" "TotallyOpen" {
  vpc_id = "${aws_vpc.EXAMPLE-vpc.id}"
  name = "TotallyOpenSG"
}
resource "aws_security_group_rule" "totallyOpenIN"{
  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.TotallyOpen.id}"
}
resource "aws_security_group_rule" "totallyOpenOUT"{
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.TotallyOpen.id}"
}
data "aws_availability_zones" "available" {}
