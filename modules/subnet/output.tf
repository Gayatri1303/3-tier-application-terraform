output "subnet_id" {
  value = aws_subnet.sub.id
}

output "pub_cidr" {
  value = var.pub_cidr
}