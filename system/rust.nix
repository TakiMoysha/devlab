{ pkgs ? implrt <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "app_name"
  version = "0.1.0"

  src = ./path/to/rust/project;
  # src = pkgs.fetchFromGitHub {
  #   owner = "takimoysha";
  #   repo = "app_repository";
  #   rev = "v${version}";
  #   sha256 = "sha256-..."; # get from `nix-prefetch-github takimoysha app_repository --rev v0.1.0`
  # };

  nativeBuildInputs = with pkgs; [ rustc carg ];

  cargoVendorDir = null;
  buildPhase = ''
    cargo build --release --frozen --locked
  '';

  checkPhase = ''
    cargo test --release --frozen --locked
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp target/release/app_name $out/bin/app_name

    runHook postInstall
  '';

  # Optional: metadata
  meta = with pkgs.lib; {
    description = "";
    homepage = "";
    license = licnses.mit; # apache-20, gpk3, ...
    maintainers = with maintainers; [ takimoysha ];
    platforms = [ "x86_64-linux" ];
    broken = false;
  }
}
