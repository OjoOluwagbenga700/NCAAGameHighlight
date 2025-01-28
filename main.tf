# Add provider configuration with version constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use version constraints
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2" # Specify your desired AWS region
}

resource "aws_default_vpc" "default_vpc" {

  tags = {
    Name = "default vpc"
  }
}
# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}

# create default subnet if one does not exit
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "default subnet"
  }
}

# create security group for the ec2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2_instance_sg"
  }
}

# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
data "aws_caller_identity" "current" {}

# Create IAM role for EC2
resource "aws_iam_role" "HighlightProcessorRole" {
  name = "HighlightProcessorRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "mediaconvert.amazonaws.com"
          ],
          
        }
      }
    ]
  })
}

  resource "aws_iam_role_policy_attachment" "HighlightProcessorPolicyAttachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElementalMediaConvertFullAccess"
  role       = aws_iam_role.HighlightProcessorRole.name
}

 resource "aws_iam_role_policy_attachment" "HighlightProcessors3PolicyAttachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.HighlightProcessorRole.name
}
      


# Create instance profile
resource "aws_iam_instance_profile" "game_highlight_profile" {
  name = "HighlightProcessor_instance_profile"
  role = aws_iam_role.HighlightProcessorRole.name
}

#launch s3 Bucket
resource "aws_s3_bucket" "game-highlight-bucket" {
  bucket        = "game-highlight-700"
  force_destroy = true
}



# launch the ec2 instance
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  iam_instance_profile   = aws_iam_instance_profile.game_highlight_profile.name
  key_name               = "mynewkeypair"

  tags = {
    Name        = "game-highlight-server"
    Environment = "dev"
    Project     = "game-highlight"
  }
}
# an empty resource block
resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/mynewkeypair.pem")
    host        = aws_instance.ec2_instance.public_ip
  }

  # copy files from your computer to the ec2 instance
  provisioner "file" {
    source      = ".env"
    destination = "/home/ec2-user/.env"
  }

  provisioner "file" {
    source      = "config.py"
    destination = "/home/ec2-user/config.py"
  }

  provisioner "file" {
    source      = "Dockerfile"
    destination = "/home/ec2-user/Dockerfile"
  }

  provisioner "file" {
    source      = "fetch.py"
    destination = "/home/ec2-user/fetch.py"
  }

  provisioner "file" {
    source      = "mediaconvert_process.py"
    destination = "/home/ec2-user/mediaconvert_process.py"
  }

  provisioner "file" {
    source      = "process_one_video.py"
    destination = "/home/ec2-user/process_one_video.py"
  }

  provisioner "file" {
    source      = "requirements.txt"
    destination = "/home/ec2-user/requirements.txt"
  }

  provisioner "file" {
    source      = "run_all.py"
    destination = "/home/ec2-user/run_all.py"
  }


  # set permissions and run the python script
  provisioner "remote-exec" {
    inline = [
      # Install Docker
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      # secure.env file
      "sudo chmod 600 .env",
      # Create Docker image
      "sudo docker build -t highlight-processor .",

      # Run Docker container with env file
      "sudo docker run --env-file .env highlight-processor",

    ]
  }
  lifecycle {
    create_before_destroy = true
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.ec2_instance, aws_s3_bucket.game-highlight-bucket]
}


