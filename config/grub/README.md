Theme taken from https://github.com/catppuccin/grub/tree/main 
1. copy `themes` into `/usr/share/grub/themes/`:
    ```shell
    sudo cp -r themes/* /usr/share/grub/themes/
    ```
2. edit `/etc/default/grub` to your theme:
    ```shell
    GRUB_THEME="/usr/share/grub/themes/catppuccin-mocha-grub-theme/theme.txt"
    ```
3. Update grub:
    ```shell
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    ```
