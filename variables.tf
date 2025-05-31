variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}

variable "ami_fliter
    description = "Name filter and owner for AMI"

    type    = pbject({
      name  = string
      owner = string

    })
    default = {
    name = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  owner= "979382823631" # Bitnami
    }
}

data "aws_vpc" "default" {
  default = true
}

variable ="enviornment" {
  decsription = "Development Environment"
  type = object ({
    name           = string
    network_prefix = string
})
  default = {
    name = "dev"
    cidr = "10.0"
  }
}

variable "asg_min_size" {
  decxsription = "minimum number of instance in the ASG"
  default      = 1
}
variable "asg_max_size" {
  decxsription = "maximum number of instance in the ASG"
  default      = 2
}