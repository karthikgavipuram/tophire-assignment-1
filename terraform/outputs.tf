# terraform/outputs.tf
output "master_public_ip" {
  description = "The public IP address of the Kubernetes Master Node."
  value       = aws_instance.k8s_master.public_ip
}

output "ssh_connect" {
  description = "SSH command to connect to the master node."
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.k8s_master.public_ip}"
}