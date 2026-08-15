{ config, ... }:

{
  # Meta Quest 3 over WiVRn: a Monado-based OpenXR streaming server. WiVRn is
  # the system OpenXR runtime itself, so SteamVR-on-Linux stays out of the
  # picture; OpenVR-only titles go through the bundled OpenComposite.
  services.wivrn = {
    enable = true;

    # TCP+UDP 9757 for the headset. The module also pulls in avahi so the
    # Quest can discover this machine on the LAN.
    openFirewall = true;

    # Run the runtime with the session, so the headset can connect any time.
    autoStart = true;

    # CAP_SYS_NICE, needed for async reprojection. Upstream makes this
    # mutually exclusive with the service's systemd hardening options.
    highPriority = true;

    # The module defaults the compositor to debug, which logs a line per
    # rendered frame for as long as a headset is connected. Connects,
    # disconnects and errors still come through at info.
    monadoEnvironment.XRT_COMPOSITOR_LOG = "info";

    steam = {
      # The same wrapped Steam that programs.steam installs. Left at its
      # default, both modules would push a different steam derivation into
      # environment.systemPackages.
      package = config.programs.steam.package;

      # PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1, so Proton games inside the
      # Steam runtime container can see the runtime. Needs a full logout.
      importOXRRuntimes = true;
    };
  };
}
