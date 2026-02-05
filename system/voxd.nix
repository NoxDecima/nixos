# system/voxd.nix
{ inputs, settings, ... }:

{
  imports = [
    # Import the NixOS module directly from the flake inputs
    inputs.voxd.nixosModules.default
  ];

  # Enable the service defined in that module
  services.voxd.enable = true;

  # Add your user to the 'input' group for ydotool permissions
  users.users.${settings.userName}.extraGroups = [ "input" ];
}