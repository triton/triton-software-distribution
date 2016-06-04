{ stdenv, runCommand, glibc, fetchurl, file

, version
}:

let
  # !!! These should be on nixos.org
  src = if glibc.system == "x86_64-linux" then
    (if version == "8" then
      fetchurl {
        name = "openjdk8-bootstrap-x86_64-linux.tar.xz";
        multihash = "QmTkD5FLDCHpe5jmha7zViQiLbtszkNCjZa4QVitwfeCsH";
        sha256 = "18zqx6jhm3lizn9hh6ryyqc9dz3i96pwaz8f6nxfllk70qi5gvks";
      }
    else if version == "7" then
      fetchurl {
        name = "openjdk7-bootstrap-x86_64-linux.tar.xz";
        multihash = "QmNc5zHMHxXb3ZczSApvC4rXvXmeoX3AZmvMKD1MqLbwUn";
        sha256 = "024gg2sgg4labxbc1nhn8lxls2p7d9h3b82hnsahwaja2pm1hbra";
      }
    else throw "No bootstrap for version")
  else if glibc.system == "i686-linux" then
    (if version == "8" then
      fetchurl {
        name = "openjdk8-bootstrap-i686-linux.tar.xz";
        multihash = "QmWcxGtbkjFXYoT272esZx2bjaomnDuphmk8K5wzjsALGv";
        sha256 = "1yx04xh8bqz7amg12d13rw5vwa008rav59mxjw1b9s6ynkvfgqq9";
      }
    else if version == "7" then
      fetchurl {
        name = "openjdk7-bootstrap-i686-linux.tar.xz";
        multihash = "QmRYZgpeWzwCgmEt93SCKH5QeQexj6a5ZWspESdrtyXFmm";
        sha256 = "0xwqjk1zx8akziw8q9sbjc1rs8s7c0w6mw67jdmmi26cwwp8ijnx";
      }
    else throw "No bootstrap for version")
  else throw "No bootstrap for system";

  bootstrap = runCommand "openjdk-bootstrap" {
    passthru = {
      home = "${bootstrap}/lib/openjdk";
    };
  } ''
    tar xvf ${src}
    mv openjdk-bootstrap $out

    LIBDIRS="$(find $out -name \*.so\* -exec dirname {} \; | sort | uniq | tr '\n' ':')"

    for i in $out/bin/*; do
      patchelf --set-interpreter ${glibc}/lib/ld-linux*.so.2 $i || true
      patchelf --set-rpath "${glibc}/lib:$LIBDIRS" $i || true
    done

    find $out -name \*.so\* | while read lib; do
      patchelf --set-interpreter ${glibc}/lib/ld-linux*.so.2 $lib || true
      patchelf --set-rpath "${glibc}/lib:${stdenv.cc.cc}/lib:$LIBDIRS" $lib || true
    done
  '';
in bootstrap
