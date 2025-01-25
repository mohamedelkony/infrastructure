provider "aws" {
  region = "us-west-1"
}
resource "aws_ami" "ubuntu_ami_with_jenkins_snapshot" {
  name                = "ubuntu_ami_with_jenkins_snapshot"
  virtualization_type = "hvm"
  root_device_name    = "/dev/sda1"
  ebs_block_device {
    device_name = "/dev/sda1" 
    snapshot_id = "snap-0f13b01b81af06bd8"  
    volume_size = 8 
    volume_type = "gp3"  
  }
}

resource "aws_instance" "jenkins_controller" {
  ami                         = aws_ami.ubuntu_ami_with_jenkins_snapshot.id 
  instance_type               = "t2.micro"
  availability_zone           = "us-west-1a"
  subnet_id                   = "subnet-0576347d1a502e38d"
  associate_public_ip_address = true
  key_name                    = "AWS_Jenkins_controller_key"

  iam_instance_profile = aws_iam_instance_profile.Jenkins_controller_EC2_IAM_instance_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = false
  }

  vpc_security_group_ids = [aws_security_group.allow_ssh_http_https.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Instance just started!" > ~/ec2-user/juststarted.txt
              EOF

  tags = {
    Name = "jenkins_controller"
  }
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > public_ip.txt"
  }
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins_controller.public_ip
}

resource "aws_security_group" "allow_ssh_http_https" {
  name_prefix = "allow_ssh_http_https"

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
    from_port   = 443
    to_port     = 443
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


resource "aws_iam_role" "jenkins_controller_EC2_IAM_role" {
  name = "jenkins_controller_EC2_IAM_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_management_policy" {
  name        = "EC2-Management-Policy"
  description = "Policy for managing EC2 instances, security groups, and volumes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:CreateVolume",
          "ec2:DeleteVolume"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ec2_management_attachment" {
  role       = aws_iam_role.jenkins_controller_EC2_IAM_role.name
  policy_arn = aws_iam_policy.ec2_management_policy.arn
}

resource "aws_iam_instance_profile" "Jenkins_controller_EC2_IAM_instance_profile" {
  name = "Jenkins_controller_EC2_IAM_instance_profile"
  role = aws_iam_role.jenkins_controller_EC2_IAM_role.name
}
