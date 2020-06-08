credentials         = "~/k8s-the-hard-way-277515-e1c76f53fc3c.json"
project             = "k8s-the-hard-way-277515"
region              = "europe-west1"
zone                = "europe-west1-b"
node_pools          = [
  {
    name                       = "default"
    node_count                 = 1
    autoscaling_min_node_count = 3
    autoscaling_max_node_count = 6
    node_config_machine_type   = "n1-standard-1"
    node_config_disk_type      = "pd-standard"
    node_config_disk_size_gb   = 100
    node_config_preemptible    = false
  },
  {
    name                       = "spark"
    node_count                 = 1
    autoscaling_min_node_count = 1
    autoscaling_max_node_count = 5
    node_config_machine_type   = "n1-standard-2"
    node_config_disk_type      = "pd-standard"
    node_config_disk_size_gb   = 100
    node_config_preemptible    = false
  },
]
