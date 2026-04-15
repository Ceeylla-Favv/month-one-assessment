output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "load_balancer_dns" {
  description = "Paste this into browser to see the web app"
  value       = aws_lb.main.dns_name
}

output "bastion_public_ip" {
  description = "SSH into this IP to reach the bastion host"
  value       = aws_eip.bastion.public_ip
}