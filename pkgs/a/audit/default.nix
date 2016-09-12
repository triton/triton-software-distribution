{ stdenv
, fetchurl
, swig

, go
, libcap-ng
, krb5_lib
, openldap
, python2
, python3
, tcp-wrappers

, prefix ? ""
}:

let
  inherit (stdenv.lib)
    optionals
    optionalString;
in

let
  libOnly = prefix == "lib";

  version = "2.6.7";
in
stdenv.mkDerivation rec {
  name = "${prefix}audit-${version}";

  src = fetchurl {
    url = "https://people.redhat.com/sgrubb/audit/audit-${version}.tar.gz";
    multihash = "QmS3gYy2Y5dW69Z6RfMvM2VLNx2qahvHg1PafVDXHxqEvU";
    sha256 = "8923917332daa7833bbc0c1d9eb012167093fbad000da4a9630fb3356aff8cdc";
  };

  nativeBuildInputs = [
    swig
  ];

  buildInputs = [
    go
    libcap-ng
    python2
    python3
  ] ++ optionals (!libOnly) [
    krb5_lib
    tcp-wrappers
    openldap
  ];

  postPatch = ''
    # Get the absolute paths to the needed headers for swig
    echo -e '#include <stdint.h>\n#include <linux/audit.h>' | gcc -M -xc - \
      | tail -n +2 | awk "{print \"-e\ns,[^<\\\\\\\"]*/\"substr(\$1, match(\$1, \"include\"))\",\"\$1\",g\"}" \
      | xargs sed -i bindings/swig/src/auditswig.i
  '';

  configureFlags = [
    "--with-python"
    "--with-python3"
    "--with-golang"
    "--${if libOnly then "disable" else "enable"}-listener"
    "--${if libOnly then "disable" else "enable"}-zos-remote"
    "--${if libOnly then "disable" else "enable"}-gssapi-krb5"
    "--disable-systemd"
    "--without-debug"
    "--without-warn"
    "--without-alpha"  # TODO: Support
    "--without-arm"  # TODO: Support
    "--without-aarch64"  # TODO: Support
    "--${if libOnly then "without" else "with"}-apparmor"
    "--without-prelude"
    "--${if libOnly then "without" else "with"}-libwrap${if libOnly then "" else "=${tcp-wrappers}"}"
  ];

  # For libs only build and install the lib portion
  buildPhase = optionalString libOnly ''
    function buildDir() {
      pushd $1
      shift
      make -j $NIX_BUILD_CORES $@
      popd
    }

    buildDir lib
    buildDir auparse
    buildDir bindings
  '';

  installPhase = optionalString libOnly ''
    buildDir lib install
    buildDir auparse install
    buildDir bindings install
  '';

  meta = with stdenv.lib; {
    description = "Audit Library";
    homepage = "http://people.redhat.com/sgrubb/audit/";
    license = licenses.gpl2;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
