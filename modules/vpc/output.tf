output "vpc_id" {
  value = aws_vpc.threetier.id

}
output "mrtid" {
  value = aws_vpc.threetier.main_route_table_id
}

output "naclid" {
  value = aws_vpc.threetier.default_network_acl_id
}
