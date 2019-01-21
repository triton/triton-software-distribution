{ stdenv
, fetchurl
, icu, expat, zlib, bzip2, python2, zstd, xz
, enableRelease ? true
, enableDebug ? false
, enableSingleThreaded ? false
, enableMultiThreaded ? true
, enableShared ? true
, enableStatic ? false
, enablePIC ? false
, enableExceptions ? false
, taggedLayout ? ((enableRelease && enableDebug) || (enableSingleThreaded && enableMultiThreaded) || (enableShared && enableStatic))
, patches ? null
, mpi ? null

, channel
}:

# We must build at least one type of libraries
assert !enableShared -> enableStatic;

with stdenv.lib;

let

  source = (import ./sources.nix { })."${channel}";

  variant = concatStringsSep ","
    (optional enableRelease "release" ++
     optional enableDebug "debug");

  threading = concatStringsSep ","
    (optional enableSingleThreaded "single" ++
     optional enableMultiThreaded "multi");

  link = concatStringsSep ","
    (optional enableShared "shared" ++
     optional enableStatic "static");

  runtime-link = if enableShared then "shared" else "static";

  # To avoid library name collisions
  layout = if taggedLayout then "tagged" else "system";

  cflags = if enablePIC && enableExceptions then
             "cflags=\"-fPIC -fexceptions\" cxxflags=-fPIC linkflags=-fPIC"
           else if enablePIC then
             "cflags=-fPIC cxxflags=-fPIC linkflags=-fPIC"
           else if enableExceptions then
             "cflags=-fexceptions"
           else
             "";

  genericB2Flags = [
    "--includedir=$dev/include"
    "--libdir=$lib/lib"
    "-j$NIX_BUILD_CORES"
    "--layout=${layout}"
    "variant=${variant}"
    "threading=${threading}"
    "runtime-link=${runtime-link}"
    "link=${link}"
    "${cflags}"
  ] ++ optional (variant == "release") "debug-symbols=off";

  nativeB2Flags = [
    "-sEXPAT_INCLUDE=${expat}/include"
    "-sEXPAT_LIBPATH=${expat}/lib"
  ] ++ optional (mpi != null) "--user-config=user-config.jam";
  nativeB2Args = concatStringsSep " " (genericB2Flags ++ nativeB2Flags);

  crossB2Flags = [
    "-sEXPAT_INCLUDE=${expat.crossDrv}/include"
    "-sEXPAT_LIBPATH=${expat.crossDrv}/lib"
    "--user-config=user-config.jam"
    "toolset=gcc-cross"
    "--without-python"
  ];
  crossB2Args = concatMapStringsSep " " (genericB2Flags ++ crossB2Flags);

  builder = b2Args: ''
    ./b2 ${b2Args}
  '';

  installer = b2Args: ''
    # boostbook is needed by some applications
    mkdir -p $dev/share/boostbook
    cp -a tools/boostbook/{xsl,dtd} $dev/share/boostbook/

    # Let boost install everything else
    ./b2 ${b2Args} install

    # Create a derivation which encompasses everything, making buildInputs nicer
    mkdir -p $out/nix-support
    echo "$dev $lib" > $out/nix-support/propagated-native-build-inputs
  '';

  commonConfigureFlags = [
    "--includedir=$(dev)/include"
    "--libdir=$(lib)/lib"
  ];

  fixup = ''
    # Make boost header paths relative so that they are not runtime dependencies
    (
      cd "$dev"
      find include \( -name '*.hpp' -or -name '*.h' -or -name '*.ipp' \) \
        -exec sed '1i#line 1 "{}"' -i '{}' \;
    )
  '';

in

stdenv.mkDerivation {
  name = "boost-${source.version}";

  src = fetchurl {
    url = "mirror://sourceforge/boost/boost/${source.version}/"
      + "boost_${replaceStrings ["."] ["_"] source.version}.tar.bz2";
    inherit (source) sha256;
  };

  preConfigure = ''
    NIX_LDFLAGS="$(echo $NIX_LDFLAGS | sed "s,$out,$lib,g")"
  '' + optionalString (mpi != null) ''
    cat << EOF > user-config.jam
    using mpi : ${mpi}/bin/mpiCC ;
    EOF
  '';

  buildInputs = [ icu expat zlib bzip2 zstd xz python2 ];

  configureScript = "./bootstrap.sh";
  configureFlags = commonConfigureFlags ++ [
    "--with-icu=${icu}"
    "--with-python=${python2.interpreter}"
  ];

  buildPhase = builder nativeB2Args;

  installPhase = installer nativeB2Args;

  postFixup = fixup;

  outputs = [ "out" "dev" "lib" ];

  crossAttrs = rec {
    buildInputs = [ expat.crossDrv zlib.crossDrv bzip2.crossDrv ];
    # all buildInputs set previously fell into propagatedBuildInputs, as usual, so we have to
    # override them.
    propagatedBuildInputs = buildInputs;
    # We want to substitute the contents of configureFlags, removing thus the
    # usual --build and --host added on cross building.
    preConfigure = ''
      export configureFlags="--without-icu ${concatStringsSep " " commonConfigureFlags}"
      set -x
      cat << EOF > user-config.jam
      using gcc : cross : $crossConfig-g++ ;
      EOF
    '';
    buildPhase = builder crossB2Args;
    installPhase = installer crossB2Args;
    postFixup = fixup;
  };

  meta = with stdenv.lib; {
    homepage = "http://boost.org/";
    description = "Collection of C++ libraries";
    license = licenses.boost;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
