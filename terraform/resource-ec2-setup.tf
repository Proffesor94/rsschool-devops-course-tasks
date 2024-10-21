# Bastion Host
resource "aws_instance" "bastion" {
  ami                         = var.aws_linux_ami
  instance_type               = var.aws_linux_instance_type
  subnet_id                   = aws_subnet.public_subnets[0].id
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  user_data                   = <<-EOF
              #!/bin/bash
              apt update -y && apt install -y awscli
              EOF
  tags = {
    Name    = "Bastion Host"
    Owner   = "Pavel Shumilin"
    Project = "Task 3"
  }
}

# NAT Instance
resource "aws_instance" "nat_instance" {
  ami                         = var.aws_nat_ami
  instance_type               = var.aws_linux_instance_type
  subnet_id                   = aws_subnet.public_subnets[0].id
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.nat_instance_sg.id]
  source_dest_check           = false
  tags = {
    Name    = "NAT Instance"
    Project = "Task 3"
  }
  user_data = <<-EOF
              #!/bin/bash
              echo 1 > /proc/sys/net/ipv4/ip_forward
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              EOF
}

# K3s Control Plane Node
resource "aws_instance" "k3s_control_plane" {
  ami                    = var.aws_linux_ami
  instance_type          = "t3.micro"
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  tags = {
    Name = "k3s-control-plane"
  }
  user_data = <<-EOF
              #!/bin/bash
              # Update and install necessary packages
              apt-get update -y
              apt-get install -y curl linux-modules-extra-$(uname -r)
              # Configure zRAM
              modprobe zram
              echo zram > /etc/modules-load.d/zram.conf
              echo "options zram num_devices=1" > /etc/modprobe.d/zram.conf
              TOTALMEM=$(free | grep -e "^Mem:" | awk '{print $2}')
              ZRAM_SIZE=$(( ($TOTALMEM * 75) / 100 ))
              echo 'KERNEL=="zram0", ATTR{disksize}="'$ZRAM_SIZE'K" RUN="/usr/sbin/mkswap /dev/zram0", TAG+="systemd"' > /etc/udev/rules.d/99-zram.rules
              echo "/dev/zram0 none swap defaults 0 0" >> /etc/fstab
              systemctl daemon-reload
              systemctl start dev-zram0.swap
              echo 'vm.swappiness = 80' >> /etc/sysctl.conf
              sysctl -p
              # Verify zRAM setup
              zramctl 

              curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --token ${var.k3s_token}

              mkdir -p /home/ubuntu/.kube
              cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
              chown ubuntu:ubuntu /home/ubuntu/.kube/config
              chmod 644 /home/ubuntu/.kube/config

              # Make kubeconfig accessible without sudo
              chmod 644 /etc/rancher/k3s/k3s.yaml
              echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /etc/profile
              source /etc/profile
              EOF
}

# K3s Worker Node
resource "aws_instance" "k3s_worker" {
  ami                    = var.aws_linux_ami
  instance_type          = "t3.micro"
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  depends_on             = [aws_instance.k3s_control_plane]
  tags = {
    Name = "k3s-worker"
  }
  user_data = <<-EOF
              #!/bin/bash
              # Update and install necessary packages
              apt-get update -y
              apt-get install -y curl linux-modules-extra-$(uname -r)
              # Configure zRAM
              modprobe zram
              echo zram > /etc/modules-load.d/zram.conf
              echo "options zram num_devices=1" > /etc/modprobe.d/zram.conf
              TOTALMEM=$(free | grep -e "^Mem:" | awk '{print $2}')
              ZRAM_SIZE=$(( ($TOTALMEM * 75) / 100 ))
              echo 'KERNEL=="zram0", ATTR{disksize}="'$ZRAM_SIZE'K" RUN="/usr/sbin/mkswap /dev/zram0", TAG+="systemd"' > /etc/udev/rules.d/99-zram.rules
              echo "/dev/zram0 none swap defaults 0 0" >> /etc/fstab
              systemctl daemon-reload
              systemctl start dev-zram0.swap
              echo 'vm.swappiness = 80' >> /etc/sysctl.conf
              sysctl -p
              # Verify zRAM setup
              zramctl 
              
              until nc -z ${aws_instance.k3s_control_plane.private_ip} 6443; do
              echo "Waiting for K3s server to be ready..."
              sleep 5
              done
              # Install K3s agent and register the worker node with the desired label
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_control_plane.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s - agent
              EOF
}