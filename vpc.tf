#
# Sandbox VPC for testing purposes
#
data "aws_vpc" "this" {
  count = (lower(var.env) == "sandbox" || var.vpc == null) ? 1 : 0
  filter {
    name = "tag:Name"
    values = ["vpc-main-sandbox"]
  }

  filter {
    name = "tag:Environment"
    values = ["sandbox"]
  }
}

#
# Sandbox Subnets for testing purposes
#
data "aws_subnets" "this" {
  count = (lower(var.env) == "sandbox" || var.vpc == null) ? 1 : 0
  filter {
    name = "tag:Environment"
    values = ["sandbox"]
  }
}

#
# Sandbox security group for testing purposes
#
data "aws_security_group" "this" {
  count  = (lower(var.env) == "sandbox" || var.vpc == null) ? 1 : 0
  vpc_id = data.aws_vpc.this[0].id
  filter {
    name = "tag:Environment"
    values = ["sandbox"]
  }
}