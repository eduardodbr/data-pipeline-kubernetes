

# Terraform

1. Creates a GKE cluster
2. Installs FluxCD and all the necessary namespaces on the kubernetes. 
3. The output is a private key that should be added to the repo (with write permissions) that flux will monitor.

# Kubernetes

Flux is configured to monitor the `releases/` directory. Any mianifest within that directory is going to be deployed to kuberntes.
The following services were deployed:

1. Prometheus-Operator (prometheus + Grafana + Alertmanager)
    - Creates a custom dashboard to monitor kafka.
    - The Grafana credentials are defined by Terraform.
2. EFK stack (Elasticseach, Fluentd, Kibana) and elastic-exporter for monitoring
    - Fluentd is deployed as a daemonset and the logs are sent with the respective pod name.
    - Kibana has a postStart lifecycle to create the indexes for: kafka prometheus elasticsearch kube-dns kube-proxy alertmanager
3. Kafka 
4. Jenkins - Although Flux already does CD I also decided to deploy Jenkins to build an entire CI/CD pipeline that can be found [here](https://github.com/eduardodbr/jenkins-pipeline).
    - Credentials must be set using Secrets :
        ```
        apiVersion: v1
        kind: Secret
        metadata:
          name: jenkins-credentials
        data:
          credentials.xml: the-base64-enconde-of-credentials.xml
        ```
        ```
        apiVersion: v1
        kind: Secret
        metadata:
          name: jenkins-secrets-secret
        data:
          master.key: the-base64-enconde-of-master.key
          hudson.util.Secret: the-base64-enconde-of-hudson.util.Secret
        ```
    - The pipeline must be created using jenkins UI
    - This CI/CD builds and deploys a test app to produce mock data to kafka. Can be usefull to test the entire environment.
 

### manually sync  flux with the repo
fluxctl sync --k8s-fwd-ns flux

### generate a new access key and add it to github
fluxctl identity --k8s-fwd-ns flux
