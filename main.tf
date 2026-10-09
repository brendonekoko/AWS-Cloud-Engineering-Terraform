terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}
resource "aws_vpc" "cloud_lab" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "CloudEngineering-VPC"
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.cloud_lab.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "CloudEngineering-PublicSubnet"
  }
}
resource "aws_internet_gateway" "cloud_igw" {
  vpc_id = aws_vpc.cloud_lab.id

  tags = {
    Name = "CloudEngineering-IGW"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cloud_lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud_igw.id
  }

  tags = {
    Name = "CloudEngineering-PublicRT"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_security_group" "cloud_sg" {
  name        = "CloudEngineering-SG"
  description = "Security group for cloud engineering lab"
  vpc_id      = aws_vpc.cloud_lab.id

  ingress {
    description = "SSH from my public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CloudEngineering-SG"
  }
}
resource "aws_key_pair" "cloud_key" {
  key_name   = "CloudEngineering-Key"
  public_key = file(pathexpand("~/.ssh/aws-cloud-lab.pub"))

  tags = {
    Name = "CloudEngineering-Key"
  }
}
data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "cloud_server" {
  ami                         = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.cloud_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.cloud_key.key_name
  user_data = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "CloudEngineering-LinuxServer"
  }
}
variable "ssh_allowed_cidr" {
  description = "Public IP address allowed to SSH into EC2"
  type        = string
}
