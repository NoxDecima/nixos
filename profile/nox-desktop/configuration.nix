# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, config, pkgs, settings, ... }:

{
	imports = [
		./hardware-configuration.nix
		../../programs.nix
		../../system/hyprland.nix
		../../system/nvidia.nix
	    ../../system/audio.nix
	    ../../system/nextcloud.nix
        ../../system/font.nix
	    ../../system/virtualization.nix
        ../../system/python-dev.nix
        ../../system/rust-dev.nix
        ../../system/usb-drive.nix
        ../../system/voxd.nix
        ../../system/tailscale.nix
        ../../system/printing.nix
#	    ../../system/update.nix
	];

	# Bootloader.
	boot.loader.grub.enable = true;
	boot.loader.grub.device = "/dev/nvme0n1";
	boot.loader.grub.useOSProber = true;
	boot.loader.grub.theme = ../../config/grub/themes/catppuccin-mocha-grub-theme;

	nixpkgs.config.allowUnfree = true;

	networking.hostName = "nox-desktop"; # Define your hostname.

	# Enable networking
	networking.networkmanager.enable = true;

	# Set your time zone.
	time.timeZone = settings.timezone;

	# Select internationalisation properties.
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



	# Enable CUPS to print documents.
	services.printing.enable = true;

	# Enable sound with pipewire.
	services.pulseaudio.enable = false;
	security.rtkit.enable = true;
	services.pipewire = {
	  enable = true;
	  alsa.enable = true;
	  alsa.support32Bit = true;
	  pulse.enable = true;
	  # If you want to use JACK applications, uncomment this
	  jack.enable = true;

	  # use the example session manager (no others are packaged yet so this is enabled by default,
	  # no need to redefine it in your config for now)
	  #media-session.enable = true;
	};

	# Enable touchpad support (enabled default in most desktopManager).
	# services.xserver.libinput.enable = true;

	# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.${settings.userName} = {
	  isNormalUser = true;
	  description = settings.userName;
	  extraGroups = [ "networkmanager" "wheel" ];
	  packages = with pkgs; [
	  #  thunderbird
	  ];
	};

	# Install firefox.
	programs.firefox.enable = true;

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [
	vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
	#  wget
	];

	# Some programs need SUID wrappers, can be configured further or are
	# started in user sessions.
	# programs.mtr.enable = true;
	# programs.gnupg.agent = {
	#   enable = true;
	#   enableSSHSupport = true;
	# };

	# List services that you want to enable:

	# Enable the OpenSSH daemon.
	# services.openssh.enable = true;

	# Open ports in the firewall.
	# networking.firewall.allowedTCPPorts = [ ... ];
	# networking.firewall.allowedUDPPorts = [ ... ];
	# Or disable the firewall altogether.
	# networking.firewall.enable = false;

	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "24.11"; # Did you read the comment?

	nix.settings.experimental-features = [ "nix-command" "flakes" ];

}
