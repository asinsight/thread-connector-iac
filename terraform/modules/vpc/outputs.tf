output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = aws_vpc.this.id
}

output "cidr_block" {
  description = "CIDR block associated with the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the created public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of the created private subnets"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "private_route_table_ids" {
  description = "IDs of the private route tables for attaching gateway endpoints"
  value       = [for rt in aws_route_table.private : rt.id]
}
