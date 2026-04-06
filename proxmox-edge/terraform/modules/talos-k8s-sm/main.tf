terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.2-rc06"
    }
  }
}

// ============================================
provider "proxmox" {
  pm_api_url          = "http://edge.arpa/api2/json"
  pm_api_token_id     = "terraform-prov@pve!pcl-89-infra"
  pm_api_token_secret = "9b868951-4ede-411b-885b-43f8786a76ec"
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "talos-controlplane" {
  count       = 1
  name        = "talos-ctr-${count.index}"
  clone       = "talos-template-0"
  target_node = "edge"
  vmid        = 320 + count.index

  network {
    model  = "virtio"
    bridge = "vmbr0"
    ip     = "192.168.10.110/24"
    gw     = "192.168.10.1"
  }

  # turn off cloud-init and agent
  agent  = 0
  ciwait = false
  onboot = false
}

resource "proxmox_vm_qemu" "talos-worker" {
  count       = 2
  name        = "talos-wrk-${count.index + 1}"
  target_node = "edge"
  vmid        = 330 + count.index
  clone       = "talos-template-0"

  agent  = 0
  ciwait = false
  onboot = false

  network {
    model  = "virtio"
    bridge = "vmbr0"
    ip     = "dhcp"
    gw     = "192.168.10.1"
  }
}

output "controlplane_ips" {
  value = [for vm in proxmox_vm_qemu.talos-controlplane : vm.ip_address]
}
output "worker_ips" {
  value = [for vm in proxmox_vm_qemu.talos-worker : vm.ip_address]
}
