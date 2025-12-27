terraform {
  required_version = ">= 1.0.0"

  required_providers {
    proxmox = {
      # source = "telmate/proxmox"
      # version = "3.0.2-rc06"

      source = "bpg/proxmox"
      version = "0.90.0"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "http://edge.arpa/api2/json"
  pm_api_token_id     = "terraform-prov@pve!pcl-89-infra"
  pm_api_token_secret = "9b868951-4ede-411b-885b-43f8786a76ec"
  pm_tls_insecure     = true
}
