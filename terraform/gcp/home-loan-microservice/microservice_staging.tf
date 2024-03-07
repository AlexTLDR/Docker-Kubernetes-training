module "microservice_staging" {
  source = "./modules/microservice-module"

  gke_cluster_name = "gke-home-loan-staging"
  region           = var.region
  pods_per_nodes   = 25
  vpc              = google_compute_network.vpc.self_link
  subnet           = google_compute_subnetwork.subnet.self_link

  google_container_node_pool_name = "gke-home-loan-node-pool-staging"
  gke_num_nodes                   = 1
  machine_type                    = "e2-micro"

  memory_storage_name = "memory-store-home-loan-staging"
  memory_size_gb      = 1
  tier                = "BASIC"
  project_id          = var.project_id

  application_name = "cs-home-loan-staging"
  versioning       = false
} 