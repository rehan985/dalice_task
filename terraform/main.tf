data "aws_availability_zones" "available" {
    state = "available"
}

# VPC Configuration
resource "aws_vpc" "Dalice_Testing" {
  cidr_block       = "192.168.0.0/24"
  instance_tenancy = "default"
  tags = {
    Name = "Dalice-Testing"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Dalice_Testing.id
  tags = {
    Name = "Dalice-Testing-IGW"
  }
}

# Subnets
resource "aws_subnet" "public_subnet" {
  count                   = 4
  vpc_id                  = aws_vpc.Dalice_Testing.id
  cidr_block              = cidrsubnet(aws_vpc.Dalice_Testing.cidr_block, 3, count.index)
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "Dalice-Public-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = 4
  vpc_id            = aws_vpc.Dalice_Testing.id
  cidr_block        = cidrsubnet(aws_vpc.Dalice_Testing.cidr_block, 3, count.index + 4)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "Dalice-Private-${count.index + 1}"
  }
}

# NAT Gateways
resource "aws_eip" "nat_eip" {
  count = 2
  
}

resource "aws_nat_gateway" "nat_gw" {
  count = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)
  tags = {
    Name = "Dalice-NAT-Gateway-${count.index + 1}"
  }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.Dalice_Testing.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Dalice-Public-RT"
  }
}

resource "aws_route_table" "private_rt" {
  count  = 2
  vpc_id = aws_vpc.Dalice_Testing.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gw.*.id, count.index)
  }
  tags = {
    Name = "Dalice-Private-RT-${count.index + 1}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_rt_assoc" {
  count      = 4
  subnet_id  = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_assoc" {
  count          = 4
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private_rt.*.id, floor(count.index / 2))
}


# Security Groups
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.Dalice_Testing.id
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
  tags = {
    Name = "Dalice-Bastion-SG"
  }
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.Dalice_Testing.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.Dalice_Testing.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Dalice-Private-SG"
  }
}

# EC2 Instances
resource "aws_instance" "bastion" {
  ami           = "ami-011ef2017d41cb239" # Replace with your AMI ID
  instance_type = "t2.small"
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  security_groups = [aws_security_group.bastion_sg.id]
  key_name      = "pkv_test" # Replace with your key name
  tags = {
    Name = "Dalice-Bastion"
  }
}

resource "aws_instance" "ansible_master" {
  ami           = "ami-011ef2017d41cb239" # Replace with your AMI ID
  instance_type = "t2.small"
  subnet_id     = element(aws_subnet.private_subnet.*.id, 0)
  security_groups = [aws_security_group.private_sg.id]
  key_name      = "pkv_test" # Replace with your key name
  tags = {
    Name = "Dalice-Ansible-Master"
  }
}

resource "aws_instance" "ansible_worker" {
  ami           = "ami-011ef2017d41cb239" # Replace with your AMI ID
  instance_type = "t2.small"
  subnet_id     = element(aws_subnet.private_subnet.*.id, 1)
  security_groups = [aws_security_group.private_sg.id]
  key_name      = "pkv_test" # Replace with your key name
  tags = {
    Name = "Dalice-Ansible-Worker"
  }
}
