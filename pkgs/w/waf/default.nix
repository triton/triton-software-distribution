{ stdenv
, fetchurl
, lib

, python3

, channel
}:

let
  autowaf = fetchurl {
    # r101
    # This is not a persistent URL since it is the SVN repo, so we rely on
    # using the multihash.
    url = "http://svn.drobilla.net/autowaf/autowaf.py";
    multihash = "Qmbztdz9ry33VWVtgzASTbXDwcwxKtmFBZ1y5nsHA1rE97";
    sha256 = "6cecb0c26bcbe046f8ef4742ae46834518dabff59dfab68dd2ae1f9704b193bd";
  };
  sources = {
    "1.9" = {
      version = "1.9.15";
      multihash = "QmaXJ7fQJTfM77DNnEg4HH6b6odMYtKpHhVVEiqmZV5EQh";
      sha256 = "4b7b92aaf90828853d57bed9a89a7c0e965d5af3c03717b970d67ff3ae4f2483";
    };
    "2.0" = {
      version = "2.0.4";
      multihash = "QmPysbZWegyPT8GMZo8StwN69g8okQ6xYX5CtwrTvGLtYB";
      sha256 = "36aaa3ee6aff75058a694b6c53c3cdf3080c882e134811dd8d4716ccd8e3b67e";
    };
  };
  source = sources."${channel}";
in
stdenv.mkDerivation rec {
  name = "waf-${source.version}";

  src = fetchurl {
    url = "https://waf.io/${name}.tar.bz2";
    hashOutput = false;
    inherit (source)
      multihash
      sha256;
  };

  buildInputs = [
    python3
  ];

  setupHook = ./setup-hook.sh;

  postPatch = ''
    sed -i waf-light -e 's,env python,env python3,'
    patchShebangs waf-light
  '';

  configurePhase = ''
    ./waf-light configure
  '';

  buildPhase = ''
    cp -v ${autowaf} autowaf.py
    ./waf-light build --tools=$(pwd)/autowaf.py
  '';

  installPhase = ''
    install -D -m755 -v waf $out/bin/waf
  '';

  passthru = {
    srcVerification = fetchurl {
      inherit (src)
        outputHash
        outputHashAlgo
        urls;
      failEarly = true;
      pgpsigUrls = map (n: "${n}.asc") src.urls;
      # Thomas Nagy
      pgpKeyFingerprint = "8AF2 2DE5 A068 22E3 474F  3C70 49B4 C67C 0527 7AAA";
    };
  };

  meta = with lib; {
    description = "Meta build system";
    homepage = https://waf.io/;
    license = licenses.bsd3;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
