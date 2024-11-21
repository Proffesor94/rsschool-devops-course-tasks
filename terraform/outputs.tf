output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP of the Bastion Host"
}

output "control_plane_private_ip" {
  value       = aws_instance.k3s_control_plane.private_ip
  description = "Private IP of the K3s Control Plane Node"
}

output "worker_private_ip" {
  value       = aws_instance.k3s_worker.private_ip
  description = "Private IP of the K3s Worker Node"
}

output "nat_instance_ip" {
  value       = aws_eip.nat_eip.public_ip
  description = "Public IP of the NAT instance"
}

output "kubeconfig_instructions" {
  value       = <<EOT
    To access your K3s cluster from your local machine, use the following command:
    ssh -i <path_to_your_key> -L 6443:${aws_instance.k3s_control_plane.private_ip}:6443 ubuntu@${aws_instance.bastion.public_ip}
    Then configure kubectl to use 'localhost:6443' as the API server address.
  EOT
  description = "Instructions for accessing the K3s cluster through the bastion host."
}
