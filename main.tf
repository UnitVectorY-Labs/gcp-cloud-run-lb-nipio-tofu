provider "google" {
  project = var.project_id
}

locals {
  load_balancer_domain = "${var.app_name}-${replace(google_compute_global_address.load_balancer_ip.address, ".", "-")}.nip.io"
}

# Create a global static IP address for the load balancer
resource "google_compute_global_address" "load_balancer_ip" {
  name        = "${var.app_name}-ip"
  description = "Static IP address for the load balancer"
}

# Create Artifact Registry repositories in each region
resource "google_artifact_registry_repository" "repos" {
  for_each      = toset(var.regions)
  location      = each.key
  repository_id = "${var.app_name}-${each.key}-repo"
  description   = "Proxy Container Registry for ${var.app_name} in ${each.key}"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  remote_repository_config {
    docker_repository {
      custom_repository {
        uri = var.root_repository
      }
    }
  }
}

# Service account for Cloud Run services
resource "google_service_account" "cloud_run_sa" {
  project      = var.project_id
  account_id   = "${var.app_name}-sa"
  display_name = "${var.app_name} service account"
}

# Deploy Cloud Run services in each region
resource "google_cloud_run_v2_service" "services" {
  for_each = toset(var.regions)
  name     = "${var.app_name}-${each.value}"
  location = each.value
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      image = "${each.value}-docker.pkg.dev/${var.project_id}/${var.app_name}-${each.value}-repo/${var.image}:${var.image_tag}"
    }
  }

  depends_on = [google_artifact_registry_repository.repos]
}

# Allow unauthenticated access to Cloud Run services
resource "google_cloud_run_service_iam_member" "noauth" {
  for_each   = toset(var.regions)
  location   = each.key
  service    = google_cloud_run_v2_service.services[each.key].name
  role       = "roles/run.invoker"
  member     = "allUsers"
  depends_on = [google_cloud_run_v2_service.services]
}

# Create Serverless NEGs for each Cloud Run service
resource "google_compute_region_network_endpoint_group" "neg" {
  for_each              = toset(var.regions)
  name                  = "${var.app_name}-neg-${each.key}"
  region                = each.key
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.services[each.key].name
  }
}

# Define the SSL policy
resource "google_compute_ssl_policy" "tls_policy" {
  name = "${var.app_name}-tls-policy"
  profile = "RESTRICTED"
  min_tls_version = "TLS_1_2"
}

# Use the lb-http module to create a global load balancer
module "gclb" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 9.0"

  project = var.project_id
  name    = var.app_name

  backends = {
    for region in var.regions : region => {
      enable_cdn = false

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group = google_compute_region_network_endpoint_group.neg[region].id # Reference the NEG
        }
      ]

      iap_config = {
        enable = false
      }
    }
  }

  http_forward = false # Not supporting unencrypted traffic

  url_map = "default" # Change to a string representing the default URL map

  ssl = true # Just set this to true

  managed_ssl_certificate_domains = [local.load_balancer_domain] # Use the domain for the managed SSL certificate

  create_address = false
  address = google_compute_global_address.load_balancer_ip.address

  ssl_policy = google_compute_ssl_policy.tls_policy.name # Reference the SSL policy

  depends_on = [
    google_compute_region_network_endpoint_group.neg,
    google_artifact_registry_repository.repos
  ]
}