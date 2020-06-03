provider "google" {
    credentials = file(var.credentials)
    project = var.project
    region  = var.region
    zone    = var.zone
}


module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 2.3"

    project_id   = var.project
    network_name = "gke-vpc-bk"

    subnets = [
        {
            subnet_name           = "gke-subnet-public"
            subnet_ip             = "10.0.3.0/24"
            subnet_region         = var.region
        },
        {
            subnet_name           = "gke-subnet-private"
            subnet_ip             = "10.0.4.0/24"
            subnet_region         =  var.region
            subnet_private_access = "true"
        }
    ]
}


resource "google_container_cluster" "gke_cluster" {
  name               = "gke-cluster"
  location           = var.region
  initial_node_count = 1
  remove_default_node_pool = true

  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets_names[0]

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

   #I disable gcloud auth to free resources
    logging_service = "none"
    monitoring_service = "none"
}

#we might want to create several node pools
resource "google_container_node_pool" "gke_node_pool" {
    count       = length(var.node_pools)
    name        = format("gke-node-pool-%s",lookup(var.node_pools[count.index],"name"))
    location    = google_container_cluster.gke_cluster.location
    cluster     = google_container_cluster.gke_cluster.name
    node_count  = lookup(var.node_pools[count.index], "node_count", 1) # at least 1 node per zone inside the region

    autoscaling {
        min_node_count = lookup(var.node_pools[count.index], "autoscaling_min_node_count", 2)
        max_node_count = lookup(var.node_pools[count.index], "autoscaling_max_node_count", 3)
    }

    node_config {
        machine_type = lookup(var.node_pools[count.index], "node_config_machine_type", "n1-standard-1")
        disk_size_gb = lookup(var.node_pools[count.index],"node_config_disk_size_gb",100)
        disk_type = lookup(var.node_pools[count.index],"node_config_disk_type","pd-standard")

        metadata = {
        disable-legacy-endpoints = "true"
        }

        oauth_scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
        ]
    }
}