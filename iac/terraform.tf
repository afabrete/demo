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

data "digitalocean_ssh_key" "default" {
  name       = "default auth"
}

resource "digitalocean_droplet" "doguinhos" {
  image    = "debian-10-x64"
  name     = "cluster-manager"
  region   = "nyc1"
  size     = "s-2vcpu-4gb"
  ssh_keys = [data.digitalocean_ssh_key.default.id]

  provisioner "remote-exec" {
    inline = [
      "hostnamectl set-hostname doguinhos",
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

#resource "linode_instance" "doguinhos" {
#  image           = "linode/debian10"
#  label           = "doguinhos"
#  region          = "us-east"
#  type            = "g6-standard-1"
#  authorized_keys = [ var.linode_public_key ]
#  root_pass       = random_string.password.result

}

resource "cloudflare_record" "doguinhos" {
  zone_id = var.cloudflare_zone_id
  name = "doguinhos"
  value = digitalocean_droplet.doguinhos.ipv4_address
  type = "A"
  depends_on = [ digitalocean_droplet.doguinhos ]
}

#resource "linode_instance" "doguinhos" {
#  image           = "linode/debian10"
#  label           = "cluster-worker"
#  region          = "us-east"
#  type            = "g6-standard-1"
#  authorized_keys = [ var.linode_public_key ]
#  root_pass       = random_string.password.result
#  depends_on = [ cloudflare_record.doguinhos ]

#  provisioner "remote-exec" {
#    inline = [
#      "hostnamectl set-hostname cluster-worker",
#      "apt -y update",
#      "apt -y install curl wget htop",
#      "export K3S_TOKEN=${var.linode_token}",
#      "export K3S_URL=https://doguinhos.${var.cloudflare_zone_name}:6443",
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

resource "local_file" "doguinhos-ip" {
  content  = digitalocean_droplet.doguinhos.ipv4_address
  filename = "doguinhos-ip"
}
