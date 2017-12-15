{ stdenv
, fetchurl
, lib
, makeWrapper

, alsa-lib
, atk
, cairo
, cups
, dbus
, expat
, fontconfig
, freetype
, gconf
, gdk-pixbuf
, gdk-pixbuf_unwrapped
, git
, glib
, gnome-themes-standard
, gtk_2
, gvfs
, kbproto
, libcap
, libgnome-keyring
, libgpg-error
, libnotify
, libx11
, libxcb
, libxcomposite
, libxcursor
, libxdamage
, libxext
, libxfixes
, libxi
, libxrandr
, libxrender
, libxscrnsaver
, nspr
, nss
, pango
, python
, shared-mime-info
, systemd_lib
, xorg
, xproto
, zlib

, channel
}:

let
  inherit (lib)
    makeSearchPath;

  sources = {
    "stable" = {
      suffix = "";
      version = "1.23.1";
      sha256 = "8e6cb0b8ae0bb71040e1eae8d6cf20268cea43c6f63ba8906413e6ce10799c91";
    };
    "beta" = {
      suffix = "-beta";
      version = "1.24.0-beta1";
      sha256 = "e5adc63c36e292eecbad4e9120514b784ea87447a266a47f4e0f232866ed9e11";
    };
  };
  source = sources."${channel}";
in
stdenv.mkDerivation rec {
  name = "atom${source.suffix}-${source.version}";

  src = fetchurl {
    url = "https://github.com/atom/atom/releases/download/v${source.version}/"
      + "atom-amd64.deb";
    name = "${name}.deb";
    inherit (source) sha256;
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gconf
    gdk-pixbuf
    gdk-pixbuf_unwrapped
    glib
    gnome-themes-standard
    gtk_2
    gvfs
    kbproto
    libcap
    libgnome-keyring
    libgpg-error
    libnotify
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    xorg.libxkbfile
    libxrandr
    libxrender
    libxscrnsaver
    xorg.libXtst
    nspr
    nss
    pango
    stdenv.cc.cc
    systemd_lib
    xproto
    zlib
  ];

  libPath_ = makeSearchPath "lib" buildInputs;
  libPath64 = makeSearchPath "lib64" buildInputs;
  libPath = "${libPath_}:${libPath64}";

  unpackPhase = ''
    mkdir -pv "$out"
    ar p $src data.tar.xz | tar -xJ
  '';

  installPhase = ''
    rm -rv usr/share/lintian
    mv -v usr/* $out/
  '';

  preFixup = ''
    sed -i $out/share/applications/atom${source.suffix}.desktop \
      -e "s,/usr/share/atom${source.suffix}/atom,$out/bin/atom${source.suffix},"

    # Replace vendored git binary
    atom_git=$out/share/atom${source.suffix}/resources/app.asar.unpacked/node_modules/dugite/git
    rm -fv $atom_git/bin/git
    ln -sv ${git}/bin/git \
      $atom_git/bin/git
    for gitcommand in ${git}/libexec/git-core/*; do
      if [ -e "$atom_git/libexec/git-core/$(basename "$gitcommand")" ] && \
         [ ! -d "$atom_git/libexec/git-core/$(basename "$gitcommand")" ]; then
        rm -v "$atom_git/libexec/git-core/$(basename "$gitcommand")"
        ln -sv "$gitcommand" \
          "$atom_git/libexec/git-core/$(basename "$gitcommand")"
      fi
    done

    # Fix runtime beta detection
    sed -i $out/bin/atom${source.suffix} \
      -e 's,$(basename $0),atom${source.suffix},'

    wrapProgram $out/bin/atom${source.suffix} \
      --set 'GTK2_RC_FILES' \
          '${gnome-themes-standard}/share/themes/Adwaita/gtk-2.0/gtkrc' \
      --prefix 'CPATH' : "${makeSearchPath "include" buildInputs}" \
      --prefix 'PATH' : "${gvfs}/bin:${python}/bin" \
      --prefix 'LIBRARY_PATH' : "${libPath}" \
      --prefix 'LD_LIBRARY_PATH' : "${libPath}" \
      --prefix 'XDG_DATA_DIRS' : "${shared-mime-info}/share" \
      --prefix 'XDG_DATA_DIRS' : "$out/share"

    wrapProgram $out/bin/apm${source.suffix} \
      --prefix 'CPATH' : "${makeSearchPath "include" buildInputs}" \
      --prefix 'PATH' : "${gvfs}/bin:${python}/bin" \
      --prefix 'LIBRARY_PATH' : "${libPath}" \
      --prefix 'LD_LIBRARY_PATH' : "${libPath}" \
      --prefix 'XDG_DATA_DIRS' : "${shared-mime-info}/share" \
      --prefix 'XDG_DATA_DIRS' : "$out/share" \
      --run "$DEFAULT_GTK2_RC_FILES"

    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}:$out/share/atom${source.suffix}" \
      $out/share/atom${source.suffix}/atom
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}" \
      $out/share/atom${source.suffix}/resources/app/apm/bin/node
    #find $out/share/atom${source.suffix} \
    #  -name "*.node" \
    #  -exec patchelf --set-rpath "${libPath}:$out/share/atom${source.suffix}" {} \;
  '';

  buildDirCheck = false;  # slow
  dontStrip = true;

  meta = with lib; {
    description = "A hackable text editor for the 21st Century";
    homepage = https://atom.io/;
    license = licenses.mit;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
