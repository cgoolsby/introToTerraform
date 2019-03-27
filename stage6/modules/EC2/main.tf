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


resource "aws_instance" "web" {
  count = "${var.extraEC2count}"

  instance_type = "${var.aws_instance_type}"
  ami           = "${data.aws_ami.ubuntu.id}"
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = ["${var.sg-ssh_id}", "${var.sg-BH_Cluster_id}"]
  ####PUBLIC
  associate_public_ip_address = true
  subnet_id = "${var.public_subnet_id}"


  connection {
    user = "ubuntu"
    private_key = "${file("~/.ssh/${var.aws_key_name}.pem")}"
  }

  #first do a remote - exec to ensure there is ssh capabilities
  provisioner "remote-exec" {
    inline = ["touch ssh-established.txt"]
  }
  #Install pySpark
  provisioner "remote-exec" {
    inline = ["sudo apt-get -y update",
              "sudo apt-get install -y python-pip",
              "sudo apt-get install -y default-jre",
              "pip install pyspark"]
  }
  provisioner "file" {
    source = "requirements.txt"
    destination = "~/requirements.txt"
  }
  #install additional python requirements
  provisioner "remote-exec" {
    inline = ["pip install -r requirements.txt"]
  }
  provisioner "file" {
    source = "key"
    destination = "~/.ssh/id_rsa"
  }
  provisioner "file" {
    source = "key.pub"
    destination = "~/key.pub"
  }
  provisioner "remote-exec" {
    inline = ["cat key.pub >> .ssh/authorized_keys"]
  }
}

output "ips" {
  value = "${aws_instance.web.*.public_ip}"
}
