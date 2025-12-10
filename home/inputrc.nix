{ ... }:
{
    programs.readline = {
        enable = true;
        extraConfig = ''
            "\e[A": history-search-backward
            "\e[B": history-search-forward
        '';
    };
}