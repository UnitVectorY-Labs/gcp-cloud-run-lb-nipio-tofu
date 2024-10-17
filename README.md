# gcp-cloudrun-lb-nipio-tofu

Deploys a global load-balanced Cloud Run service using nip.io for automatic SSL certificates.

## Overview

This module demonstrates the creation of a Global Load Balancer with Cloud Run services using nip.io for DNS with automatic certificate creation through GCP. It is intended for development and demonstration purposes and includes the following features:

- Creation of a global load balancer with Cloud Run services.
- Disabling direct access to Cloud Run.
- Utilizing nip.io to avoid the need for configuring DNS.
- Ensuring TLS is used to access the service.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
