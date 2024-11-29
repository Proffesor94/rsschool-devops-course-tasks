# Bastion Host
resource "aws_instance" "bastion" {
  ami                         = var.aws_linux_ami
  instance_type               = var.aws_linux_instance_type
  subnet_id                   = aws_subnet.public_subnets[0].id
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  depends_on                  = [aws_spot_instance_request.k3s_control_plane]
  user_data                   = <<-EOF
              #!/bin/bash
              set -e
              # Update package list and install Nginx
              apt update -y && apt install -y nginx
              # Create Nginx reverse proxy configuration
              cat << NGINXCONF > /etc/nginx/sites-available/reverse-proxy
              upstream backend {
                  server ${aws_spot_instance_request.k3s_control_plane.private_ip}:32000;
                  keepalive 32;
              }

              server {
                  listen 443 ssl;
                  server_name _;

                  # SSL configuration
                  ssl_certificate /etc/nginx/ssl/nginx.crt;
                  ssl_certificate_key /etc/nginx/ssl/nginx.key;
                  ssl_protocols TLSv1.2 TLSv1.3;
                  ssl_ciphers HIGH:!aNULL:!MD5;

                  # Timeouts
                  proxy_connect_timeout 300;
                  proxy_send_timeout 300;
                  proxy_read_timeout 300;
                  send_timeout 300;

                  # WordPress specific settings
                  index index.php;
                  location / {
                      proxy_pass http://backend;

                      # WordPress headers
                      proxy_set_header Host \$http_host;
                      proxy_set_header X-Real-IP \$remote_addr;
                      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                      proxy_set_header X-Forwarded-Proto \$scheme;
                      proxy_set_header X-Forwarded-Host \$http_host;
                      proxy_set_header X-Forwarded-Port \$server_port;

                      # Fix WordPress admin
                      proxy_redirect off;
                      proxy_buffering off;

                      # WebSocket support
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade \$http_upgrade;
                      proxy_set_header Connection "upgrade";

                      # Buffer settings
                      proxy_buffer_size 128k;
                      proxy_buffers 4 256k;
                      proxy_busy_buffers_size 256k;
                  }

                  # Prevent access to WordPress config
                  location = /wp-config.php {
                      deny all;
                  }

                  # Handle PHP files
                  location ~ \.php$ {
                      proxy_pass http://backend;
                      proxy_set_header Host \$http_host;
                      proxy_set_header X-Real-IP \$remote_addr;
                      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                      proxy_set_header X-Forwarded-Proto \$scheme;
                      proxy_set_header X-Forwarded-Host \$http_host;
                      proxy_set_header X-Forwarded-Port \$server_port;
                  }

                  # HTTP to HTTPS redirect
                  error_page 497 https://\$host\$request_uri;

                  # Large file uploads
                  client_max_body_size 64M;
              }

              # HTTP redirect
              server {
                  listen 8080;
                  server_name _;
                  return 301 https://\$host\$request_uri;
              }
              NGINXCONF
              # Create SSL certificate directory
              mkdir -p /etc/nginx/ssl

              # Generate self-signed certificate
              openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                  -keyout /etc/nginx/ssl/nginx.key \
                  -out /etc/nginx/ssl/nginx.crt \
                  -subj "/C=US/ST=State/L=City/O=Organization/CN=$(curl -s ifconfig.me)"

              # Set proper permissions
              chmod 600 /etc/nginx/ssl/nginx.key

              # Remove default config and create symbolic link
              rm -f /etc/nginx/sites-enabled/default
              ln -sf /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/
              nginx -t
              systemctl restart nginx
              EOF
  tags = {
    Name    = "Bastion Host"
    Owner   = "Pavel Shumilin"
    Project = "Task 6"
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
resource "aws_spot_instance_request" "k3s_control_plane" {
  ami                            = var.aws_linux_ami
  instance_type                  = "t3.small"
  key_name                       = var.ssh_key_name
  subnet_id                      = aws_subnet.private_subnets[0].id
  vpc_security_group_ids         = [aws_security_group.k3s_sg.id]
  spot_price                     = "0.02" # Set your maximum price
  wait_for_fulfillment           = true
  spot_type                      = "persistent" # Makes the request persistent
  instance_interruption_behavior = "stop"       # Options: stop or terminate

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

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
              mkdir -p /opt/conf/task_6
              #git clone -b task_5 https://github.com/Proffesor94/rsschool-devops-course-tasks.git /opt/conf/task_5
              #helm install wordpress /opt/conf/task_5/helm/wordpress/ -f /opt/conf/task_5/helm/wordpress/values.yaml --set wordpress.service.nodePort=32000
              git clone -b task_6 https://github.com/Proffesor94/rsschool-devops-course-tasks.git /opt/conf/task_6
              #kubectl wait --for=condition=Available deployment/coredns -n kube-system --timeout=180s
              helm install jenkins /opt/conf/task_6/helm/jenkins/ -f /opt/conf/task_6/helm/jenkins/values.yaml --set jenkins.service.nodePort=32000
              kubectl create secret generic jenkins-kubernetes-credentials   --from-file=kubeconfig=/etc/rancher/k3s/k3s.yaml -n jenkins
              EOF
}

## K3s Worker Node
#resource "aws_instance" "k3s_worker" {
#  ami                    = var.aws_linux_ami
#  instance_type          = "t3.micro"
#  key_name               = var.ssh_key_name
#  subnet_id              = aws_subnet.private_subnets[0].id
#  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
#  depends_on             = [aws_instance.k3s_control_plane]
#  tags = {
#    Name = "k3s-worker"
#  }
#  user_data = <<-EOF
#              #!/bin/bash
#              set -e
#
#              # Update system and install required packages for extending unified memory
#              apt-get update -y
#              apt-get install -y curl 
#              #apt-get install -y linux-modules-extra-$(uname -r)
#
#              ## Configure zRAM
#              #modprobe zram
#              #
#              ## Create persistent module loading configuration
#              #echo "zram" > /etc/modules-load.d/zram.conf
#              #echo "options zram num_devices=1" > /etc/modprobe.d/zram.conf
#              # 
#              ## Calculate zRAM size (100% of total RAM)
#              #TOTALMEM=$(free | grep -e "^Mem:" | awk '{print $2}')
#              #ZRAM_SIZE=$TOTALMEM
#              #
#              ## Configure compression algorithm to lzo-rle
#              #echo "lzo-rle" > /sys/block/zram0/comp_algorithm
#              #
#              ## Create udev rule for zRAM device
#              #cat << 'UDEVRULE' > /etc/udev/rules.d/99-zram.rules
#              #KERNEL=="zram0", ATTR{disksize}="$ZRAM_SIZE"K" RUN="/usr/bin/mkswap -L zram0 /dev/zram0", TAG+="systemd"
#              #UDEVRULE
#
#              # Create and configure regular swap partition (1GB)
#              dd if=/dev/zero of=/swapfile bs=1M count=1024
#              chmod 600 /swapfile
#              mkswap /swapfile
#              swapon -p 100 /swapfile
#
#              # Add swap entries to fstab
#              #grep -q "^/dev/zram0" /etc/fstab || echo "/dev/zram0 none swap defaults,pri=-2 0 0" >> /etc/fstab
#              grep -q "^/swapfile" /etc/fstab || echo "/swapfile none swap sw,pri=100 0 0" >> /etc/fstab
#
#              # Reload systemd and udev
#              systemctl daemon-reload
#              udevadm control --reload
#
#              # Configure swap parameters
#              cat << 'SYSCTL' > /etc/sysctl.d/99-zram.conf
#              vm.swappiness = 10
#              vm.vfs_cache_pressure = 50
#              vm.page-cluster = 0
#              SYSCTL
#
#              # Apply sysctl settings
#              sysctl -p /etc/sysctl.d/99-zram.conf
#
#              ## Initialize zRAM device
#              #echo "$${ZRAM_SIZE}K" > /sys/block/zram0/disksize
#              #mkswap -L zram0 /dev/zram0
#              #swapon -p -2 /dev/zram0 # Yes, with lower priority than the regular swap because of limited CPU.
#              
#              # Install and configure K3S agent
#              until nc -z ${aws_instance.k3s_control_plane.private_ip} 6443; do
#              echo "Waiting for K3s server to be ready..."
#              sleep 5
#              done
#
#              # Install K3s agent and register the worker node
#              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_control_plane.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s - agent
#              EOF
#}