{ config, unstable, ... }:

{
  # Steam Frame wireless adapter (USB 28de:2432, an RTL8852CU). rtw89_8852cu
  # only gained its Valve-specific config in 7.2; older kernels leave the
  # dongle unbound or stuck in a reset loop. Stable 26.05 tops out at 7.1.
  boot.kernelPackages = unstable.linuxPackages_7_2;

  # The headset's link runs on 6 GHz, which the world regdomain (00) leaves
  # entirely disabled; without a country the dongle never sees the Frame.
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="NL"
  '';

  # Give the dongle a fixed name instead of the port-derived wlp*u*, matched
  # on its USB IDs so it holds in any port and for any Frame adapter.
  systemd.network.links."10-steam-frame" = {
    matchConfig.Property = [ "ID_VENDOR_ID=28de" "ID_MODEL_ID=2432" ];
    linkConfig.Name = "steamframe0";
  };

  # Pairing and streaming run over the dongle's private link to the headset
  # (Steam on TCP/UDP 27036, UDP 27031-27036, plus undocumented VR ports), so
  # trust it outright.
  networking.firewall.trustedInterfaces = [ "steamframe0" ];

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
