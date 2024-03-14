provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["./credentials.txt"]
}

#Creating the VPC
resource "aws_vpc" "vpc_Lab2" {
  cidr_block = "192.168.0.0/16"
}

#Creating the public subnets
resource "aws_subnet" "SN_public_Lab2" {
  count                   = 4
  vpc_id                  = aws_vpc.vpc_Lab2.id
  cidr_block              = "192.168.${4 * count.index}.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

#Creating the security group
resource "aws_security_group" "Lab2_SG" {
  name        = "Lab2_SG"
  vpc_id      = aws_vpc.vpc_Lab2.id
  description = "Allows SSH, HTTP & two docker NGINX containers"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8081
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

#Creating the EC2 instances
resource "aws_instance" "Lab2_Instance" {
  count         = 4
  ami           = "ami-0f403e3180720dd7e"
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.SN_public_Lab2.*.id, count.index)

  tags = {
    Name = "Lab2_Instance"
  }

  #two docker NGINX containers
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install docker -y
              sudo systemctl start docker
              sudo docker run -d -p 80:80 nginx
              sudo docker run -d -p 8080:8080 nginx
              sudo docker run -d -p 8081:8081 nginx
              EOF

  #Applying the SG to the instance
  vpc_security_group_ids = [aws_security_group.Lab2_SG.id]
}

#Creating the Internet Gateway
resource "aws_internet_gateway" "IGW_Lab2" {
  vpc_id = aws_vpc.vpc_Lab2.id

  tags = {
    Name = "IGW_Lab2"
  }
}

#Creating the Route Table
resource "aws_route_table" "Public_RT_Lab2" {
  vpc_id = aws_vpc.vpc_Lab2.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW_Lab2.id
  }

  tags = { 
    Name = "Public_RT_Lab2" 
  }
}

#Creating the Route Table Association
resource "aws_route_table_association" "SNPublic_RT_Lab2" {
  count          = 4
  subnet_id      = aws_subnet.SN_public_Lab2[count.index].id
  route_table_id = aws_route_table.Public_RT_Lab2.id
}

