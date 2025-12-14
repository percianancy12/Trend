provider "aws" {
  region = "ap-south-1"
}

# -------------------------
# Networking
# -------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "main_vpc" }
}

resource "aws_subnet" "sub1_jenkins" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = { Name = "sub1_jenkins" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main_igw" }
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main_route_table" }
}

resource "aws_route" "route" {
  route_table_id         = aws_route_table.rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.sub1_jenkins.id
  route_table_id = aws_route_table.rtb.id
}

# -------------------------
# Security Group
# -------------------------
resource "aws_security_group" "sg" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_ssh_jenkins"
  description = "Allow SSH and Jenkins inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Jenkins"
    from_port   = 8080
    to_port     = 8080
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

# -------------------------
# IAM Role + Instance Profile
# -------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_role" {
  name               = "ec2_jenkins_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2_instance_profile_jenkins"
  role = aws_iam_role.jenkins_role.name
}

# -------------------------
# EC2 Instance with Jenkins
# -------------------------
resource "aws_instance" "jenkins" {
  ami                         = "ami-00ca570c1b6d79f36" # Amazon Linux 2 in ap-south-1
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.sub1_jenkins.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  associate_public_ip_address = true
  key_name                    = "jenkins"   # replace with your actual EC2 key pair name

  user_data = <<EOF
#!/bin/bash
set -ex
yum update -y
yum install -y wget
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y java-21-amazon-corretto jenkins
systemctl enable jenkins
systemctl start jenkins
EOF

  tags = { Name = "Jenkins_Server" }
}

# -------------------------
# Outputs
# -------------------------
output "instance_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}