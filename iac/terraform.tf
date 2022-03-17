terraform {
  cloud {
    organization = "afabrete"
    workspaces {
      name = "demo"
    }
  }
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

data "digitalocean_ssh_key" "default" {
  name = "default auth"
}

resource "digitalocean_droplet" "cluster-manager" {
  image    = "debian-11-x64"
  name     = "cluster-manager"
  region   = "nyc1"
  size     = "s-2vcpu-4gb"
  ssh_keys = [data.digitalocean_ssh_key.default.id]

  provisioner "remote-exec" {
    inline = [
      "hostnamectl set-hostname cluster-manager",
      "apt -y update",
      "sleep 2",
      "apt -y upgrade",
      "apt -y install curl wget htop unzip dnsutils",
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
}

output "cluster-manager-ip" {
  value = digitalocean_droplet.cluster-manager.ipv4_address
}
