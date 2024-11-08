# wordpress Helm Chart

This Helm chart is designed to deploy wordpress on a Kubernetes cluster. It includes all the necessary configurations, including service accounts, permissions, persistent storage, and service exposure to make wordpress accessible outside the cluster.

## Prerequisites

- Kubernetes cluster (minimum version 1.16)

- Helm 3.x

- Persistent Volume provisioner support in the underlying infrastructure

## Chart Structure

```bash
├── Chart.yaml  
├── README.md  
├── templates  
│   ├── deployment.yaml  
│   ├── namespace.yaml  
│   ├── pv.yaml  
│   ├── pvc.yaml  
│   ├── role.yaml  
│   ├── rolebinding.yaml  
│   ├── service.yaml  
│   ├── serviceaccount.yaml  
│   └── storageclass.yaml  
└── values.yaml  
```

## File Descriptions

- **Chart.yaml**: Metadata about the Helm chart, such as name, version, and description
- **README.md**: Instructions and information about the Helm chart, including installation steps and structure
- **templates/**: Directory containing Kubernetes resource templates
  - **deployment.yaml**: Defines the wordpress deployment, including replicas, containers, volumes, and probes
  - **namespace.yaml**: Creates a dedicated namespace for wordpress
  - **pv.yaml**: Defines the PersistentVolume (PV) for wordpress data storage
  - **pvc.yaml**: Defines the PersistentVolumeClaim (PVC) for wordpress, which requests storage from the PV
  - **role.yaml**: Creates a ClusterRole with necessary permissions for wordpress
  - **rolebinding.yaml**: Binds the service account to the ClusterRole for wordpress permissions
  - **service.yaml**: Defines the wordpress service to expose it within or outside the cluster
  - **serviceaccount.yaml**: Creates a ServiceAccount specifically for wordpress
  - **storageclass.yaml**: Defines a StorageClass, if custom storage provisioning is required
- **values.yaml**: Default configuration values for the chart, including image version, resource limits, storage settings, and service type

## Installation

To install the Wordpress Helm chart in the namespace `wordpress` with default values, use:
```bash
helm install wordpress ./helm/wordpress --namespace wordpress --create-namespace
```
To override default values, specify a custom values.yaml file:
```bash
helm install wordpress ./helm/wordpress --namespace wordpress -f custom-values.yaml
```

## Upgrading the Chart

To upgrade the wordpress Helm chart with new values or chart updates, use:
```bash
helm upgrade wordpress ./wordpress-helm-chart --namespace wordpress -f custom-values.yaml
```
## Uninstalling the Chart

To uninstall the wordpress Helm chart and remove all associated resources, use:
```bash
helm uninstall wordpress --namespace wordpress
```

## Monitoring and Logs

To check the status of the wordpress deployment, use:
```bash
kubectl get deployment wordpress -n wordpress
```
To view the status of pods associated with wordpress, use:
```bash
kubectl get pods -n wordpress
```
To view logs of the wordpress pod, first identify the pod name, then use:
```bash
kubectl logs <wordpress-pod-name> -n wordpress
```
To follow the logs in real-time, use:
```bash
kubectl logs -f <wordpress-pod-name> -n wordpress
```
