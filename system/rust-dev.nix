{ inputs, settings, config, pkgs, lib, ... }:
let
  unstable = import inputs.nixpkgs-unstable {
    system = settings.system;
    config = {
      allowUnfree = true;
    };
  };
in
{
  environment.systemPackages = with pkgs; [
#    cargo
#    rustc
    unstable.jetbrains.rust-rover
    rustup
    openssl
    openssl.dev
    pkg-config
  ];
}
