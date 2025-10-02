terraform {
  required_version = ">= 1.13.3"
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = ">= 2.9.14"
    }
  }
}

# instead of pm_user and pm_password using PM_USER and PM_PASS
provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url = "https://192.168.1.100:8006/api2/json"
}

resource "proxmox_vm_qemu" "k3s_control" {
  name = "k3s-ctrl-1"
  target_node = "edge"

  clone = "debian-13.1.0-amd64-netinst.iso"
  full_clone = true

  cores = 2
  memory = 2048
  disk {
    size = "12G"
    type = "scsi"
    storage = "homelab"
  }

  network {
    model = "vmxnet3"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=192.168.10.21/24,gw=192.168.10.1"
}
