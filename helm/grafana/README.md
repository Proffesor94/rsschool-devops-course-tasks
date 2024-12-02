# **Grafana Setup with Reverse Proxy and Dashboard Creation**

This document outlines the steps to set up Grafana with a reverse proxy and create a custom dashboard for Kubernetes metrics.

---

## **Prerequisites**
1. A Kubernetes cluster with Prometheus installed (tested with K3s).
2. Helm installed for deploying Grafana.
3. Reverse proxy server running Nginx to route traffic to Grafana.
4. Basic familiarity with Terraform, Helm, and Kubernetes.

---

## **Part 1: Reverse Proxy Configuration**

### **Step 1: Deploy Nginx with SSL**
The reverse proxy is configured via user data provided to an AWS EC2 instance. The following setup is automated:

- **Nginx installed and configured** to forward requests to the Grafana service (`http://backend`).
- A **self-signed SSL certificate** generated for secure communication.
- Proxy-specific settings for handling timeouts, large file uploads, and WebSocket connections.

**Key proxy settings:**
- **Backend server:** `${aws_spot_instance_request.k3s_control_plane.private_ip}:32001`
- **SSL certificates:** `/etc/nginx/ssl/nginx.crt` and `/etc/nginx/ssl/nginx.key`

### **Step 2: Validate Configuration**
1. Log into the EC2 instance.
2. Check the Nginx status:
   ```bash
   sudo systemctl status nginx
   ```
3. Validate the Nginx configuration:
   ```bash
   sudo nginx -t
   ```

### **Step 3: Test Connectivity**
1. Access Grafana using the public IP of the reverse proxy:
   ```bash
   https://<REVERSE_PROXY_PUBLIC_IP>
   ```
   (Replace `<REVERSE_PROXY_PUBLIC_IP>` with your EC2 instance's public IP.)

---

## **Part 2: Grafana Setup**

### **Step 1: Install Grafana**
Deploy Grafana in the Kubernetes cluster using Helm:
1. Add the Bitnami repository:
   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   ```
2. Deploy Grafana:
   ```bash
   helm upgrade --install grafana bitnami/grafana \
              --namespace monitoring --create-namespace \
              -f /opt/conf/task_8/helm/grafana/values.yaml \
              --set service.type=NodePort \
              --set service.nodePort=32001 \
              --set adminPassword=admin
   ```
   ### **Script Details**
1. **Namespace Creation:** Grafana is installed into the `monitoring` namespace.
2. **Service Type:** Set to `NodePort` to expose Grafana on port `32001`.
3. **Admin Password:** Default password set to `admin` (replace with a secure password for production).
4. **Values File:** `/opt/conf/task_8/helm/grafana/values.yaml` contains custom Grafana configurations.

3. Verify installation:
   ```bash
   kubectl get pods -n monitoring
   ```

### **Step 2: Configure Data Source**
1. Log in to Grafana via the reverse proxy:
   ```bash
   https://<REVERSE_PROXY_PUBLIC_IP>
   ```
   Default credentials:
   - **Username:** `admin`
   - **Password:** `admin` (or as configured in `values.yaml`).
2. Add Prometheus as a data source:
   - URL: `http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`
   - Save and test the connection.

---

## **Part 3: Create Custom Dashboard**

### **Step 1: Add Panels for Metrics**
1. Go to **Dashboards → + Create → New Dashboard**.
2. Add panels with the following queries:
   - **CPU Usage (per Pod):**
     ```promql
     sum(rate(container_cpu_usage_seconds_total{namespace="default", pod!=""}[5m])) by (pod)
     ```
   - **Memory Usage (per Pod):**
     ```promql
     sum(container_memory_usage_bytes{namespace="default", pod!=""}) by (pod)
     ```
   - **Storage Usage (per Pod):**
     ```promql
     sum(container_fs_usage_bytes{namespace="default", pod!=""}) by (pod)
     ```

3. Configure panel settings:
   - Visualization: Select **Graph**.
   - Time Range: Ensure historical data is visible.

### **Step 2: Save the Dashboard**
1. Name the dashboard (e.g., "Kubernetes Cluster Metrics").
2. Set an appropriate **Refresh Interval** (e.g., `30s`).

---

## **Part 4: Testing**
1. Access Grafana via the reverse proxy:
   ```bash
   https://<REVERSE_PROXY_PUBLIC_IP>
   ```
2. Verify:
   - Data source is active.
   - Panels display metrics with historical data.

---

## **Troubleshooting**
- **No data in panels:**
  - Check Prometheus scrape configurations.
  - Ensure Grafana pod has network access to Prometheus.
- **Reverse proxy not working:**
  - Validate Nginx configuration:
    ```bash
    sudo nginx -t
    ```
  - Check EC2 security group rules for port 443.

---

## **Credits**
- Nginx Documentation: [https://nginx.org/](https://nginx.org/)
- Grafana Documentation: [https://grafana.com/docs/](https://grafana.com/docs/)