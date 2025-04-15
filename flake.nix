{
	description = "System configuration";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-24.11";
		nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager.url = "github:nix-community/home-manager/release-24.11";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
		zen-browser.url = "github:0xc000022070/zen-browser-flake";
		hyprland.url = "github:hyprwm/Hyprland";
		catppuccin.url = "github:catppuccin/nix";
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
	in {
		nixosConfigurations = {
			nixos = lib.nixosSystem {
				system = settings.system;
				modules = [
				  ./configuration.nix
#				  home-manager.nixosModules.home-manager
#                  {
#                    home-manager.useGlobalPkgs = true;
#                    home-manager.useUserPackages = true;
#                    home-manager.users.${settings.userName} = import ./home.nix {
#                        inherit inputs;
#                        inherit settings;
#                    };
#                  }
				];
				specialArgs = {
			        inherit inputs;
					inherit settings;
				};
			};
		};

		homeConfigurations.${settings.userName} = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            modules = [
                ./home.nix
                inputs.catppuccin.homeManagerModules.catppuccin
            ];
            specialArgs = {
                inherit inputs;
                inherit settings;
            };
        };
	};
}
