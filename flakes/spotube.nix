{
  lib,
  stdenv,
  fetchurl,

  autoPatchelfHook,
  dpkg,
  makeBinaryWrapper,
  makeWrapper,
  undmg,
  wrapGAppsHook3,

  alsa-lib,
  cairo,
  dbus,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  glib-networking,
  gtk3,
  libGL,
  libsoup_3,
  libvlc,
  libx11,
  libxext,
  libxi,
  libxrender,
  libxtst,
  pango,
  webkitgtk_4_1,
  xdg-user-dirs,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "spotube";
  version = "6.0.0";

  src = finalAttrs.passthru.sources.${stdenv.hostPlatform.system};

  sourceRoot = lib.optionalString stdenv.hostPlatform.isDarwin ".";

  nativeBuildInputs =
    lib.optionals stdenv.hostPlatform.isLinux [
      autoPatchelfHook
      dpkg
      makeWrapper
      wrapGAppsHook3
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      undmg
      makeBinaryWrapper
    ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
    fontconfig
    freetype
    glib-networking
    gtk3
    libGL
    libx11
    libxext
    libxi
    libxrender
    libxtst
    (lib.getLib stdenv.cc.cc)
    zlib
  ];

  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    mkdir -p $out
    cp -r usr/* $out
    cp -r opt/spotube $out/share/spotube
    substituteInPlace $out/share/applications/spotube.desktop \
      --replace-fail "Exec=/opt/spotube/spotube" "Exec=spotube"
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    mkdir -p $out/Applications
    cp -r Spotube.app $out/Applications
    makeBinaryWrapper $out/Applications/Spotube.app/Contents/MacOS/Spotube $out/bin/spotube
  ''
  + ''
    runHook postInstall
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    makeWrapper $out/share/spotube/spotube $out/bin/spotube \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : $out/share/spotube:$out/share/spotube/lib:${
        lib.makeLibraryPath [
          # also covers libs the app extracts to ~/.cache/nucleus at runtime
          cairo
          dbus
          gdk-pixbuf
          glib
          gtk3
          libGL
          libsoup_3
          libvlc
          pango
          stdenv.cc.cc
          webkitgtk_4_1
        ]
      } \
      --prefix PATH : ${lib.makeBinPath [ xdg-user-dirs ]} \
      --set-default WEBKIT_DISABLE_DMABUF_RENDERER 1 # login webview: Wayland protocol error 71 on NVIDIA
  '';

  passthru.sources =
    let
      fetchArtifact =
        { suffix, hash }:
        fetchurl {
          name = "Spotube-${finalAttrs.version}-${suffix}";
          url = "https://github.com/team-spotube/spotube/releases/download/v${finalAttrs.version}/Spotube-${suffix}";
          inherit hash;
        };
    in
    {
      "aarch64-linux" = fetchArtifact {
        suffix = "linux-aarch64.deb";
        hash = "sha256:0m1zdj1s6ay2p45hv764jhvkyn2zj8cx89gp69x7z69hqx144n83";
      };
      "x86_64-linux" = fetchArtifact {
        suffix = "linux-x86_64.deb";
        hash = "sha256:0kxk2ds28ywan21lmjv7mfrx9lifdwlc0i3lnn98javm3k5pnlq9";
      };
      "aarch64-darwin" = fetchArtifact {
        suffix = "macos-apple-silicon.dmg";
        hash = "sha256:1ls5s89cdnyyykidfb4520vd0f9y5w11q7dgcgdayq0c19mdwq74";
      };
    };

  meta = {
    description = "Open source, cross-platform Spotify client compatible across multiple platforms";
    longDescription = ''
      Spotube is an open source, cross-platform Spotify client compatible across
      multiple platforms utilizing Spotify's data API and YouTube (or Piped.video or JioSaavn)
      as an audio source, eliminating the need for Spotify Premium
    '';
    downloadPage = "https://github.com/team-spotube/spotube/releases";
    homepage = "https://spotube.krtirtho.dev/";
    license = lib.licenses.bsdOriginal;
    mainProgram = "spotube";
    maintainers = with lib.maintainers; [ tomasajt ];
    platforms = lib.attrNames finalAttrs.passthru.sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})