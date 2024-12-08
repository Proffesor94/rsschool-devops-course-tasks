# Prometheus Alertmanager Setup and Configuration

## Overview

This setup configures Prometheus to use Alertmanager for alert notifications. Alerts are routed to both **Gmail** and **Telegram** for critical and warning-level notifications. The configuration includes Prometheus custom alert rules for high CPU utilization and CPU core capacity exhaustion.

### Requirements
1. **Kubernetes Cluster** (with `kubectl` access)
2. **Helm** installed for package management
3. **Prometheus** and **Alertmanager** set up in the cluster

### Prerequisites
1. You must have Prometheus deployed with a Helm chart and Alertmanager configured.
2. Create a Gmail app password (if using Gmail for alerts) from [Google's App Passwords page](https://myaccount.google.com/apppasswords).
3. Obtain your Telegram Bot token and chat ID from [BotFather](https://core.telegram.org/bots#botfather) and [get your chat ID](https://stackoverflow.com/questions/32423837/what-is-my-telegram-chat-id).

---

## Step 1: Install Prometheus

1. **Add the Prometheus Helm repository:**

   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   ```

2. **Install Prometheus with the custom values file:**

   ```bash
   git clone -b task_9 https://github.com/Proffesor94/rsschool-devops-course-tasks.git /opt/conf/task_9
   helm upgrade install prometheus prometheus-community/prometheus -f /opt/conf/task_9/helm/prometheus/values.yaml
   ```

3. **Wait for Prometheus to be available:**

   ```bash
   kubectl wait --for=condition=Available deployment/prometheus-server --timeout=180s
   ```

4. **Expose Prometheus service:**

   ```bash
   kubectl patch svc prometheus-server -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 9090, "nodePort": 32000}]}}'
   ```

---

## Step 2: Configure Alertmanager

Alertmanager is configured to send alerts to both Gmail and Telegram.

1. **Alertmanager configuration (`alertmanager.yml`):**

   ```yaml
   global:
     resolve_timeout: 1m

   receivers:
     - name: 'gmail-notifications'
       email_configs:
         - to: serfer94@gmail.com
           from: serfer94@gmail.com
           smarthost: smtp.gmail.com:587
           auth_username: serfer94@gmail.com
           auth_identity: serfer94@gmail.com
           auth_password: "password" # Replace with your app password
           send_resolved: true
           headers:
             subject: "Prometheus - Alert"
             text: "{{ range .Alerts }} Hi, \n{{ .Annotations.summary }} \n {{ .Annotations.description }} {{end}} "

     - name: 'telegram'
       telegram_configs:
         - api_url: "https://api.telegram.org"
           bot_token: "token" # Replace with your bot token
           chat_id: 428025159 # Replace with your chat ID

     - name: 'all-notifications'
       email_configs:
         - to: serfer94@gmail.com
           from: serfer94@gmail.com
           smarthost: smtp.gmail.com:587
           auth_username: serfer94@gmail.com
           auth_identity: serfer94@gmail.com
           auth_password: "password" # Replace with your app password
           send_resolved: true
           headers:
             subject: "Prometheus - Alert"
             text: "{{ range .Alerts }} Hi, \n{{ .Annotations.summary }} \n {{ .Annotations.description }} {{end}} "
       telegram_configs:
         - api_url: "https://api.telegram.org"
           bot_token: "token" # Replace with your bot token
           chat_id: 428025159 # Replace with your chat ID

   route:
     group_wait: 10s
     group_interval: 2m
     repeat_interval: 2m
     receiver: 'all-notifications'
   ```

---

## Step 3: Define Alert Rules

Create custom alert rules that will trigger based on CPU utilization and capacity:

1. **Alert Rule for High CPU Utilization:**

   ```yaml
   groups:
     - name: k8s-rules
       rules:
         - alert: HighCpuUtilization
           expr: |
             sum(rate(node_cpu_seconds_total{mode!="idle"}[2m])) / sum(machine_cpu_cores) > 0.8
           for: 1m
           labels:
             severity: warning
           annotations:
             summary: "High CPU utilization detected on node {{ $labels.instance }}"
             description: "Node {{ $labels.instance }} is using over 80% CPU for the last 1 minute."
   ```

2. **Alert Rule for CPU Cores Capacity Exhaustion:**

   ```yaml
         - alert: CpuCoresCapacityExhausted
           expr: |
             sum(machine_cpu_cores) - sum(rate(node_cpu_seconds_total{mode!="idle"}[2m])) < 1
           for: 1m
           labels:
             severity: critical
           annotations:
             summary: "CPU cores capacity almost exhausted on node {{ $labels.instance }}"
             description: "Node {{ $labels.instance }} has less than 1 core available for allocation."
   ```

3. **Save the alert rules as `alerting_rules.yml`** under the `serverFiles` section in the Prometheus values file.

---

## Step 4: Apply Configuration

1. **Apply the Alertmanager configuration** to Prometheus via Helm:

   ```bash
   helm upgrade install prometheus prometheus-community/prometheus -f /opt/conf/task_9/helm/prometheus/values.yaml
   ```

2. **Check the logs** to verify that the alerts are being processed and sent to the specified receivers:

   ```bash
   kubectl logs <alertmanager-pod-name>
   ```

---

## Step 5: Testing Alerts

To test the alert configuration using a stress test on your Kubernetes cluster, you can use the following test case.

1. **Run a CPU Stress Test Pod**:

   This command will run a stress test that will generate CPU load on two cores for 130 seconds. The test is done using the `stress-ng` tool inside an Alpine container.

   ```bash
   kubectl run cpu-stress --image=alpine --restart=Never -- sh -c "apk add stress-ng && stress-ng --cpu 2 --timeout 130s"
   ```

   This will:
   - Start a pod named `cpu-stress`.
   - Install `stress-ng` inside the container.
   - Run a CPU stress test using 2 CPU cores for 130 seconds.

2. **Check Pod Status**:

   After running the command, verify the pod is running:

   ```bash
   kubectl get pods
   ```

   You should see the `cpu-stress` pod running.

3. **Verify Prometheus Alerts**:

   During the stress test, Prometheus should detect high CPU utilization (assuming you have the alert configured for CPU usage over 80%). You can verify the alert status in the Prometheus web UI:

   - Open Prometheus at `https://<bastion-ip>`.
   - Navigate to the **Alerts** tab to check for any active alerts.
   - You should see the alert for `HighCpuUtilization` being triggered during the stress test if the CPU usage exceeds 80%.

4. **Check Email and Telegram Notifications**:

   If you have configured Alertmanager to send alerts to both Gmail and Telegram, you should receive the following:
   - **Gmail**: An email notification with the subject "Prometheus - Alert" with details about the CPU utilization.
   - **Telegram**: A message in your Telegram chat indicating high CPU utilization.

5. **Cleanup**:

   Once the stress test is completed and you have verified the alerts, you can delete the pod:

   ```bash
   kubectl delete pod cpu-stress
   ```

### Expected Outcome:
- You should receive an alert when CPU utilization exceeds 80% during the stress test.
- The alert should trigger both Gmail and Telegram notifications as defined in the Alertmanager configuration.

### Troubleshooting:
- If you do not receive alerts, check the following:
  - **Alertmanager Logs**: Ensure the alertmanager is properly receiving and forwarding the alerts.
  - **Prometheus Metrics**: Ensure the `node_cpu_seconds_total` metric is being scraped correctly by Prometheus.
  - **Alertmanager Configuration**: Verify that the email and Telegram configurations are correct, especially the authentication credentials and bot token.

---

## Troubleshooting

- If you do not receive alerts, check the following:
  - **Alertmanager Logs**: Review the logs for errors:
    ```bash
    kubectl logs <alertmanager-pod-name> -n monitoring
    ```
  - **Configuration Validation**: Ensure that the paths for email and Telegram bot configurations are correct.

---

## Conclusion

This setup integrates Prometheus with Alertmanager and configures it to send alerts via both Gmail and Telegram. The alert rules monitor CPU utilization and availability of CPU cores, triggering emails and Telegram notifications when thresholds are exceeded.

