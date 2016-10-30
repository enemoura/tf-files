## Terraform main
## The key word 'resource' creates resources if not already imported
## Trying to create a resource with an existing name fails
## Order is not important, but in this case:
## 1) Create VPC and VPC components
## 2) Create a Security Group
## 3) Create a key pair - commented as we'll use existing key
## 4) Instantiate the server
## 5) As part of instantiation, assign the sg created earlier and add a public IP



# Create a VPC to launch our instances into
resource "aws_vpc" "test3" {
  cidr_block = "192.168.10.0/24"
  enable_dns_hostnames = "true"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "gw3" {
   vpc_id = "${aws_vpc.test3.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.test3.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw3.id}"
}

# Create 4 subnets to launch our instances into
# The first two are public, the second two private
resource "aws_subnet" "Private_1A" {
  vpc_id = "${aws_vpc.test3.id}"
  cidr_block              = "192.168.10.192/27"
  map_public_ip_on_launch = false
}
resource "aws_subnet" "Private_1D" {
  vpc_id = "${aws_vpc.test3.id}"
  cidr_block              = "192.168.10.224/27"
  map_public_ip_on_launch = false
}
resource "aws_subnet" "Public_1A" {
  vpc_id = "${aws_vpc.test3.id}"
  cidr_block              = "192.168.10.64/27"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "Public_1D" {
  vpc_id = "${aws_vpc.test3.id}"
  cidr_block              = "192.168.10.128/27"
  map_public_ip_on_launch = true
}

## A new security group
resource "aws_security_group" "default" {
  name        = "terraform_testing"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.test3.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#resource "aws_key_pair" "auth" {
#  key_name   = "${var.key_name}"
#  public_key = "${file(var.public_key_path)}"
#}

resource "aws_instance" "tf-instance" {
  ami           = "ami-1b83c00c"
  instance_type = "t2.nano"
  subnet_id = "${aws_subnet.Public_1A.id}"
  key_name = "My Key"
  connection {
  	user = "ec2-user"
  }

vpc_security_group_ids = ["${aws_security_group.default.id}"]
associate_public_ip_address = true

}
