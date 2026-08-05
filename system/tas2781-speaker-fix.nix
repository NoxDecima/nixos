{ pkgs, ... }:

{
    # Lenovo Yoga Pro 9 14IRP8: the TAS2781 speaker amp regularly loses its DSP
    # firmware state at boot and on runtime resume (verified still broken on
    # kernel 6.18.41), leaving the speakers ~25 dB quieter with no bass tuning.
    # With "Force Firmware Load" enabled the driver reloads the firmware on
    # every device open, which reliably keeps the speakers in their full state.
    # The flag survives suspend; it only resets on reboot/module reload.
    systemd.services.tas2781-force-firmware-load = {
        description = "Keep TAS2781 speaker amp DSP firmware loaded";
        wantedBy = [ "multi-user.target" ];
        after = [ "sound.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        script = ''
            for _ in $(seq 1 30); do
                if ${pkgs.alsa-utils}/bin/amixer -c sofhdadsp cset name='Speaker Force Firmware Load' on; then
                    exit 0
                fi
                sleep 1
            done
            echo "sofhdadsp card or Force Firmware Load control not available" >&2
            exit 1
        '';
    };
}
