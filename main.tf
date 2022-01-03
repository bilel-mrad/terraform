#VPC Configuration
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_blocks
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

#Modules definition

module "myapp-subnet" {
  source                 = "./modules/subnet"
  subnet_cidr_blocks     = var.subnet_cidr_blocks
  avail_zone             = var.avail_zone
  env_prefix             = var.env_prefix
  vpc_id                 = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}

module "myapp-server" {
  source              = "./modules/webserver"
  my_ip               = var.my_ip
  instance_type       = var.instance_type
  avail_zone          = var.avail_zone
  env_prefix          = var.env_prefix
  public_key_location = var.public_key_location
  vpc_id              = aws_vpc.myapp-vpc.id
  subnet_id           = module.myapp-subnet.subnet.id
}