provider "google" {
  project = var.project_id
}

data "google_project" "project" {
  project_id = var.project_id
}

locals {
  load_balancer_domain = "${var.app_name}-${replace(google_compute_global_address.load_balancer_ip.address, ".", "-")}.nip.io"
}

resource "google_compute_global_address" "load_balancer_ip" {
  name        = "${var.app_name}-ip"
  description = "Static IP address for the load balancer"
}

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

resource "google_service_account" "cloud_run_sa" {
  project      = var.project_id
  account_id   = "${var.app_name}-sa"
  display_name = "${var.app_name} service account"
}

resource "google_cloud_run_v2_service" "services" {
  for_each = toset(var.regions)
  name     = "${var.app_name}-${each.value}"
  location = each.value
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  deletion_protection = false

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      image = "${each.value}-docker.pkg.dev/${var.project_id}/${var.app_name}-${each.value}-repo/${var.image}:${var.image_tag}"
    }
  }

  depends_on = [
    google_artifact_registry_repository.repos
  ]
}

resource "google_cloud_run_service_iam_member" "iap_invoker" {
  for_each   = var.iap_enabled ? toset(var.regions) : toset([])
  location   = each.key
  service    = google_cloud_run_v2_service.services[each.key].name
  role       = "roles/run.invoker"
  member     = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"
  depends_on = [google_cloud_run_v2_service.services]
}

locals {
  # Generate all combinations of regions and invokers
  iam_combinations = flatten([
    for region in var.regions : [
      for invoker in var.invokers : {
        key     = "${region}-${invoker}"
        region  = region
        invoker = invoker
      }
    ]
  ])
}

resource "google_cloud_run_service_iam_member" "user_invoker" {
  # Use iam_combinations directly with for_each
  for_each   = { for combo in local.iam_combinations : combo.key => combo }
  location   = each.value.region
  service    = google_cloud_run_v2_service.services[each.value.region].name
  role       = "roles/run.invoker"
  member     = each.value.invoker
  depends_on = [google_cloud_run_v2_service.services]
}

resource "google_compute_region_network_endpoint_group" "neg" {
  for_each              = toset(var.regions)
  name                  = "${var.app_name}-neg-${each.key}"
  region                = each.key
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.services[each.key].name
  }
}

resource "google_compute_ssl_policy" "tls_policy" {
  name            = "${var.app_name}-tls-policy"
  profile         = "RESTRICTED"
  min_tls_version = "TLS_1_2"
}

module "gclb" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 13.0"

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
          group = google_compute_region_network_endpoint_group.neg[region].id
        }
      ]

      iap_config = {
        enable               = var.iap_enabled
      }
    }
  }

  http_forward = false
  url_map      = "default"
  ssl          = true

  managed_ssl_certificate_domains = [local.load_balancer_domain]
  create_address                  = false
  address                         = google_compute_global_address.load_balancer_ip.address
  ssl_policy                      = google_compute_ssl_policy.tls_policy.name

  depends_on = [
    google_compute_region_network_endpoint_group.neg,
    google_artifact_registry_repository.repos
  ]
}