{ stdenv
, fetchurl
, substituteAll

, freetype
, expat
, libxslt
, xorg
}:

/** Font configuration scheme
 * - ./config-compat.patch makes fontconfig try the following root
 *   configs, in order: $FONTCONFIG_FILE,
 *   /etc/fonts/${configVersion}/fonts.conf, /etc/fonts/fonts.conf.
 *   This is done not to override config of pre-2.11 versions (which
 *   just blows up) and still use *global* font configuration at
 *   both NixOS or non-NixOS.
 * - NixOS creates /etc/fonts/${configVersion}/fonts.conf link to
 *   $out/etc/fonts/fonts.conf, and other modifications should go to
 *   /etc/fonts/${configVersion}/conf.d
 * - See ./make-fonts-conf.xsl for config details.
 */

let
  # bump whenever fontconfig breaks compatibility with older configurations
  configVersion = "2.12";
in
stdenv.mkDerivation rec {
  name = "fontconfig-2.12.1";

  src = fetchurl {
    urls = [
      "https://www.freedesktop.org/software/fontconfig/release/${name}.tar.bz2"
      "http://fontconfig.org/release/${name}.tar.bz2"
    ];
    sha256 = "b449a3e10c47e1d1c7a6ec6e2016cca73d3bd68fbbd4f0ae5cc6b573f7d6c7f3";
  };

  patches = [
    (substituteAll {
      src = ./config-compat.patch;
      inherit configVersion;
    })
  ];

  buildInputs = [
    expat
    freetype
  ];

  configureFlags = [
    "--enable-iconv"
    #"--enable-libxml2"
    "--disable-docs"
    # This is what you get when loading fontconfig's config fails
    # for any reason.
    "--with-default-fonts=${xorg.fontbhttf}"
    "--with-cache-dir=/var/cache/fontconfig"
  ];

  # Don't try to write to /var/cache/fontconfig at install time.
  installFlags = [
    "fc_cachedir=$(TMPDIR)/dummy"
    "RUN_FC_CACHE_TEST=false"
  ];

  postInstall = ''
    cd "$out/etc/fonts"
    rm conf.d/{50-user,51-local}.conf
    "${libxslt}/bin/xsltproc" --stringparam fontDirectories "${xorg.fontbhttf}" \
      --stringparam fontconfig "$out" \
      --stringparam fontconfigConfigVersion "${configVersion}" \
      --path $out/share/xml/fontconfig \
      ${./make-fonts-conf.xsl} $out/etc/fonts/fonts.conf \
      > fonts.conf.tmp
    mv fonts.conf.tmp $out/etc/fonts/fonts.conf
  '';

  doCheck = true;

  passthru = {
    inherit configVersion;
  };

  meta = with stdenv.lib; {
    description = "A library for font customization and configuration";
    homepage = http://fontconfig.org/;
    license = licenses.bsd2; # custom but very bsd-like
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}

