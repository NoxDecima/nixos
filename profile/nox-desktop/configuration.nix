{ ... }:

{
	imports = [
		./hardware-configuration.nix
		./alc892-jack-retask.nix
#		../../system/update.nix
	];

	networking.hostName = "nox-desktop";

	boot.loader.grub.enable = true;
	boot.loader.grub.device = "/dev/nvme0n1";
	boot.loader.grub.useOSProber = true;
	boot.loader.grub.theme = ../../config/grub/themes/catppuccin-mocha-grub-theme;
}
