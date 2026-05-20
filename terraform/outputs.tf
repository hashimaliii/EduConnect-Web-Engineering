output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  value = module.vpc.nat_gateway_id
}

output "web_server_public_ip" {
  value = module.web_server.public_ip
}

output "db_server_private_ip" {
  value = module.db_server.private_ip
}