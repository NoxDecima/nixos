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
    uv
    python314
    unstable.jetbrains.pycharm
#    (writeShellScriptBin "patched-python" ''
#  export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
#  exec ${python3}/bin/python "$@"
#'')
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      libz
      pipewire.jack # Include this lib as it is required for PipeWire and we overwrite its binding.
    ];
  };

  environment.localBinInPath = true;
}

