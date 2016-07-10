{ stdenv
, fetchurl
, fetchpatch
, which
, gnumake

, bzip2
#, harfbuzz
, libpng
, zlib

, infinality ? false
  , freetype2-infinality-ultimate

, glib /* passthru only */
}:

# NOTE: freetype2-infinality-ultimate must be updated in unison
#       with freetype.

let
  inherit (stdenv.lib)
    optionalString;
in

stdenv.mkDerivation rec {
  name = "freetype-2.6.4";

  src = fetchurl {
    urls = [
      "mirror://savannah/freetype/${name}.tar.bz2"
      "mirror://sourceforge/freetype/${name}.tar.bz2"
    ];
    allowHashOutput = false;
    sha256 = "5f83ce531c7035728e03f7f0421cb0533fca4e6d90d5e308674d6d313c23074d";
  };

  buildInputs = [
    bzip2
    #harfbuzz
    libpng
    zlib
  ];

  prePatch = optionalString infinality ''
    # freetype2-infinality-ultimate patch naming isn't completely
    # predictable, so build include all patches at build time.
    for i in '${freetype2-infinality-ultimate}/share/freetype2-infinality-ultimate/'*'.patch' ; do
      patches+=" $i"
    done
  '';

  configureFlags = [
    "--enable-biarch-config"
    "--with-zlib"
    "--with-bzip2"
    "--with-png"
    # Recursive dependency
    "--without-harfbuzz"
    "--without-old-mac-fonts"
    "--without-fsspec"
    "--without-fsref"
    "--without-quickdraw-toolbox"
    "--without-quickdraw-carbon"
    "--without-ats"
  ];

  # https://bugzilla.redhat.com/show_bug.cgi?id=506840
  NIX_CFLAGS_COMPILE = "-fno-strict-aliasing";

  postInstall = glib.flattenInclude;

  doCheck = true;

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      failEarly = true;
      pgpsigUrls = map (n: "${n}.sig") src.urls;
      pgpKeyFingerprint = "58E0 C111 E39F 5408 C5D3  EC76 C1A6 0EAC E707 FDA5";
    };
  };

  meta = with stdenv.lib; {
    description = "A font rendering engine";
    homepage = http://www.freetype.org/;
    license = licenses.gpl2Plus; # or the FreeType License (BSD + advertising clause)
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
