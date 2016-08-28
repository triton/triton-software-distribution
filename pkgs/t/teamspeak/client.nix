{ stdenv
, fetchurl
, less
, makeDesktopItem
, makeWrapper
, unzip
, which

, alsa-lib
, fontconfig
, freetype
, glib
, libpng
, libredirect
, llvm
, pulseaudio_lib
, qt5
, quazip
, xorg
, zlib
}:

let
  inherit (stdenv.lib)
    makeSearchPath;

  version = "3.0.19.4";
in
stdenv.mkDerivation rec {
  name = "teamspeak-client-${version}";

  src = fetchurl {
    urls = [
      "http://dl.4players.de/ts/releases/${version}/TeamSpeak3-Client-linux_amd64-${version}.run"
      "http://teamspeak.gameserver.gamed.de/ts3/releases/${version}/TeamSpeak3-Client-linux_amd64-${version}.run"
    ];
    sha256 = "f74617d2a2f5cb78e0ead345e6ee66c93e4a251355779018fd060828e212294a";
  };

  # grab the plugin sdk for the desktop icon
  pluginsdk = fetchurl {
    url = "http://dl.4players.de/ts/client/pluginsdk/pluginsdk_3.0.19.1.zip";
    sha256 = "ca9301b2bbd13b3a3e5f25d21f73200094af3e4a97da28103cb9ab82bfd13ae4";
  };

  unpackPhase = ''
    echo -e 'q\ny' | sh -xe $src
    cd TeamSpeak*
  '';

  nativeBuildInputs = [
    makeWrapper
    less
    which
    unzip
  ];

  buildInputs = [
    alsa-lib
    fontconfig
    freetype
    glib
    libpng
    libredirect
    llvm
    pulseaudio_lib
    qt5
    quazip
    xorg.libICE
    xorg.libSM
    xorg.libX11
    xorg.libxcb
    xorg.libXcursor
    xorg.libXext
    xorg.libXfixes
    xorg.libXinerama
    xorg.libXrandr
    xorg.libXrender
    zlib
  ];

  buildPhase = ''
    mv -v ts3client_linux_amd64 ts3client
    echo "patching ts3client..."
    patchelf \
      --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath ${makeSearchPath "lib" buildInputs}:$(cat $NIX_CC/nix-support/orig-cc)/lib64 \
      --force-rpath \
      ts3client
  '';

  installPhase = ''
    # Delete unecessary libraries - these are provided by Triton.
    rm -v *.so*
    rm -v qt.conf

    # Install files.
    mkdir -p $out/lib/teamspeak
    mv -v * $out/lib/teamspeak/

    # Make a desktop item
    mkdir -pv $out/share/applications/ $out/share/icons/
    unzip ${pluginsdk}
    cp -v pluginsdk/docs/client_html/images/logo.png $out/share/icons/teamspeak.png
    cp -v ${desktopItem}/share/applications/* $out/share/applications/

    # Make a symlink to the binary from bin.
    mkdir -pv $out/bin/
    ln -sv $out/lib/teamspeak/ts3client $out/bin/ts3client

    wrapProgram $out/bin/ts3client \
      --set QT_PLUGIN_PATH "$out/lib/teamspeak/platforms" \
      --set NIX_REDIRECTS /usr/share/X11/xkb=${xorg.xkeyboardconfig}/share/X11/xkb
  '';

  desktopItem = makeDesktopItem {
    name = "teamspeak";
    exec = "ts3client";
    icon = "teamspeak";
    comment = "The TeamSpeak voice communication tool";
    desktopName = "TeamSpeak";
    genericName = "TeamSpeak";
    categories = "Network";
  };

  dontStrip = true;
  dontPatchELF = true;

  meta = with stdenv.lib; {
    description = "The TeamSpeak voice communication tool";
    homepage = http://teamspeak.com/;
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
