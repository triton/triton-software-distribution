{ stdenv
, buildPythonPackage
, fetchFromGitHub
, pythonPackages

, acme
, ConfigArgParse
, configobj
, cryptography
, parsedatetime
, pkgs
, psutil
, pyopenssl
, python2-pythondialog
, pyRFC3339
, pytz
, six
, zope-component
, zope-interface
}:

let
  inherit (pythonPackages)
    isPy3k;
in

buildPythonPackage rec {
  name = "certbot-${version}";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "certbot";
    repo = "certbot";
    rev = "v${version}";
    sha256 = "48c453db74457ac88130480052246c132497fafd81c69e6ff9ff02f33243b855";
  };

  pythonPath = [
    acme
    ConfigArgParse
    configobj
    cryptography
    parsedatetime
    pkgs.dialog
    psutil
    pyopenssl
    python2-pythondialog
    pyRFC3339
    pytz
    six
    zope-component
    zope-interface
  ];

  disabled = isPy3k;
  doCheck = true;

  meta = with stdenv.lib; {
    description = "EFF's tool to obtain certs from Let's Encrypt";
    homepage = https://github.com/certbot/certbot;
    license = licenses.asl20;
    maintainers = with maintainers; [
      codyopel
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
