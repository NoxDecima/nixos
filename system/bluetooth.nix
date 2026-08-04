{ ... }:

{
    hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
            General = {
                Experimental = true; # Show battery charge of Bluetooth devices
                # NOTE: LE Audio (BAP/LC3) was verified working 2026-08-04 via
                # KernelExperimental = true, but reverted: the XM6 softens ANC
                # whenever audio streams (bidirectional CIS => conversation-mode
                # DSP). Retry after Sony firmware updates — full recipe in the
                # Claude project memory (nox-work-bt-hfp-autoswitch).
            };
        };
    };

    services.blueman.enable = true;
}