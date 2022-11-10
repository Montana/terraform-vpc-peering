module "vpc-1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "VPC1"
  cidr = "10.0.0.0/16"

  azs = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c"
  ]

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  public_subnets = [
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]

  intra_subnets = [
    "10.0.7.0/28",
    "10.0.7.16/28",
    "10.0.7.32/28"
  ]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}
    
module "vpc-2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "VPC2"

  cidr = "10.1.0.0/16"

  enable_dns_hostnames = true

  azs = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c"
  ]

  private_subnets = [
    "10.1.1.0/24",
    "10.1.2.0/24",
    "10.1.3.0/24"
  ]
}
    
resource "aws_vpc_peering_connection" "vpc1-to-vpc2" {
  vpc_id = module.vpc-1.vpc_id
  peer_vpc_id = module.vpc-2.vpc_id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  auto_accept = true
}

resource "aws_route" "vpc1_private_to_peering_connection" {
  count = "${length(module.vpc-1.private_route_table_ids)}"
  
  route_table_id = "${module.vpc-1.private_route_table_ids[count.index]}"
  destination_cidr_block = module.vpc-2.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1-to-vpc2.id
}
    
resource "aws_route" "vpc2_private_to_peering_connection" {
  count = "${length(module.vpc-2.private_route_table_ids)}"
  
  route_table_id = "${module.vpc-2.private_route_table_ids[count.index]}"
  destination_cidr_block = module.vpc-1.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1-to-vpc2.id
}
