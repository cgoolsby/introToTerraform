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
  provisioner "remote-exec" {
    inline = ["chmod 0600 .ssh/id_rsa"]
  }
  provisioner "remote-exec" {
    inline = ["wget http://apache.claz.org/kafka/2.2.0/kafka_2.12-2.2.0.tgz"]
  }
  provisioner "remote-exec" {
    inline = ["tar -xzf kafka_2.12-2.2.0.tgz"]
  }
  provisioner "remote-exec" {
    inline = ["sudo mv kafka_2.12-2.2.0/ /usr/local/kafka/"]
  }
  provisioner "remote-exec" {
    inline = ["sudo sed -i '1i export JMX_PORT=$${JMX_PORT:-9999}' /usr/local/kafka/bin/kafka-server-start.sh"]
  } 
}
locals {
  zookeeper_ips = "${join(":2181, ", aws_instance.web.*.public_ip)}"
}
resource "null_resource" "kafka_setup_zookeeper_ips" {
  depends_on = ["aws_instance.web"]
  count = 4
  connection {
    user = "ubuntu"
    host = "${element(aws_instance.web.*.public_ip,count.index)}"
    private_key = "${file("~/.ssh/${var.aws_key_name}.pem")}"
  }
  provisioner "remote-exec" {
    inline = ["sudo sed -i 's%localhost:2181%'\"{${local.zookeeper_ips}:0:-1}\"'%g' /usr/local/kafka/config/server.properties"]
  }
}
resource "null_resource" "kafka_setup" {
  depends_on = ["aws_instance.web"]
  count = 4
  connection {
    user = "ubuntu"
    host = "${element(aws_instance.web.*.public_ip,count.index)}"
    private_key = "${file("~/.ssh/${var.aws_key_name}.pem")}"
  }
  provisioner "remote-exec" {
    inline = ["sudo sed -i 's%broker.id=0%broker.id='\"${count.index}\"'%g' /usr/local/kafka/config/server.properties"]
  }
  provisioner "remote-exec" {
    inline = ["sudo sed -i 's%#advertised.listeners=PLAINTEXT://your.host.name%advertised.listeners=PLAINTEXT://'\"${element(aws_instance.web.*.public_ip,0)}\"'%g' /usr/local/kafka/config/server.properties"]
  }
}

output "ips" {
  value = "${aws_instance.web.*.public_ip}"
}
