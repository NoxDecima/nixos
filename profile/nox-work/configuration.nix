{ ... }:

{
	imports = [
		./hardware-configuration.nix
		../../system/bluetooth.nix
		../../system/power-profiles.nix
		../../system/tas2781-speaker-fix.nix
#		../../system/update.nix
	];

	networking.hostName = "nox-work";

	boot.loader.efi.canTouchEfiVariables = true;
	boot.loader.grub = {
		enable = true;
		device = "nodev";
		efiSupport = true;
		useOSProber = true;
		configurationLimit = 10;
		theme = ../../config/grub/themes/catppuccin-mocha-grub-theme;
	};
}
