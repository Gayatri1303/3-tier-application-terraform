
resource "aws_subnet" "sub" {
  vpc_id     = var.vpc_id
  cidr_block = var.pub_cidr
  availability_zone = var.az

}

