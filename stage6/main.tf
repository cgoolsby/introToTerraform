provider "http" {}
provider "aws" {
  region = "us-west-2"
}

module "vpc_network" {
  source = "./modules/network/vpc/"
 }
module "internet_gateway" {
  source = "./modules/network/igw/"
  vpc_id = "${module.vpc_network.vpc_id}"
}
module "security_groups" {
#  source = "./modules/network/security_groups/"
  source = "./modules/network/open_security_groups/"
  vpc_id = "${module.vpc_network.vpc_id}"
}
module "subnets" {
  source = "./modules/network/subnets/"
  vpc_id = "${module.vpc_network.vpc_id}"
}
module "route_tables" {
  source = "./modules/network/route_tables/"
  vpc_id = "${module.vpc_network.vpc_id}"
  igw_id = "${module.internet_gateway.igw_id}"
  Public_Subnet_id_list = "${module.subnets.public_subnet_ids}"
  Private_Subnet_id_list = "${module.subnets.private_subnet_ids}"
}
module "spark_EC2" {
  source = "./modules/spark_EC2/"
  extraEC2count = "4"
  aws_instance_type = "m4.large"
  public_subnet_id = "${module.subnets.public_subnet_ids[0]}"
  sg-ssh_id = "${module.security_groups.sg-ssh_id}" 
  aws_key_name = "${var.key_name}"
  sg-BH_Cluster_id = "${module.security_groups.sg-BH_Cluster_Open}"
}

output "Ips" {
  value = "${module.EC2.ips}"
}
