# -------------------------------------
# Network
# -------------------------------------
data "aws_vpc" "main" {
  state = "available"

  tags = {
    Name = "aws-controltower-VPC"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Network = "Private"
  }
}
