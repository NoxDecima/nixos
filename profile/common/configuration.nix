{ settings, ... }:

{
	imports = [
		../../programs.nix
		../../system/hyprland.nix
		../../system/nvidia.nix
		../../system/nextcloud.nix
		../../system/font.nix
		../../system/virtualization.nix
		../../system/python-dev.nix
		../../system/rust-dev.nix
		../../system/usb-drive.nix
		../../system/voxd.nix
		../../system/tailscale.nix
		../../system/printing.nix
		../../system/input-method.nix
		../../system/clipboard.nix
	];

	nixpkgs.config.allowUnfree = true;

	networking.networkmanager.enable = true;

	time.timeZone = settings.timezone;

	i18n.defaultLocale = settings.locale;
	i18n.extraLocaleSettings = {
		LC_ADDRESS = settings.locale;
		LC_IDENTIFICATION = settings.locale;
		LC_MEASUREMENT = settings.locale;
		LC_MONETARY = settings.locale;
		LC_NAME = settings.locale;
		LC_NUMERIC = settings.locale;
		LC_PAPER = settings.locale;
		LC_TELEPHONE = settings.locale;
		LC_TIME = settings.locale;
	};

	# Sound with pipewire.
	services.pulseaudio.enable = false;
	security.rtkit.enable = true;
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
		jack.enable = true;
	};

	users.users.${settings.userName} = {
		isNormalUser = true;
		description = settings.userName;
		extraGroups = [ "networkmanager" "wheel" ];
	};

	programs.firefox.enable = true;

	# Release of the first install of these systems; do not bump on upgrades.
	system.stateVersion = "24.11";

	nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
