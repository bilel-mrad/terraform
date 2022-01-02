provider "aws" {
  region     = "eu-west-3"
  profile = "terraform"
}

#VPC Configuration
resource "aws_vpc" "development-pvc" {
  cidr_block = var.cidr_blocks[0]
  tags = {
    Name = "development-pvc"
  }
}
#Subnets Configuration  
resource "aws_subnet" "dev-subnet-1" {
  vpc_id            = aws_vpc.development-pvc.id
  cidr_block        = var.cidr_blocks[1]
  availability_zone = "eu-west-3a"
  tags = {
    Name = "subnet-1-dev"
  }
}

resource "aws_subnet" "dev-subnet-2" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "172.31.48.0/20"
  availability_zone = "eu-west-3a"
}

#Data Sources
data "aws_vpc" "existing_vpc" {
  default = true

}

#Outputs

output "dev-vpc-id" {
  value = aws_vpc.development-pvc.id
}
output "dev-subnet-1" {
  value = aws_subnet.dev-subnet-1.id

}

#Variables

variable "cidr_blocks" {
    description = "vpc and subnet cidr bocks"
    type = list(string)
}
