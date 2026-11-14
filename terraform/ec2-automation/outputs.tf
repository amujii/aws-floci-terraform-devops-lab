output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.demo_ec2.id
}

output "instance_type" {
  description = "EC2 instance type"
  value       = aws_instance.demo_ec2.instance_type
}

output "instance_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.demo_ec2.public_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.ec2_sg.id
}

output "key_pair_name" {
  description = "SSH key pair name"
  value       = aws_key_pair.my_key.key_name
}