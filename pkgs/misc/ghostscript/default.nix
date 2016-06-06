{ stdenv
, lib
, fetchurl
, fetchTritonPatch
, libidn
, libpaper
, fontconfig
, dbus
, freetype
, libjpeg
, zlib
, libpng
, lcms2
, ijs
, jbig2dec
, x11Support ? false, xorg
, cupsSupport ? false, cups
}:

let
  version = "9.19";
  versionNoP = lib.replaceChars ["."] [""] version;
  sha256 = "f67acdcfcde1f86757ff3553cd719f12eac2d7681a0e96d8bdd1f40a0f47b45b";

  fonts = stdenv.mkDerivation {
    name = "ghostscript-fonts";

    srcs = [
      (fetchurl {
        url = "mirror://sourceforge/gs-fonts/ghostscript-fonts-std-8.11.tar.gz";
        sha256 = "00f4l10xd826kak51wsmaz69szzm2wp8a41jasr4jblz25bg7dhf";
      })
      (fetchurl {
        url = "mirror://gnu/ghostscript/gnu-gs-fonts-other-6.0.tar.gz";
        sha256 = "1cxaah3r52qq152bbkiyj2f7dx1rf38vsihlhjmrvzlr8v6cqil1";
      })
      # ... add other fonts here
    ];

    installPhase = ''
      mkdir "$out"
      mv -v * "$out/"
    '';
  };

in
stdenv.mkDerivation rec {
  name = "ghostscript-${version}";

  src = fetchurl {
    url = "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${versionNoP}/${name}.tar.bz2";
    inherit sha256;
  };

  outputs = [ "out" "doc" ];

  buildInputs = [
    libidn
    libpaper
    fontconfig
    dbus
    freetype
    libjpeg
    zlib
    libpng
    lcms2
    ijs
    jbig2dec
  ] ++ stdenv.lib.optionals x11Support [
    xorg.xproto
    xorg.libX11
  ] ++ stdenv.lib.optional cupsSupport cups
      ;

  NIX_ZLIB_INCLUDE = "${zlib}/include";

  patches = [
    (fetchTritonPatch {
      rev = "16e1e82d413e33a3a46976f64c275c58a7dc3928";
      file = "ghostscript/urw-font-files.patch";
      sha256 = "1f7e0e309802c4400a31eaadbdd4eb89c63db848f867891119156ce2cffd5c89";
    })
  ];

  postPatch = ''
    rm -r freetype jbig2dec jpeg lcms2 libpng tiff zlib ijs

    sed "s@if ( test -f \$(INCLUDE)[^ ]* )@if ( true )@; s@INCLUDE=/usr/include@INCLUDE=/no-such-path@" -i base/unix-aux.mak
    sed "s@^ZLIBDIR=.*@ZLIBDIR=${zlib}/include@" -i configure.ac
  '' + lib.optionalString cupsSupport ''
    configureFlagsArray+=(
      "--with-cups-serverbin=$out/lib/cups"
      "--with-cups-serverroot=$out/etc/cups"
      "--with-cups-datadir=$out/share/cups"
    )
  '';

  configureFlags = [
    "--with-system-libtiff"
    "--enable-fontconfig"
    "--enable-freetype"
    "--enable-dynamic"
  ] ++ lib.optional x11Support "--with-x"
    ++ lib.optional cupsSupport "--enable-cups"
    ;

  doCheck = true;

  # don't build/install statically linked bin/gs
  buildFlags = [ "so" ];
  installTargets = [ "soinstall" ];

  postInstall = ''
    ln -s gsc "$out"/bin/gs

    cp -r Resource "$out/share/ghostscript/${version}"

    mkdir -p "$doc/share/ghostscript/${version}"
    mv "$out/share/ghostscript/${version}"/{doc,examples} "$doc/share/ghostscript/${version}/"

    ln -s "${fonts}" "$out/share/ghostscript/fonts"
  '';

  # Sometimes throws weird errors for 9.18
  parallelInstall = false;

  passthru = {
    inherit version;
  };

  meta = with stdenv.lib; {
    homepage = "http://www.ghostscript.com/";
    description = "PostScript interpreter (mainline version)";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
