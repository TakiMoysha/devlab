set dotenv-load

export PM_API_URL:="http://edge.arpa/api2/json"
export PM_API_TOKEN_ID:="terraform-prov@pve!pcl-89-infra"
export PM_API_TOKEN_SECRET:="9b868951-4ede-411b-885b-43f8786a76ec"


[doc("just nix-generate system/clean-container.nix")]
nix-generate nix_config:
  nix run github:/nix-community/nixos-generators -- --format proxmox -c {{nix_config}}

[doc("")]
nix-update flake_target:
  nix run github:/nix-community/nixos-rebuild -- --flake .#{{flake_target}} --target-host user@remote-host --use-remote-sudo

[working-directory: "proxmox-edge"]
init-proxmox-terraform:
  tofu init
  tofu apply


mod test "containers/justfile"
