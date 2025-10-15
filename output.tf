output "frontendip" {
  value = module.frontend.public_ip
}

output "backendip" {
  value = module.backend1.public_ip
}