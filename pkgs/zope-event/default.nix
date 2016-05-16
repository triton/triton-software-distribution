{ stdenv
, buildPythonPackage
, fetchPyPi
}:

buildPythonPackage rec {
  name = "zope.event-${version}";
  version = "4.2.0";

  src = fetchPyPi {
    package = "zope.event";
    inherit version;
    sha256 = "ce11004217863a4827ea1a67a31730bddab9073832bdb3b9be85869259118758";
  };

  doCheck = true;

  meta = with stdenv.lib; {
    description = "An event publishing system";
    homepage = https://pypi.python.org/pypi/zope.event;
    license = licenses.zpt20;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
