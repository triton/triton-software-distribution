{ stdenv
, buildPythonPackage
, fetchPyPi

, oauthlib
, requests
, six
}:

buildPythonPackage rec {
  name = "discogs-client-${version}";
  version = "2.2.1";

  src = fetchPyPi {
    package = "discogs-client";
    inherit version;
    sha256 = "9e32b5e45cff41af8025891c71aa3025b3e1895de59b37c11fd203a8af687414";
  };

  propagatedBuildInputs = [
    oauthlib
    requests
    six
  ];

  meta = with stdenv.lib; {
    description = "Official Python API client for Discogs";
    homepage = https://github.com/discogs/discogs_client/;
    license = licenses.bsd2;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
