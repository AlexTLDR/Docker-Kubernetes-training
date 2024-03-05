resource "google_container_cluster" "primary" {
    name = "${var.gke_cluster_name}-${var.application_name}"
    # location = var.region # for learning purposes, we will use zone. This creates only one node pool instead of 3
    location = var.zone
    remove_default_node_pool = true
    initial_node_count = 1
    deletion_protection = "false"
    network = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link
}

resource "google_container_node_pool" "primary_nodes" {
    name = "${google_container_cluster.primary.name}-node-pool"
    # location = var.region # for learning purposes, we will use zone. This creates only one node pool instead of 3
    location = var.zone
    cluster = google_container_cluster.primary.name
    node_count = var.gke_num_nodes

    node_config {
      oauth_scopes = [
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
      ]

      machine_type = var.machine_type
      metadata = {
        disable-legacy-endpoints = "true"
      }
    }
}

resource "google_redis_instance" "memory-store-primary" {
    name = "${var.memory_storage_name}-memory-store-primary"
    memory_size_gb = 1
    region = var.region
    authorized_network = google_compute_network.vpc.self_link
    project = var.project_id
    tier = var.tier
}

resource "google_storage_bucket" "cloud-storage-primary" {
    name = "cs-${var.application_name}"
    location = var.region
    force_destroy = true
    uniform_bucket_level_access = true

    lifecycle_rule {
      condition {
        age = 3
      }
      action{
        type = "SetStorageClass"
        storage_class = "REGIONAL"
      }
    }
    versioning {
      enabled = false
    }
}