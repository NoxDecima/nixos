{
  description = "VOXD - Voice-to-text dictation for Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      nixosModule = { config, lib, pkgs, ... }: {
        options.services.voxd = {
          enable = lib.mkEnableOption "VOXD voice-to-text service";
        };

        config = lib.mkIf config.services.voxd.enable {
          boot.kernelModules = [ "uinput" ];

          services.udev.extraRules = ''
            KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
          '';

          environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.voxd ];
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonPackages = pkgs.python3Packages;
      in rec {
        packages.voxd = pythonPackages.buildPythonApplication rec {
          pname = "voxd";
          version = "1.7.0";
          format = "pyproject";

          # Using fetchFromGitHub to pull the remote source
          src = pkgs.fetchFromGitHub {
            owner = "jakovius";
            repo = "voxd";
            rev = "v${version}"; # Or use a specific commit hash/branch
            sha256 = "sha256-A02lNyBO0XkDL7rSG3rgTW/q6R4SqBkyTLr1GZV2NW8="; # Replace with actual hash after first run
          };

          nativeBuildInputs = with pythonPackages; [ hatchling pkgs.makeWrapper ];

          propagatedBuildInputs = with pythonPackages; [
            sounddevice pyqt6 platformdirs pyyaml pyperclip psutil numpy requests pyqtgraph tqdm
          ];

          buildInputs = with pkgs; [
            whisper-cpp llama-cpp
          ];

          runtimeDependencies = with pkgs; [
            ydotool xclip wl-clipboard ffmpeg pipewire alsa-lib libpulseaudio
            whisper-cpp llama-cpp
          ];

          preBuild = ''
            substituteInPlace pyproject.toml \
              --replace-fail 'version = "mr.batman"' 'version = "${version}"'
            if [ -f setup.sh ]; then
              substituteInPlace setup.sh \
                --replace-warn 'sudo apt ' '# sudo apt ' \
                --replace-warn 'sudo dnf ' '# sudo dnf ' \
                --replace-warn 'sudo pacman ' '# sudo pacman '
            fi
            substituteInPlace src/voxd/defaults/default_config.yaml \
              --replace-fail 'whisper_binary: whisper.cpp/build/bin/whisper-cli' 'whisper_binary: whisper-cli' \
              --replace-fail 'llamacpp_server_path: "llama.cpp/build/bin/llama-server"' 'llamacpp_server_path: "llama-server"' \
              --replace-fail 'llamacpp_cli_path: "llama.cpp/build/bin/llama-cli"' 'llamacpp_cli_path: "llama-cli"'

            # Use sed to replace the save method with a version that handles PermissionError and ensures writability
            sed -i '/def save(self):/,/print("\\n\[config\] Configuration saved.")/c\    def save(self):\n        try:\n            CONFIG_DIR.mkdir(parents=True, exist_ok=True)\n            if CONFIG_PATH.exists():\n                os.chmod(CONFIG_PATH, 0o644)\n            with open(CONFIG_PATH, "w") as f:\n                yaml.dump(self.data, f, default_flow_style=False)\n        except PermissionError as e:\n            print(f"\\n[config] Warning: Could not save configuration to {CONFIG_PATH}: {e}")\n        except Exception as e:\n            print(f"\\n[config] Error saving configuration: {e}")' src/voxd/core/config.py
         '';

          doCheck = false;

          postInstall = ''
            wrapProgram "$out/bin/voxd" \
              --prefix PATH : ${pkgs.lib.makeBinPath runtimeDependencies}

            wrapProgram "$out/bin/voxd-model" \
              --prefix PATH : ${pkgs.lib.makeBinPath runtimeDependencies}
          '';

          meta = with pkgs.lib; {
            description = "Offline voice dictation app";
            homepage = "https://github.com/jakovius/voxd";
            license = licenses.mit;
            platforms = platforms.linux;
            mainProgram = "voxd";
          };
        };

        defaultPackage = packages.voxd;
      }) // {
        nixosModules.default = nixosModule;
      };
}

