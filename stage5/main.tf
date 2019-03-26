provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "EXAMPLE-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

variable "key_name" {}

resource "aws_instance" "web" {
  count = 1

  instance_type = "t2.micro"
  ami           = "${data.aws_ami.ubuntu.id}"
  
  key_name = "${var.key_name}"	
  subnet_id = "${aws_subnet.public.id}"	
  vpc_security_group_ids = ["${aws_security_group.Example.id}"]	
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
  count = 1
  vpc_id = "${aws_vpc.EXAMPLE-vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags {
    Name = "Public Subnet-0"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.EXAMPLE-vpc.id}"
  depends_on = ["aws_internet_gateway.igw"]
  tags {
    Name = "${terraform.workspace}-public-rt"
  }
}
resource "aws_route" "intoInstance" {
  route_table_id = "${aws_route_table.public-rt.id}"
  depends_on = ["aws_route_table.public-rt"]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.igw.id}"
}
resource "aws_route_table_association" "public-rt" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}
data "http" "ip-address" {
  url = "http://ipv4.icanhazip.com"
}

locals  {
  ipAddress = "${chomp(data.http.ip-address.body)}/32"
}
resource "aws_security_group" "Example" {
  vpc_id = "${aws_vpc.EXAMPLE-vpc.id}"
  name = "TotallyOpenSG"
}
resource "aws_security_group_rule" "sshIn"{
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["${local.ipAddress}"]
  security_group_id = "${aws_security_group.Example.id}"
}
resource "aws_security_group_rule" "httpIn"{
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["${local.ipAddress}"]
  security_group_id = "${aws_security_group.Example.id}"
}
resource "aws_security_group_rule" "JupyterIn"{
  type = "ingress"
  from_port = 8888
  to_port = 8888
  protocol = "tcp"
  cidr_blocks = ["${local.ipAddress}"]
  security_group_id = "${aws_security_group.Example.id}"
}
resource "aws_security_group_rule" "OpenEgress"{
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["${local.ipAddress}"]
  security_group_id = "${aws_security_group.Example.id}"
}
data "aws_availability_zones" "available" {}

output "ip_of_instance" {
  value = "${aws_instance.web.public_ip}"
}
