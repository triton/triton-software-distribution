{ stdenv
, fetchurl
}:

let
  version = "2018-07-30";
in
stdenv.mkDerivation rec {
  name = "linux-firmware-${version}";

  # This repo is built from
  # http://git.kernel.org/cgit/linux/kernel/git/firmware/linux-firmware.git/
  # for any given date. This gives us up to date iwlwifi firmware as well as
  # the usual set of firmware. firmware/linux-firmware usually lags kernel releases
  # so iwlwifi cards will fail to load on newly released kernels.
  src = fetchurl {
    url = "https://github.com/wkennington/linux-firmware/releases/download/${version}/${name}.tar.xz";
    sha256 = "005edce365b48c978ce58f239bcc6577cc9fec1f9044b7f16cc89b6494efecf1";
  };

  preInstall = ''
    mkdir -p $out
  '';

  installFlags = [
    "DESTDIR=$(out)"
  ];

  passthru = {
    inherit version;
  };

  meta = with stdenv.lib; {
    description = "Binary firmware collection packaged by kernel.org";
    license = licenses.unfreeRedistributableFirmware;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
    priority = 6; # give precedence to kernel firmware
  };
}
