provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "talos-controlplane" {
  count       = 1
  name        = "talos-ctr-${count.index}"
  target_node = "edge"
  vmid        = 320 + count.index
  clone       = "talos-template-0"

  # turn off cloud-init and agent
  agent  = 0
  ciwait = false
  onboot = false
  network {
    model  = "virtio"
    bridge = "vmbr0"
    ip     = "192.168.10.110/24"
    gw     = "192.168.10.1"
  }

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
