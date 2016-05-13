{ stdenv
, fetchurl
, makeWrapper

, bzip2
, cairo
, gksu
, glib
, gtk2
, libredirect
, openssl
, pango
, xorg

, pkexecPath ? "/var/setuid-wrappers/pkexec"
}:

let
  inherit (stdenv)
    system;
  inherit (stdenv.lib)
    makeLibraryPath
    optionalString;
in

let
  version = "3114";
in

let
  sublime-text-bin = stdenv.mkDerivation rec {
    name = "sublime-text-bin-${version}";

    src = fetchurl {
      url = "https://download.sublimetext.com/"
        + "sublime_text_3_build_${version}_x64.tar.bz2";
      sha256 = "c6409bfc0841a02dfa3ba194015c7c87ea41ade9d61407d421ca947fe713b15a";
    };

    nativeBuildInputs = [
      makeWrapper
    ];

    libPath = makeLibraryPath [
      cairo
      glib
      gtk2
      pango
      xorg.libX11
    ];

    redirects = [
      "/usr/bin/gksudo=${gksu}/bin/gksudo"
      "/usr/bin/pkexec=${pkexecPath}"
    ];

    postPatch =
      /* Fix paths */ ''
        sed -i sublime_text.desktop \
          -e 's,/opt/sublime_text/,,' \
          -e 's,sublime-text,sublime_text,'
      '' +
      /* Rename icon file */ ''
        mv -v Icon/256x256/sublime-text.png Icon/256x256/sublime_text.png
      '';

    buildPhase = ''
      for i in 'sublime_text' 'plugin_host' 'crash_reporter' ; do
        patchelf \
          --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          --set-rpath ${libPath}:${stdenv.cc.cc}/lib64 \
          $i
      done
    '' +
    /* Rewrite gksudo/pkexec argument. Note that we can't delete
       bytes in binary. */ ''
      sed -i sublime_text \
        -e 's,/bin/cp\x00,cp\x00\x00\x00\x00\x00\x00,g'
    '';

    installPhase = ''
      mkdir -pv $out/
      cp -prvd * $out/
    '' + ''
      wrapProgram $out/sublime_text \
        --set LD_PRELOAD '${libredirect}/lib/libredirect.so' \
        --set NIX_REDIRECTS ${builtins.concatStringsSep ":" redirects}
    '' +
    /* Without this, plugin_host crashes, even though it has the rpath */ ''
      wrapProgram $out/plugin_host \
        --prefix LD_PRELOAD : '${stdenv.cc.cc}/li64/libgcc_s.so.1' \
        --prefix LD_PRELOAD : '${openssl}/lib/libssl.so' \
        --prefix LD_PRELOAD : '${bzip2}/lib/libbz2.so'
    '';

    dontStrip = true;
    dontPatchELF = true;

    meta = with stdenv.lib; {
      license = licenses.unfreeRedistributable;
      platforms = with platforms;
        x86_64-linux;
    };
  };
in

stdenv.mkDerivation rec {
  name = "sublime-text-${version}";

  phases = [
    "installPhase"
  ];

  installPhase = ''
    mkdir -pv $out/bin
    ln -sv ${sublime-text-bin}/sublime_text $out/bin/sublime_text
    ln -sv ${sublime-text-bin}/sublime_text $out/bin/subl

    mkdir -pv $out/share/applications
    ln -sv ${sublime-text-bin}/sublime_text.desktop $out/share/applications
    mkdir -pv $out/share/icons
    ln -sv ${sublime-text-bin}/Icon/256x256/sublime_text.png $out/share/icons
  '';

  meta = with stdenv.lib; {
    description = "Sophisticated text editor for code, markup and prose";
    homepage = https://www.sublimetext.com/;
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
