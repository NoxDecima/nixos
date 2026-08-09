{ pkgs, unstable, ... }:

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
