variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "regions" {
  description = "List of regions to deploy resources in"
  type        = list(string)
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "root_repository" {
  description = "Root repository for Docker images"
  type        = string
  default     = "https://ghcr.io"
}

variable "image" {
  description = "Docker image name"
  type        = string
  default     = "unitvectory-labs/hellorest"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "v1"
}

variable "iap_enabled" {
  description = "Enable IAP for the Load Balancer. If enabled, the invokers variable is suggested to be set to the users that are granted IAM access"
  type        = bool
  default     = false
}

variable "invokers" {
  description = "Set of invokers to allow access to the Cloud Run services, defaults to allUsers but can be set to a list of users or service accounts"
  type        = set(string)
  default     = ["allUsers"]
}