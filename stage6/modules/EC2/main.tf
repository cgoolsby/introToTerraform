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
  provisioner "remote-exec" {
    inline = ["chmod 0600 .ssh/id_rsa"]
  }
  provisioner "remote-exec" {
    inline = ["wget http://www-us.apache.org/dist/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz"]
  }
  provisioner "remote-exec" {
    inline = ["tar xvf spark-2.4.0-bin-hadoop2.7.tgz"]
  }
  provisioner "remote-exec" {
    inline = ["sudo mv spark-2.4.0-bin-hadoop2.7 /usr/local/spark"]
  }
  provisioner "file" {
    source = "pathAppend.txt"
    destination = "~/pathAppend.txt"
  }
  provisioner "remote-exec" {
    inline = ["cat pathAppend.txt >> ~/.bashrc"]
  }
  provisioner "remote-exec" {
    inline = ["sudo echo \"\nmaster\nslave00\nslave01\nslave02\">>/usr/local/spark/conf/slaves"]
  }
  provisioner "remote-exec" {
    inline = ["cp /usr/local/spark/conf/spark-env.sh.template /usr/local/spark/conf/spark-env.sh"]
  }
}
resource "null_resource" "provision_master" {
  connection {
    user = "ubuntu"
    host = "${element(aws_instance.web.*.public_ip,0)}"
    private_key = "${file("~/.ssh/${var.aws_key_name}.pem")}"
  }
  
  provisioner "remote-exec" {
    inline = ["echo \"export SPARK_MASTER_HOST=${element(aws_instance.web.*.private_ip,0)}\" >> /usr/local/spark/conf/spark-env.sh"]
  }
  provisioner "remote-exec" {
    inline = ["echo \"export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre\" >> /usr/local/spark/conf/spark-env.sh"]
  }
  provisioner "remote-exec" {
    inline = ["sudo echo \"${element(aws_instance.web.*.public_ip,0)} master\" | sudo tee --append /etc/hosts"]
  }
}
resource "null_resource" "populate_slaves_and_host_etc" {
  count = 3
  connection {
    user = "ubuntu"
    host = "${element(aws_instance.web.*.public_ip,0)}"
    private_key = "${file("~/.ssh/${var.aws_key_name}.pem")}"
  }
  provisioner "remote-exec" {
    inline = ["sudo echo \" ${element(aws_instance.web.*.public_ip,count.index+1)}  slave0${count.index}\" | sudo tee --append /etc/hosts"] 
  }
}
resource "null_resource" "start_spark" {
  depends_on = ["null_resource.provision_master", "null_resource.populate_slaves_and_host_etc"]
  connection {
    user = "ubuntu"
    host = "${element(aws_instance.web.*.public_ip,0)}"
    private_key = "${file("~/.ssh/${var.aws_key_name}.pem")}"
  }
  provisioner "remote-exec" {
    inline = ["bash /usr/local/spark/sbin/start-all.sh"]
  }
}
output "ips" {
  value = "${aws_instance.web.*.public_ip}"
}
