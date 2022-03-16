variable "digitalocean_token" {}
variable "digitalocean_public_key" {}
variable "digitalocean_private_key" {}

variable "cloudflare_email" {}
variable "cloudflare_api_key" {}
variable "cloudflare_zone_id" {}
variable "cloudflare_zone_name" {}

variable "datadog_agent_key" {}

#resource "random_string" "password" {
#  length = 32
#  special = true
#  upper = true
#  lower = true
#  number = true
#}
