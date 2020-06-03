provider "google" {
    credentials = file(var.credentials)
    project = var.project
    region  = var.region
    zone    = var.zone
}

data "google_client_config" "provider" {}

data "google_container_cluster" "gke_cluster" {
  name     = "gke-cluster"
  location = "europe-west1"
}

provider "kubernetes" {
  load_config_file = false

  host  = "https://${data.google_container_cluster.gke_cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate,
  )
}

resource "kubernetes_namespace" "flux" {
  metadata {
    name = "flux"
  }
  
  #this is a hack to install flux CRD, when this https://www.hashicorp.com/blog/deploy-any-resource-with-the-new-kubernetes-provider-for-hashicorp-terraform 
  # becames available I shoudl change
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials gke-cluster --region europe-west1"
  }
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/1.1.0/deploy/crds.yaml"
  }
}

resource "helm_release" "helm-operator" {
  name       = "helm-operator"
  repository = "https://charts.fluxcd.io"
  chart      = "helm-operator"
  namespace  = kubernetes_namespace.flux.metadata[0].name

  set {
    name  = "helm.versions"
    value = "v3"
  }
}

resource "helm_release" "flux" {
  name       = "flux"
  repository = "https://charts.fluxcd.io"
  chart      = "flux"
  namespace  = kubernetes_namespace.flux.metadata[0].name
  version    = "1.3.0"

  set {
    name  = "helm.versions"
    value = "v3"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "helmOperator.create"
    value = "true"
  }

  set {
    name  = "git.url"
    value = "git@github.com:eduardodbr/kubernetes-env.git"
  }

  set {
    name  = "git.branch"
    value = "master"
  }

  set {
    name  = "git.path"
    value = "releases/"
  }

  set {
    name  = "git.pollInterval"
    value = "300s"
  }

  provisioner "local-exec" {
    command = "fluxctl identity --k8s-fwd-ns flux"
  }  
}

resource "kubernetes_namespace" "log" {
  metadata {
    name = "log"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "kafka"
  }
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}

resource "kubernetes_namespace" "production" {
  metadata {
    name = "production"
  }
}

resource "kubernetes_namespace" "canary" {
  metadata {
    name = "canary"
  }
}

resource "kubernetes_secret" "grafana-credentials" {
  metadata {
    name = "grafana-credentials"
    namespace = "monitoring" #this should probably be a var
  }

  data = {
    grafana-user = var.grafana_user
    grafana-password = var.grafana_password
  }
}

resource "kubernetes_secret" "jenkins-login-credentials" {
  metadata {
    name = "jenkins-login-credentials"
    namespace = "jenkins" #this should probably be a var
  }

  data = {
    jenkins-admin-user = var.jenkins_user
    jenkins-admin-password= var.jenkins_password
  }
}