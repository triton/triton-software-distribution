{ stdenv
, fetchTritonPatch
, fetchurl

, bzip2
, db
, expat
, gdbm
, libffi
, ncurses
, openssl
, readline
, sqlite
, xz
, zlib

# Inherit generics
, channel ? null

# Passthru
, callPackage
, self
}:

/*
 * Test the following packages when making major changes, as they
 * look for or link against libpython:
 * - gst-python 0.10.x & 1.x
 * - libtorrent-rasterbar
 * - pycairo
 */

let
  inherit (stdenv)
    isLinux;
  inherit (stdenv.lib)
    any
    concatStringsSep
    head
    optional
    optionals
    optionalString
    splitString
    versionAtLeast
    versionOlder
    wtFlag;
  inherit (builtins.getAttr channel (import ./sources.nix))
    pgpKeyFingerprint
    versionMinor
    sha256;
in

let
  versionMajor = channel;
  isPy2 = versionOlder versionMajor "3.0";
  isPy3 = versionAtLeast versionMajor "3.0";
  ifPy2 = a: b:
    if isPy2 then
      a
    else
      b;
  ifPy3 = a: b:
    if isPy3 then
      a
    else
      b;
  # For alpha releases we need to discard a<int> from the version for
  # part of the url.
  baseVersionMinor =
    let
      s = splitString "a" versionMinor;
    in
    head s;
in

# Supported channels
assert any (n: n == channel) [
  "2.7"
  "3.3"
  "3.4"
  "3.5"
  "3.6"
];

stdenv.mkDerivation rec {
  name = "python-${version}";
  inherit versionMajor;
  inherit versionMinor;
  version = "${versionMajor}.${versionMinor}";

  src = fetchurl {
    url = "https://www.python.org/ftp/python/"
      + "${versionMajor}.${baseVersionMinor}/Python-${version}.tar.xz";
    inherit sha256;
    allowHashOutput = false;
  };

  buildInputs = [
    bzip2
    db
    expat
    gdbm
    libffi
    ncurses
    openssl
    readline
    sqlite
    stdenv.cc.libc
    zlib
  ] ++ optionals isPy3 [
    xz
  ];

  setupHook = stdenv.mkDerivation {
    name = "python-${versionMajor}-setup-hook";
    buildCommand = ''
      sed 's,@VERSION_MAJOR@,${versionMajor},g' ${./setup-hook.sh.in} > $out
    '';
    preferLocalBuild = true;
  };

  patches = optionals isPy2 [
    # Patch python to put zero timestamp into pyc
    # if DETERMINISTIC_BUILD env var is set
    (fetchTritonPatch {
      rev = "d3fc5e59bd2b4b465c2652aae5e7428b24eb5669";
      file = "python/python-2.7-deterministic-build.patch";
      sha256 = "7b8ed591008f8f0dafb7f2c95d06404501c84223197fe138df75791f12a9dc24";
    })
    (fetchTritonPatch {
      rev = "d3fc5e59bd2b4b465c2652aae5e7428b24eb5669";
      file = "python/python-2.7-properly-detect-curses.patch";
      sha256 = "c0d17df5f1c920699f68a1c87973d626ea8423a4881927b0ac7a20f88ceedcb4";
    })
    # Python recompiles a Python if the mtime stored *in* the
    # pyc/pyo file differs from the mtime of the source file.  This
    # doesn't work in Nix because Nix changes the mtime of files in
    # the Nix store to 1.  So treat that as a special case.
    (fetchTritonPatch {
      rev = "d3fc5e59bd2b4b465c2652aae5e7428b24eb5669";
      file = "python/python-2.x-nix-store-mtime.patch";
      sha256 = "0869ba7b51b1c4b8f9779118a75ce34332a69f41909e5dfcd9305d2a9bcce638";
    })
  ];

  postPatch =
    /* Prevent setup.py from looking for include/lib
       directories in impure paths */ ''
    for i in /usr /sw /opt /pkg ; do
      sed -i setup.py \
        -e "s,$i,/no-such-path,"
    done
  '';

  preConfigure =
    /* Something here makes portions of the build magically work,
       otherwise boost_python never builds */ ''
    configureFlagsArray+=(
      CPPFLAGS="${concatStringsSep " " (map (p: "-I${p}/include") buildInputs)}"
      LDFLAGS="${concatStringsSep " " (map (p: "-L${p}/lib") buildInputs)}"
      LIBS="-lncurses"
    )
  '';

  configureFlags = [
    "--disable-universalsdk"
    "--disable-framework"
    "--enable-shared"
    #"--disable-profiling"
    "--disable-toolbox-glue"
    (ifPy3 "--enable-loadable-sqlite-extensions" null)
    "--enable-ipv6"
    (ifPy2 "--enable-unicode=ucs4" null)
    #(wtFlag "gcc" (!stdenv.cc.isClang) null)
    #"--enable-big-digits" # py3
    #"--with-hash-algorithm" # py3
    (if (versionAtLeast versionMajor "3.5") then
      # Flag is not a boolean
      (if stdenv.cc.isClang then
        "--with-address-sanitizer"
       else
         null)
     else
       null)
    "--with-system-expat"
    "--with-system-ffi"
    #"--with-system-libmpdec" # py3
    #"--with-dbmliborder"
    #"--with-signal-module"
    "--with-threads"
    #"--with-doc-strings"
    #"--with-tsc"
    #"--with-pymalloc"
    "--without-valgrind"
    #"--with-fpectl"
    #"--with-libm"
    #"--with-libc"
    #"--with-computed-gotos"
    #"--with-ensurepip"
  ];

  # Should this be stdenv.cc.isGnu???
  NIX_LDFLAGS = "-lgcc_s";

  postInstall =
    /* Needed for some packages, especially packages that
       backport functionality to 2.x from 3.x */ ''
    for item in $out/lib/python${versionMajor}/test/* ; do
      if [[ "$item" != */test_support.py* ]] ; then
        rm -rvf "$item"
      else
        echo $item
      fi
    done
  '' + optionalString isPy3 ''
    pushd $out/lib/pkgconfig
      if [ ! -f 'python3.pc' ] ; then
        ln -sv python-*.pc python3.pc
      fi
    popd
    set +x
  '' + ''
    touch $out/lib/python${versionMajor}/test/__init__.py
  '' + ''
    paxmark E $out/bin/python${versionMajor}
  '' + optionalString isPy3
    /* Some programs look for libpython<major>.<minor>.so */ ''
    if [ ! -f "$out/lib/libpython${versionMajor}.so" ] ; then
      ln -sv \
        $out/lib/libpython3.so \
        $out/lib/libpython${versionMajor}.so
    fi
  '' + optionalString isPy3
    /* Symlink include directory */ ''
    if [ ! -d "$out/include/python${versionMajor}" ] ; then
      ln -sv \
        $out/include/python${versionMajor}m \
        $out/include/python${versionMajor}
    fi
  '' + optionalString isPy2 ''
    # TODO: reference reason for pdb symlink
    ln -sv $out/lib/python${versionMajor}/pdb.py $out/bin/pdb
    ln -sv $out/lib/python${versionMajor}/pdb.py $out/bin/pdb${versionMajor}
    ln -sv $out/share/man/man1/{python2.7.1.gz,python.1.gz}
  '';

  preFixup = /* Simple test to make sure modules built */ ''
    echo "Testing modules"
    $out/bin/python${versionMajor} -c "import bz2"
    $out/bin/python${versionMajor} -c "import crypt"
    $out/bin/python${versionMajor} -c "import ctypes"
    $out/bin/python${versionMajor} -c "import curses"
    $out/bin/python${versionMajor} -c "from curses import panel"
    $out/bin/python${versionMajor} -c "import math"
    $out/bin/python${versionMajor} -c "import readline"
    $out/bin/python${versionMajor} -c "import sqlite3"
    $out/bin/python${versionMajor} -c "import ssl"
    $out/bin/python${versionMajor} -c "import zlib"
  '' + optionalString isPy2 ''
    $out/bin/python${versionMajor} -c "import gdbm"
  '' + optionalString isPy3 ''
    $out/bin/python${versionMajor} -c "from dbm import gnu"
    $out/bin/python${versionMajor} -c "import lzma"
  '';

  postFixup = ''
    # The lines we are replacing dont include libpython so we parse it out
    LIBS_WITH_PYTHON="$(pkg-config --libs --static $out/lib/pkgconfig/python-${versionMajor}.pc)"
    LIBS="$(echo "$LIBS_WITH_PYTHON" | sed 's,[ ]*\(-L\|-l\)[^ ]*python[^ ]*[ ]*, ,g')"
  '' + ''
    sed -i $out/lib/python${versionMajor}/config${ifPy3 "-${versionMajor}m" ""}/Makefile \
      -e "s@^LIBS=.*@LIBS= $LIBS@g"

    # We need to update _sysconfigdata.py{,o,c}
    sed -i "s@'\(SH\|\)LIBS': '.*',@'\1LIBS': '$LIBS',@g" $out/lib/python${versionMajor}/_sysconfigdata.py
  '' + optionalString isPy2 ''
    rm $out/lib/python${versionMajor}/_sysconfigdata.py{o,c}
  '' + optionalString isPy3 ''
    rm $out/lib/python${versionMajor}/__pycache__/_sysconfigdata*.pyc
  '' + ''
    $out/bin/python${versionMajor} -c "import _sysconfigdata"
    $out/bin/python${versionMajor} -O -c "import _sysconfigdata"
    $out/bin/python${versionMajor} -OO -c "import _sysconfigdata"
    $out/bin/python${versionMajor} -OOO -c "import _sysconfigdata"

    sed --follow-symlinks -i $out/bin/python${versionMajor}-config \
      -e "s@^LIBS=\".*\"@LIBS=\"$LIBS_WITH_PYTHON\"@g"
  '';

  # Used by python-2.7-deterministic-build.patch
  DETERMINISTIC_BUILD = 1;

  passthru = rec {
    inherit
      isPy2
      isPy3
      version
      versionMajor;

    dbSupport = db != null;
    opensslSupport = openssl != null;
    readlineSupport = readline != null;
    sqliteSupport = sqlite != null;
    tkSupport = false;
    zlibSupport = zlib != null;

    libPrefix = "python${versionMajor}";
    executable = "python${versionMajor}";
    buildEnv = callPackage ../wrapper.nix { python = self; };
    sitePackages = "lib/${libPrefix}/site-packages";
    interpreter = "${self}/bin/${executable}";

    srcVerification = fetchurl rec {
      inherit pgpKeyFingerprint;
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
    };
  };

  meta = with stdenv.lib; {
    description = "An interpreted, object-oriented programming language";
    homepage = "http://www.python.org/";
    license = licenses.psf-2;
    maintainers = with maintainers; [
      codyopel
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
