
provider "aws" {
  region                  = "us-east-1"
  profile                 = ""
  shared_credentials_file = "~/.aws/credentials"
}

resource "aws_db_subnet_group" "group_1-test-1" {
  name       = "subnet-group-1-test-1"
  subnet_ids = ["", ""] # add our private subnets here

  tags = {
    Name = "My RDS subnet group"
  }
}

####### EC2 Security Group ############
resource "aws_security_group" "ec2-sg-test-1" {
  name   = "ec2_sg-test-1"
  vpc_id = "" # Add our VPC Id here
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
####### RDS Security Group ############
resource "aws_security_group" "rds-sg-test-1" {
  name   = "rds_sg-test-1"
  vpc_id = "" # Add our VPC Id here
  # SSH access from anywhere
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2-sg-test-1.id]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_s3_role-test-1" {
  name               = "ec2_s3_role-test-1"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_s3_profile-test-1" {
  name = "ec2_s3_profile-test-1"
  role = aws_iam_role.ec2_s3_role-test-1.name
}

resource "aws_iam_role_policy" "ec2_s3_policy-test-1" {
  name   = "ec2_s3_policy-test-1"
  role   = aws_iam_role.ec2_s3_role-test-1.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
                "arn:aws:s3:::${var.s3_bucket_name}",
                "arn:aws:s3:::${var.s3_bucket_name}/*"
            ]
    }
  ]
}
EOF
}

######## RDS ############
resource "aws_db_instance" "pa-demo-mysql-rds-2-test-1" {
  identifier             = ""
  allocated_storage      = var.allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.db_instance_class
  name                   = ""
  username               = var.username
  password               = var.password
  vpc_security_group_ids = [aws_security_group.rds-sg-test-1.id]
  db_subnet_group_name   = aws_db_subnet_group.group_1-test-1.name
  skip_final_snapshot    = true
}
####### EC2 ############
resource "aws_key_pair" "ec2-key-test-1" {
  key_name   = "deployer-key"
  public_key = file(var.private_key_path)
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "instance-test-1" {
  ami                         = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_s3_profile-test-1.name
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ec2-key-test-1.key_name
  vpc_security_group_ids      = ["${aws_security_group.ec2-sg-test-1.id}"]
  subnet_id                   = "" # add our public vpc id here
  tags = {
    Name = "pa-test-instance"
  }
}

####### S3  ############
resource "aws_s3_bucket" "media_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"
}
