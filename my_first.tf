provider "google" {
  project = local.project_id
  region  = "us-central1"
  zone    = "us-central1-b"
}

resource "google_project_service" "compute_service" {
  project = local.project_id
  service = "compute.googleapis.com"
}

resource "google_compute_network" "vpc_network" {
  name                            = "quickstart-network"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  depends_on = [
    google_project_service.compute_service
  ]
}

resource "google_compute_subnetwork" "quickstart_subnet" {
  name          = "quickstart-subnet"
  ip_cidr_range = "10.2.0.0/0"
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_route" "quickstart_network_internet_route" {
  name             = "quickstart-network-internet"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.self_link
  next_hop_gateway = "default-internet-gateway"
  priority         = 100
}

resource "google_compute_router" "router" {
  name    = "quickstart-router"
  network = google_compute_network.vpc_network.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "quickstart-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

}

resource "google_compute_instance" "vm_instance" {
  name         = "nginx-instance"
  machine_type = "e2-highcpu-2"

  tags = ["nginx-instance"]

  boot_disk {
    initialize_params {
      image = "centos-7v20210420"
    }
  }

  metadata_startup_script = <<EOT
  curl -fsSL https://get.docker.com -o get-docker.sh &&
  sudo sh get-docker.sh &&
  sudo service docker start &&
  docker run -p 8080:80 -d nginxdemos/hello
  EOT


  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.quickstart_subnet.self_link
    access_config {
      network_tier = "STANDARD"
    }
  }
}




