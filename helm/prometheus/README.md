# **Prometheus Deployment on K3s Cluster**

This document outlines the steps and configurations used to deploy Prometheus on a single-node K3s cluster using Helm. The setup optimizes resource usage for a single-node environment and exposes Prometheus using a NodePort for accessibility.

----------

## **Prerequisites**

-   A running K3s cluster (single-node setup).
-   Helm installed on the cluster node.
-   Git installed for cloning the configuration repository.

----------

## **Configuration**

### **Helm Chart Values**

The custom configuration for Prometheus is located in `helm/prometheus/values.yaml` and includes the following:

-   **Global Settings**:
    
    -   Scrape interval: 15 seconds.
    -   Evaluation interval: 15 seconds.
-   **Prometheus Settings**:
    
    -   Exposed via NodePort `32000`.
    -   Configured with resource limits and requests optimized for a single-node setup.
    -   Data retention set to 7 days.
-   **Disabled Components**:
    
    -   Alertmanager and Grafana are disabled to conserve resources.
-   **Node Exporter and Kube State Metrics**:
    
    -   Enabled and configured with minimal resource requests and limits.

----

### **Cloud-Init Script**

The cloud-init script was modified to automate the deployment of Prometheus during the instance initialization:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
git clone -b task_7 https://github.com/Proffesor94/rsschool-devops-course-tasks.git /opt/conf/task_7
helm upgrade --install prometheus bitnami/kube-prometheus --namespace monitoring --create-namespace -f /opt/conf/task_7/helm/prometheus/values.yaml
```

This script:

1.  Adds the Bitnami Helm repository.
2.  Updates Helm repositories.
3.  Clones the task-specific repository containing the Prometheus configuration.
4.  Installs or upgrades the `kube-prometheus` Helm chart using the custom values file.

----------

## **Deployment Steps**

1.  Provision the K3s node and ensure the cloud-init script is executed.
2.  Verify the Helm chart installation:
    
    ```bash
    kubectl get pods -n monitoring
    kubectl get svc -n monitoring
    ```
    
3.  Access the Prometheus UI:
    -   Navigate to `http://<NODE-IP>:32000` in your browser.

----------

## **Expected Output**

### **Verify Pods**

```bash
kubectl get pods -n monitoring
```

Sample output:

```
NAME                                                            READY   STATUS    RESTARTS   AGE
prometheus-kube-prometheus-blackbox-exporter-757d7b5977-6wrxj   1/1     Running   0          5m26s
prometheus-kube-prometheus-operator-764fd85d4b-ssnhq            1/1     Running   0          5m26s
prometheus-kube-state-metrics-7f799458f5-smvxf                  1/1     Running   0          5m26s
prometheus-node-exporter-mcf6b                                  1/1     Running   0          5m26s
prometheus-prometheus-kube-prometheus-prometheus-0              2/2     Running   0          5m5s
```

### **Verify Service**

```bash
kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring
```

Sample output:

```
NAME                                    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
prometheus-kube-prometheus-prometheus   NodePort   10.43.191.163   <none>        9090:32000/TCP   5m
```

----------

## **Access Prometheus**

-   Open `http://<NODE-IP>:32000` in a browser to view the Prometheus web interface.
-   Verify the collection of metrics, such as CPU and memory usage, for the node.

----------

## **Troubleshooting**

1.  **Service Not Accessible**:
    
    -   Ensure the NodePort `32000` is open in your AWS Security Group or firewall.
    -   Verify the service:
        
        ```bash
        kubectl describe svc prometheus-kube-prometheus-prometheus -n monitoring
        ```
        
2.  **Pod Not Running**:
    
    -   Check the logs for any issues:
        
        ```bash
        kubectl logs <POD-NAME> -n monitoring
        ```
        

----------

## **Conclusion**

This setup successfully deploys Prometheus using Helm with a custom configuration optimized for a single-node K3s cluster. The cloud-init script automates the installation process, ensuring a repeatable and reliable deployment.