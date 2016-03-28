{ stdenv
, gdk-pixbuf-core
, librsvg
}:

# This is a meta package for all gdk-pixbuf loaders, see
# gdk-pixbuf-core for the main gdk-pixbuf package.

stdenv.mkDerivation rec {
  name = "gdk-pixbuf-${gdk-pixbuf-core.version}";

  setupHook = ./setup-hook.sh;

  phases = [
    "$prePhases"
    "patchPhase"
    "buildPhase"
    "installPhase"
    "fixupPhase"
    "$postPhases"
  ];

  propagatedBuildInputs = [
    gdk-pixbuf-core
    librsvg
  ];

  buildPhase = ''
    export GDK_PIXBUF_MODULE_FILE='loaders.cache'

    echo "Generating loaders.cache"
    gdk-pixbuf-query-loaders --update-cache \
      ${gdk-pixbuf-core}/lib/gdk-pixbuf-2.0/2.10.0/loaders/*.so \
      ${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders/*.so
  '';

  installPhase = ''
    install -vD -m 644 loaders.cache \
      $out/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
  '';

  dontStrip = true;

  meta = with stdenv.lib; {
    description = "A library for image loading and manipulation";
    homepage = http://library.gnome.org/devel/gdk-pixbuf/;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
