data "aws_ami" "ec2" {

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*"]
  }

  most_recent = true
  owners      = ["amazon"]

  tags = {
    Name = "${var.env_code}-EC2"
  }
}

output "ec2_ami" {
  value = data.aws_ami.ec2
}

#LC
resource "aws_launch_configuration" "main" {
  name_prefix          = "${var.env_code}-"
  image_id             = data.aws_ami.ec2.id
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.private.id]
  user_data            = file("../modules/asg/user-data.sh")
  key_name             = "main"
  iam_instance_profile = aws_iam_instance_profile.main.name
}

#Auto-Scaling-Group

resource "aws_autoscaling_group" "main" {
  name             = var.env_code
  max_size         = 4
  min_size         = 2
  desired_capacity = 2

  target_group_arns    = [var.target_group_arn]
  launch_configuration = aws_launch_configuration.main.name
  vpc_zone_identifier  = var.private_subnet_id

  tag {
    key                 = "Name"
    value               = var.env_code
    propagate_at_launch = true
  }
}
