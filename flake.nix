{
	description = "System configuration";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-26.05";
		nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
		zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
		claude-code.url = "github:sadjow/claude-code-nix";
		voxd.url = "path:./flakes/voxd";
	};

	outputs = inputs@{ self, nixpkgs, home-manager, ...}:
	let 
		settings = {
			userName = "nox";
			system = "x86_64-linux";
			timezone = "Europe/Amsterdam";
			locale = "en_US.UTF-8";
		};
		lib = nixpkgs.lib;
		pkgs = nixpkgs.legacyPackages.${settings.system};

		# Single nixpkgs-unstable instantiation, shared by every module that
		# needs newer packages (each `import nixpkgs {}` re-evaluates nixpkgs).
		unstable = import inputs.nixpkgs-unstable {
			system = settings.system;
			config.allowUnfree = true;
		};

        # Helper function to create a configuration for a specific profile
        mkSystem = profile: lib.nixosSystem {
            system = settings.system;
            modules = [
                # Common configuration
                ./profile/common/configuration.nix
                # Profile-specific configuration
                ./profile/${profile}/configuration.nix

                home-manager.nixosModules.home-manager
                {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.${settings.userName} = {
                        imports = [
                            # Common home-manager config
                            ./profile/common/home.nix
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
                inherit unstable;
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
