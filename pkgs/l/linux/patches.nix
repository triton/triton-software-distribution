{ stdenv, fetchurl, fetchTritonPatch }:

rec {
  bridge_stp_helper = {
    name = "bridge-stp-helper";
    patch = fetchTritonPatch {
      rev = "e25b3bc3302773b2572eb86db102b4769631c675";
      file = "linux-kernel/bridge-stp-helper.patch";
      sha256 = "53d467696157b4ca71535a3021d8b9d8db3fa765ea2f8db01fbf2e607e6032e5";
    };
  };
}
