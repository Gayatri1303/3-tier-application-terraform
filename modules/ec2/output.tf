output "public_ip" {
  value = aws_instance.ec2.public_ip
}

output "id" {
  value = aws_instance.ec2.id
}