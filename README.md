[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![Concept](https://img.shields.io/badge/Status-Concept-white)](https://guide.unitvectorylabs.com/bestpractices/status/#concept)

# gcp-cloud-run-lb-nipio-tofu

Deploys a global load-balanced Cloud Run service using nip.io for automatic SSL certificates.

## Overview

This module demonstrates the creation of a Global Load Balancer with Cloud Run services using nip.io for DNS with automatic certificate creation through GCP. It is intended for development and demonstration purposes and includes the following features:

- Creation of a global load balancer with Cloud Run services.
- Disabling direct access to Cloud Run.
- Utilizing nip.io to avoid the need for configuring DNS.
- Ensuring TLS is used to access the service.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gclb"></a> [gclb](#module\_gclb) | GoogleCloudPlatform/lb-http/google//modules/serverless_negs | ~> 12.0 |

## Resources

| Name | Type |
|------|------|
| [google_artifact_registry_repository.repos](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_cloud_run_service_iam_member.iap_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_member) | resource |
| [google_cloud_run_service_iam_member.user_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_member) | resource |
| [google_cloud_run_v2_service.services](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_compute_global_address.load_balancer_ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_region_network_endpoint_group.neg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_network_endpoint_group) | resource |
| [google_compute_ssl_policy.tls_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_policy) | resource |
| [google_iap_client.project_client](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iap_client) | resource |
| [google_service_account.cloud_run_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Name of the application | `string` | n/a | yes |
| <a name="input_iap_enabled"></a> [iap\_enabled](#input\_iap\_enabled) | Enable IAP for the Load Balancer. If enabled, the invokers variable is suggested to be set to the users that are granted IAM access | `bool` | `false` | no |
| <a name="input_image"></a> [image](#input\_image) | Docker image name | `string` | `"unitvectory-labs/hellorest"` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Docker image tag | `string` | `"v1"` | no |
| <a name="input_invokers"></a> [invokers](#input\_invokers) | Set of invokers to allow access to the Cloud Run services, defaults to allUsers but can be set to a list of users or service accounts | `set(string)` | <pre>[<br/>  "allUsers"<br/>]</pre> | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project ID | `string` | n/a | yes |
| <a name="input_regions"></a> [regions](#input\_regions) | List of regions to deploy resources in | `list(string)` | n/a | yes |
| <a name="input_root_repository"></a> [root\_repository](#input\_root\_repository) | Root repository for Docker images | `string` | `"https://ghcr.io"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_load_balancer_dns_name"></a> [load\_balancer\_dns\_name](#output\_load\_balancer\_dns\_name) | The DNS name of the load balancer |
| <a name="output_load_balancer_ip_address"></a> [load\_balancer\_ip\_address](#output\_load\_balancer\_ip\_address) | The IP address of the load balancer |
<!-- END_TF_DOCS -->
