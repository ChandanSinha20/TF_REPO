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

resource "google_compute_firewall" "instance_public_connectivity" {
  name    = "public-ssh"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nginx-instance"]

}

resource "google_compute_instance_group" "webservers" {
  name        = "terraform-webservers"
  description = "terraform test instance group"

  instances = [google_compute_instance.vm_instance.self_link]

  named_port {
    name = "http"
    port = "8080"
  }
}
#global health check

resource "google_compute_health_check" "webservers-health-check" {
  name        = "webserver-health-check"
  description = "health check via tcp"

  timeout_sec         = 3
  check_interval_sec  = 3
  healthy_threshold   = 1
  unhealthy_threshold = 2

  tcp_health_check {
    port_name = "http"
  }

  depends_on = [
    google_project_service.compute_service
  ]


}

resource "google_compute_backend_service" "webservers-backend-service" {
  name                            = "webservers-backend-service"
  timeout_sec                     = 30
  connection_draining_timeout_sec = 10
  load_balancing_scheme           = "EXTERNAL"
  protocol                        = "HTTP"
  port_name                       = "http"
  health_checks                   = [google_compute_health_check.webservers-health-check.self_link]


  backend {
    group          = google_compute_instance_group.webservers.self_link
    balancing_mode = "UTILIZATION"
  }
}

resource "google_compute_url_map" "default" {

  name            = "nginx-url-map"
  default_service = google_compute_backend_service.webservers-backend-service.self_link
}

# global http proxy

resource "google_compute_target_http_proxy" "default" {
  name    = "nginx-http-proxy"
  url_map = google_compute_url_map.default.id

}

resource "google_compute_forwarding_rule" "webservers-loadbalancer" {
  name                  = "nginx-forwarding-rule"
  ip_protocol           = "TCP"
  port_range            = 80
  load_balancing_scheme = "EXTERNAL"
  network_tier          = "STANDARD"
  target                = google_compute_target_http_proxy.default.id
}


resource "google_compute_firewall" "load_balancer_inbound" {
  name    = "nginx-load-balancer"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["nginx-instance"]


}

