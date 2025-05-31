data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["var.ami_fliter.name"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_fliter.owner] 
}

data "aws_vpc" "default" {
  default = true
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.enviornment.name
  cidr = "${var.enviornment.network_prefix}.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["$(var.enviornment.network_prefix).101.0/24", "$(var.enviornment.net).102.0/24", "$(var.enviornment.net).103.0/24"]

  

  tags = {
    Terraform = "true"
    Environment = var.enviornment.name
  }
}

module "autoscaling" {
  source   = "terraform-aws-modules/autoscaling/aws"
  version  = "8.3.0"
  name     = "var.enviornemnt.Name}-blog"
  min_size = var.asg_min_size
  max_size = var.asg_max_size

  vpc_zone_identifier = module.blog_vpc.public_subnets
  security_groups     = [module.blog_sg.security_group_id]

  image_id    = data.aws_ami.app_ami.id
  instance_type  = var.instance_type

  # insert the 1 required variable here
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "var.enviornemnt.Name}-blog-alb"
  vpc_id  = "module.blog_vpc.vpc_id"
  subnets = module.blog_vpc.public_subnets
  security_groups = [module.blog_sg.security_group_id]

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "$(var.enviornment.net).0.0/16"
    }
  }

  access_logs = {
    bucket = "my-alb-logs"
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

      forward = {
        target_group_key = "ex-instance"
      }
    }
  }

  target_groups = {
    ex-instance = {
      name_prefix      = "${var.enviornment.name}"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      target_id        = aws_instance.blog.id
    }
  }

  tags = {
    Environment = var.enviornment.name
    Project     = "Example"
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

   vpc_id             = module.blog_vpc.vpc_id
  name                = "${var.enviornemnt.Name}-blog"
  ingress_rules       = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]


  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

  
}

