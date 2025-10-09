
[doc("just nix-generate system/clean-container.nix")]
nix-generate nix_config:
  nix run github:/nix-community/nixos-generators -- --format proxmox -c {{nix_config}}

[doc("")]
nix-update flake_target:
  nix run github:/nix-community/nixos-rebuild -- --flake .#{{flake_target}} --target-host user@remote-host --use-remote-sudo
