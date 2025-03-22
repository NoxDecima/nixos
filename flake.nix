{
	description = "System configuration";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-24.11";
		nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
		hyprland.url = "github:hyprwm/Hyprland";
	};

	outputs = inputs@{ self, nixpkgs, home-manager, ...}:
	let 
		settings = {
			userName = "nox"; # TODO: use this
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
				  home-manager.nixosModules.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.${settings.userName} = import ./home.nix {
                        inherit inputs;
                        inherit settings;
                    };
                  }
				];
				specialArgs = {
			        inherit inputs;
					inherit settings;
				};
			};
		};
	};
}
