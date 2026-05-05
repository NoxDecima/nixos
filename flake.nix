{
	description = "System configuration";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-25.05";
		nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
		zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
		catppuccin.url = "github:catppuccin/nix";
		claude-code.url = "github:sadjow/claude-code-nix";
		voxd.url = "path:./flakes/voxd";
	};

	outputs = inputs@{ self, nixpkgs, home-manager, ...}:
	let 
		settings = {
			userName = "nox";
			system = "x86_64-linux";
			profile = "default"; # TODO: use this
			timezone = "Europe/Amsterdam"; # TODO: use this
			locale = "en_US.UTF-8"; # TODO: use this
			bootMode = ""; # TODO: use this
			gpuType = "nvidia"; # TODO: use this
		};
		lib = nixpkgs.lib;
		pkgs = nixpkgs.legacyPackages.${settings.system};

        # Helper function to create a configuration for a specific profile
        mkSystem = profile: lib.nixosSystem {
            system = settings.system;
            modules = [
                # Common configuration
                # ./profiles/common/configuration.nix
                # Profile-specific configuration
                ./profile/${profile}/configuration.nix

                home-manager.nixosModules.home-manager
                {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.${settings.userName} = {
                        imports = [
                            # Common home-manager config
                            # ./profiles/common/home.nix
                            # Profile-specific home-manager config
                            ./profile/${profile}/home.nix
                        ];
                    };
                    home-manager.extraSpecialArgs = {
                        inherit inputs;
                        inherit settings;
                        inherit profile;
                    };
                }
            ];
            specialArgs = {
                inherit inputs;
                inherit settings;
                inherit profile;
            };
        };
	in {
        nixosConfigurations = {
            # Your default configuration becomes "desktop"
            desktop = mkSystem "nox-desktop";
            # Add your work profile
            work = mkSystem "nox-work";
        };
	};
}
