terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
#   linode = {
#     source = "linode/linode"
#     version = "1.16.0"
#    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

#provider "linode" {
#  token = var.linode_token
#}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

resource "digitalocean_ssh_key" "default" {
  name       = "default auth"
  public_key = var.digitalocean_public_key
}

resource "digitalocean_droplet" "cluster-manager" {
  image    = "debian-10-x64"
  name     = "cluster-manager"
  region   = "nyc1"
  size     = "s-2vcpu-4gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]

  provisioner "remote-exec" {
    inline = [
      "hostnamectl set-hostname cluster-manager",
      "whoami",
      "apt -y update",
      "apt -y upgrade",
      "apt -y install curl wget htop",
      "export K3S_TOKEN=${var.digitalocean_token}",
      "curl -sfL https://get.k3s.io | sh -",
      "kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb.yaml",
      "export DD_AGENT_MAJOR_VERSION=7",
      "export DD_API_KEY=${var.datadog_agent_key}",
      "export DD_SITE=datadoghq.com",
      "curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh -o install_script.sh",
      "chmod +x ./install_script.sh",
      "./install_script.sh"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      agent       = false
      private_key = var.digitalocean_private_key
      host        = self.ipv4_address
    }
  }

#resource "linode_instance" "cluster-manager" {
#  image           = "linode/debian10"
#  label           = "cluster-manager"
#  region          = "us-east"
#  type            = "g6-standard-1"
#  authorized_keys = [ var.linode_public_key ]
#  root_pass       = random_string.password.result

}

resource "cloudflare_record" "cluster-manager" {
  zone_id = var.cloudflare_zone_id
  name = "cluster-manager"
  value = digitalocean_droplet.cluster-manager.ipv4_address
  type = "A"
  depends_on = [ digitalocean_droplet.cluster-manager ]
}

#resource "linode_instance" "cluster-worker" {
#  image           = "linode/debian10"
#  label           = "cluster-worker"
#  region          = "us-east"
#  type            = "g6-standard-1"
#  authorized_keys = [ var.linode_public_key ]
#  root_pass       = random_string.password.result
#  depends_on = [ cloudflare_record.cluster-manager ]

#  provisioner "remote-exec" {
#    inline = [
#      "hostnamectl set-hostname cluster-worker",
#      "apt -y update",
#      "apt -y install curl wget htop",
#      "export K3S_TOKEN=${var.linode_token}",
#      "export K3S_URL=https://cluster-manager.${var.cloudflare_zone_name}:6443",
#      "curl -sfL https://get.k3s.io | sh -",
#      "export DD_AGENT_MAJOR_VERSION=7",
#      "export DD_API_KEY=${var.datadog_agent_key}",
#      "export DD_SITE=datadoghq.com",
#      "curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh -o ./install_script.sh",
#      "chmod +x ./install_script.sh",
#      "./install_script.sh"
#    ]

#    connection {
#      type        = "ssh"
#      user        = "root"
#      agent       = false
#      private_key = var.linode_private_key
#      host        = self.ip_address
#    }
#  }
#}

#resource "cloudflare_record" "cluster-worker" {
#  zone_id = var.cloudflare_zone_id
#  name = "cluster-worker"
#  value = linode_instance.cluster-worker.ip_address
#  type = "A"
#  depends_on = [ linode_instance.cluster-worker ]
#}

resource "local_file" "cluster-manager-ip" {
  content  = digitalocean_droplet.cluster-manager.ipv4_address
  filename = "cluster-manager-ip"
}
