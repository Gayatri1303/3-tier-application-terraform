resource "aws_instance" "ec2" {
  ami=var.ami_id
  instance_type = var.type
  region = var.region_name
  availability_zone = var.az
  subnet_id = var.subnet_id
  key_name = var.key_name
  vpc_security_group_ids = [ var.sg ]
  user_data = var.user
  associate_public_ip_address = var.flag
  tags = {
    Name=var.name
  }


}
