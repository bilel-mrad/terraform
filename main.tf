provider "aws" {
  region  = "eu-west-3"
  profile = "terraform"
}
#Variables Definition
variable "vpc_cidr_blocks" {}
variable "subnet_cidr_blocks" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "instance_type" {}
variable "my_ip" {}
variable "public_key_location" {}



#VPC Configuration
resource "aws_vpc" "myapp-pvc" {
  cidr_block = var.vpc_cidr_blocks
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}
#Subnets Configuration  
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-pvc.id
  cidr_block        = var.subnet_cidr_blocks
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

#Route Table
/*resource "aws_route_table" "my-app-route-table" {
  vpc_id = aws_vpc.myapp-pvc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-rt"
  }
}*/
#Internet IGW
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-pvc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}
#Route table association
/*resource "aws_route_table_association" "myapp-rt-association" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.my-app-route-table.id
}*/

#Default route table
resource "aws_default_route_table" "myapp-default-rt" {
  default_route_table_id = aws_vpc.myapp-pvc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-main-rtb"
  }
}

#Default SG

resource "aws_default_security_group" "myapp-default-sg" {
  vpc_id = aws_vpc.myapp-pvc.id

  ingress {
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    from_port   = 22
    to_port     = 22
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    to_port     = 8080
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Ec2 Instance
resource "aws_instance" "myapp-server" {
  ami                         = data.aws_ami.myapp-ami.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_default_security_group.myapp-default-sg.id]
  key_name                    = aws_key_pair.myapp-key.id

  user_data = <<EOF
                  #!/bin/bash
                  sudo yum update -y
                  sudo yum install -y docker
                  sudo systemctl start docker
                  sudo systemctl enable docker
                  sudo usermod -Ga docker ec2-user 
                  docker run -p 8080:80 nginx
                EOF
  tags = {
    Name = "${var.env_prefix}-myapp-server"
  }
}

#Data source to fetch ami in eu-west-3

data "aws_ami" "myapp-ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] # Canonical
}

#Key pair

resource "aws_key_pair" "myapp-key" {
  key_name   = "deployer-key"
  public_key = file(var.public_key_location)
}

#Output

output "aws-ami" {
  value = data.aws_ami.myapp-ami.id
}

output "myapp-ip" {
  value = aws_instance.myapp-server.public_ip
}