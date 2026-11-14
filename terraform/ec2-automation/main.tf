
# 1. Register SSH public key
resource "aws_key_pair" "my_key" {
  key_name   = "floci-ec2-key"
  public_key = file("${path.module}/keys/floci-ec2-key.pub")
}

# 2. Get the existing default VPC
data "aws_vpc" "default" {
  default = true
}

# 3. Get subnets belonging to the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 4. Create custom security group
resource "aws_security_group" "ec2_sg" {
  name        = "floci-ec2-security-group"
  description = "Security group for Terraform EC2 lab"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["127.0.0.1/32"]
  }

  # HTTP access
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["127.0.0.1/32"]
  }

  # Flask application
  ingress {
    description = "Flask application"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["127.0.0.1/32"]
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "floci-ec2-security-group"
    Environment = "Learning"
    ManagedBy   = "Terraform"
  }
}

# 5. Create EC2 instance
resource "aws_instance" "demo_ec2" {
  ami           = "ami-0abcdef1234567891"
  instance_type = "t2.micro"

  # Select default subnet
  subnet_id = data.aws_subnets.default.ids[0]

  # Attach security group
  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  # Attach SSH key
  key_name = aws_key_pair.my_key.key_name

  # Configure root EBS volume
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name        = "terraform-floci-ec2"
    Environment = "Learning"
    ManagedBy   = "Terraform"
  }
}
