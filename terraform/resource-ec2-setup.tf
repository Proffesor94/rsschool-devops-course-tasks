# Bastion Host
resource "aws_instance" "bastion" {
  ami                         = var.aws_linux_ami
  instance_type               = var.aws_linux_instance_type
  subnet_id                   = aws_subnet.public_subnets[0].id
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  depends_on                  = [aws_instance.k3s_control_plane]
  user_data                   = <<-EOF
              #!/bin/bash
              set -e
              # Update package list and install Nginx
              apt update -y && apt install -y nginx
              # Create Nginx reverse proxy configuration
              cat << 'NGINXCONF' > /etc/nginx/sites-available/reverse-proxy
              server {
                  listen 8080;

                  location / {
                      proxy_pass http://${aws_instance.k3s_worker.private_ip}:32000;
                      proxy_set_header Host $host;
                      proxy_set_header X-Real-IP $remote_addr;
                      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                      proxy_set_header X-Forwarded-Proto $scheme;

                  }
              }
              NGINXCONF
              ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/
              nginx -t
              systemctl restart nginx
              EOF
  tags = {
    Name    = "Bastion Host"
    Owner   = "Pavel Shumilin"
    Project = "Task 5"
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
              # Enable IP forwarding
              sysctl -w net.ipv4.ip_forward=1
              echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
              
              # Configure NAT
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              
              # Make iptables rules persistent
              yum install -y iptables-services
              service iptables save
              systemctl enable iptables
              systemctl start iptables
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
              set -e

              # Update system and install required packages for extending unified memory
              apt-get update -y
              apt-get install -y curl
              #apt-get install -y curl linux-modules-extra-$(uname -r)

              ## Configure zRAM
              #modprobe zram
              #
              ## Create persistent module loading configuration
              #echo "zram" > /etc/modules-load.d/zram.conf
              #echo "options zram num_devices=1" > /etc/modprobe.d/zram.conf
              #
              ## Calculate zRAM size (100% of total RAM)
              #TOTALMEM=$(free | grep -e "^Mem:" | awk '{print $2}')
              #ZRAM_SIZE=$TOTALMEM
              #
              ## Configure compression algorithm to lzo-rle
              #echo "lzo-rle" > /sys/block/zram0/comp_algorithm
              #
              ## Create udev rule for zRAM device
              #cat << 'UDEVRULE' > /etc/udev/rules.d/99-zram.rules
              #KERNEL=="zram0", ATTR{disksize}="$ZRAM_SIZE"K" RUN="/usr/bin/mkswap -L zram0 /dev/zram0", TAG+="systemd"
              #UDEVRULE

              # Create and configure regular swap partition (1GB)
              dd if=/dev/zero of=/swapfile bs=1M count=1024
              chmod 600 /swapfile
              mkswap /swapfile
              swapon -p 100 /swapfile

              # Add swap entries to fstab
              #grep -q "^/dev/zram0" /etc/fstab || echo "/dev/zram0 none swap defaults,pri=-2 0 0" >> /etc/fstab
              grep -q "^/swapfile" /etc/fstab || echo "/swapfile none swap sw,pri=100 0 0" >> /etc/fstab

              # Reload systemd and udev
              systemctl daemon-reload
              udevadm control --reload

              # Configure swap parameters
              cat << 'SYSCTL' > /etc/sysctl.d/99-zram.conf
              vm.swappiness = 10
              vm.vfs_cache_pressure = 50
              vm.page-cluster = 0
              SYSCTL

              # Apply sysctl settings
              sysctl -p /etc/sysctl.d/99-zram.conf

              ## Initialize zRAM device
              #echo "$${ZRAM_SIZE}K" > /sys/block/zram0/disksize
              #mkswap -L zram0 /dev/zram0
              #swapon -p -2 /dev/zram0 # Yes, with lower priority than the regular swap because of limited CPU.

              # Install and configure K3s
              curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --token ${var.k3s_token}

              # Configure kubeconfig
              mkdir -p /home/ubuntu/.kube
              cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
              chown ubuntu:ubuntu /home/ubuntu/.kube/config
              chmod 644 /home/ubuntu/.kube/config

              # Make kubeconfig accessible without sudo
              chmod 644 /etc/rancher/k3s/k3s.yaml
              echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /etc/profile
              source /etc/profile

              # Install Helm
              curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
              chmod 700 get_helm.sh
              ./get_helm.sh
              mkdir -p /opt/conf/task_5
              git clone -b task_5 https://github.com/Proffesor94/rsschool-devops-course-tasks.git /opt/conf/task_5
              helm install wordpress /opt/conf/task_5/helm/wordpress/ -f /opt/conf/task_5/helm/wordpress/values.yaml --set wordpress.service.nodePort=32000
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
              set -e

              # Update system and install required packages for extending unified memory
              apt-get update -y
              apt-get install -y curl 
              #apt-get install -y linux-modules-extra-$(uname -r)

              ## Configure zRAM
              #modprobe zram
              #
              ## Create persistent module loading configuration
              #echo "zram" > /etc/modules-load.d/zram.conf
              #echo "options zram num_devices=1" > /etc/modprobe.d/zram.conf
              # 
              ## Calculate zRAM size (100% of total RAM)
              #TOTALMEM=$(free | grep -e "^Mem:" | awk '{print $2}')
              #ZRAM_SIZE=$TOTALMEM
              #
              ## Configure compression algorithm to lzo-rle
              #echo "lzo-rle" > /sys/block/zram0/comp_algorithm
              #
              ## Create udev rule for zRAM device
              #cat << 'UDEVRULE' > /etc/udev/rules.d/99-zram.rules
              #KERNEL=="zram0", ATTR{disksize}="$ZRAM_SIZE"K" RUN="/usr/bin/mkswap -L zram0 /dev/zram0", TAG+="systemd"
              #UDEVRULE

              # Create and configure regular swap partition (1GB)
              dd if=/dev/zero of=/swapfile bs=1M count=1024
              chmod 600 /swapfile
              mkswap /swapfile
              swapon -p 100 /swapfile

              # Add swap entries to fstab
              #grep -q "^/dev/zram0" /etc/fstab || echo "/dev/zram0 none swap defaults,pri=-2 0 0" >> /etc/fstab
              grep -q "^/swapfile" /etc/fstab || echo "/swapfile none swap sw,pri=100 0 0" >> /etc/fstab

              # Reload systemd and udev
              systemctl daemon-reload
              udevadm control --reload

              # Configure swap parameters
              cat << 'SYSCTL' > /etc/sysctl.d/99-zram.conf
              vm.swappiness = 10
              vm.vfs_cache_pressure = 50
              vm.page-cluster = 0
              SYSCTL

              # Apply sysctl settings
              sysctl -p /etc/sysctl.d/99-zram.conf

              ## Initialize zRAM device
              #echo "$${ZRAM_SIZE}K" > /sys/block/zram0/disksize
              #mkswap -L zram0 /dev/zram0
              #swapon -p -2 /dev/zram0 # Yes, with lower priority than the regular swap because of limited CPU.
              
              # Install and configure K3S agent
              until nc -z ${aws_instance.k3s_control_plane.private_ip} 6443; do
              echo "Waiting for K3s server to be ready..."
              sleep 5
              done

              # Install K3s agent and register the worker node
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_control_plane.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s - agent
              EOF
}