{ pkgs, ... }:

{
	# Fonts. Note: only `fonts.packages` gets scanned by fontconfig — putting a
	# font in environment.systemPackages installs it but leaves it invisible
	# to apps that resolve fonts via fontconfig (Qt, GTK, etc.).
	fonts.packages = with pkgs; [
	    nerd-fonts.jetbrains-mono
	    nerd-fonts.symbols-only
	    inter
        jetbrains-mono
        noto-fonts-cjk-sans
    ];
}
