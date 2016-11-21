{ stdenv
, fetchTritonPatch
, fetchurl
, scons

, boost
, cyrus-sasl
, gperftools
, libpcap
, openssl
, pcre
, snappy
, wiredtiger
, yaml-cpp
, zlib
}:

let
  version = "3.2.11";

  inherit (stdenv.lib)
    concatStringsSep;
in
stdenv.mkDerivation rec {
  name = "mongodb-${version}";

  src = fetchurl {
    url = "https://downloads.mongodb.org/src/mongodb-src-r${version}.tar.gz";
    sha256 = "625eb28fd47b2af63b30343a064de7f42e5265f4c642874ec766ba3643fd80d7";
  };

  nativeBuildInputs = [
    scons
  ];

  buildInputs = [
    boost
    cyrus-sasl
    gperftools
    libpcap
    openssl
    pcre
    snappy
    wiredtiger
    yaml-cpp
    zlib
  ];

  patches = [
    # Hopefully remove this in 3.2.11+
    (fetchTritonPatch {
      rev = "1a93e9f9c3689a6b85e2db14cec0f25ea26b1296";
      file = "m/mongodb/0001-boost-1.60.patch";
      sha256 = "0e9da35f4303e53daf51e78961c517895f2d12f4fa49298f01e1665e15246d73";
    })
    (fetchTritonPatch {
      rev = "1a93e9f9c3689a6b85e2db14cec0f25ea26b1296";
      file = "m/mongodb/0002-boost-1.62.patch";
      sha256 = "8ad9640407be6f945b38275ff75014c8ba2c6118a25fba63a490c640267b4b66";
    })

    # When not building with the system valgrind, the build should use the
    # vendored header file - regardless of whether or not we're using the system
    # tcmalloc - so we need to lift the include path manipulation out of the
    # conditional.
    (fetchTritonPatch {
      rev = "d7830e5e4f86c529163ccd6ce14cb77b95f27922";
      file = "m/mongodb/valgrind-include.patch";
      sha256 = "ad12f41e74acfeaaa7dd59acbc628ce8363b02c1342c5435df42f229f9fc6c17";
    })
  ];

  # Fix environment variable reading and reduces file size generation by removing debugging symbols
  postPatch = ''
    sed \
      -e '/-ggdb/d' \
      -e 's#env = Environment(#env = Environment(ENV = os.environ,#' \
      -i SConstruct
  '';

  makeFlags = [
    "--release"
    "--ssl"
    "--wiredtiger=on"
    "--js-engine=mozjs"
    "--use-sasl-client"
    "--use-system-pcre"
    "--use-system-wiredtiger"
    "--use-system-boost"
    "--use-system-snappy"
    "--use-system-zlib"
    # "--use-system-valgrind"
    # "--use-system-stemmer"
    "--use-system-yaml"
    # "--use-system-asio"
    # "--use-system-intel_decimal128"
    "--use-system-tcmalloc"
    "--disable-warnings-as-errors"
    "VARIANT_DIR=nixos" # Needed so we don't produce argument lists that are too long for gcc / ld
  ];
  
  buildFlags = [
    "core"
  ];

  preBuild = ''
    makeFlagsArray+=(
      "CCFLAGS=${concatStringsSep " " (map (input: "-I${input}/include") buildInputs)}"
      "LINKFLAGS=${concatStringsSep " " (map (input: "-L${input}/lib") buildInputs)}"
    )
  '';

  preInstall = ''
    installFlagsArray+=("--prefix=$out")
  '';

  meta = with stdenv.lib; {
    description = "a scalable, high-performance, open source NoSQL database";
    homepage = http://www.mongodb.org;
    license = licenses.agpl3;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
