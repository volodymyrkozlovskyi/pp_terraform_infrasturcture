provider "aws" {

  region = var.region
}

variable "region" {
  default = "us-west-1"
}

terraform {
  backend "s3" {
    bucket = "pp-app-infrastucture"
    key    = "pebble_infrastructure/terraform.tfstate"
    region = "us-west-1"
  }
}

variable "key_name" {
  default = "nort_cali"
}

data "aws_vpc" "default" {
  default = true
}
data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu_image" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64*"]
  }
}

variable "instance_volume_size_gb" {
  description = "The root volume size, in gigabytes"
  default     = "8"
}
#-----------------------------------------------------------------------------
# security group will be used one for port 80 and 22
# it sis a good
resource "aws_security_group" "web_sg" {
  name   = "web_sc"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_subnet" "default_sub1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_instance" "web-app" {
  ami                    = data.aws_ami.ubuntu_image.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name
  user_data              = file("./user-data/user-data.sh")

  root_block_device {
    volume_size = var.instance_volume_size_gb
  }
}
