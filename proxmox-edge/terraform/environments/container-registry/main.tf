provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

# ============================================
variable "proxmox_vm_name" {
  type = string
  description = "Registry for container images"
  default = "container-registry"
}

variable "proxmox_vm_node" {
  type = string
  description = "Proxmox node name"
  default = "edge"
}

variable "registry_data_dir" {
  type = string
  description = "Registry data directory"
  default = "/var/lib/registry"
}

# ============================================
resource "proxmox_lxc" "registry" {
  node_name = "container-registry"
  vm_id = 810
  target_node = "edge"
  memory = 1024
  cores = 1
  disk_size = "12G"  

  template = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"

  mount {
    host_path = var.registry_data_dir
    container_path = "/var/lib/registry"
    options = ["bind", "rw"]
  }

  unprivileged = true
}

resource "null_resource" "install_registry" {
  depends_on = [ proxmox_lxc.registry ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y docker.io"
    ]
    connection {
      type = "ssh"
      user = "root"
      host = proxmox_lxc.registry.default_ip_address
    }
  }
}

# ============================================
# output "registry_url" {
#   value = "http://${proxmox_lxc.registry.ip_address}:${var.registry_port}"
#   description = "Public url"
# }

# output "registry_ip" {
#   value = proxmox_lxc.registry.ip_address
#   description = "registry ip-address (!TODO :public or private net?)"
# }

# output "registry_port" {
#   value = var.registry_port
#   description = "Registry port"
# }

output "registry_address" {
  value = "http"//${proxmox_lxc.registry.default_ip_address}:{var.registry_port}""
  description = "Registry address"
}

