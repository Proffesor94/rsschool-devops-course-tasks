# WordPress Helm Chart

This Helm Chart deploys WordPress and MySQL in a separate namespace `wordpress` using NodePort for external access to WordPress. The chart automatically creates necessary Deployment, Service, and PersistentVolumeClaim resources for both applications.

## Chart Structure

- Chart.yaml — Helm chart metadata
- values.yaml — main configuration settings for WordPress and MySQL, including images, services, storage, and resource limits
- templates/namespace.yaml — creates the `wordpress` namespace
- templates/wp-deployment.yaml — creates the Deployment for WordPress
- templates/wp-service.yaml — creates the NodePort Service for WordPress
- templates/wp-pvc.yaml — creates the PersistentVolumeClaim for WordPress
- templates/mysql-deployment.yaml — creates the Deployment for MySQL
- templates/mysql-service.yaml — creates the Service for MySQL
- templates/mysql-pvc.yaml — creates the PersistentVolumeClaim for MySQL

## Deploying the Chart

1. Install the Helm chart in the `wordpress` namespace
```bash
helm install wordpress ./wordpress --namespace wordpress --create-namespace
```

2. Verify that all resources have been successfully deployed
```bash
kubectl get all -n wordpress
```
## Viewing the List of Pods

To view all pods in the `wordpress` namespace, run
```bash
kubectl get pods -n wordpress
```
## Connecting to Each Pod

To connect to a pod, use the `exec` command. For example, to connect to a WordPress pod
```bash
kubectl exec -it <wordpress-pod-name> -n wordpress -- /bin/bash
```
To connect to a MySQL pod
```bash
kubectl exec -it <mysql-pod-name> -n wordpress -- /bin/bash
```
## Viewing Logs

To view the logs for each pod, use the `logs` command. For example, to view WordPress logs
```bash
kubectl logs <wordpress-pod-name> -n wordpress
```
For MySQL logs
```bash
kubectl logs <mysql-pod-name> -n wordpress
```
