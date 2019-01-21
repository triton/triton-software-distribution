{ stdenv
, buildPythonPackage
, fetchPyPi
, lib
}:

let
  version = "0.29.3";
in
buildPythonPackage {
  name = "cython-${version}";

  src = fetchPyPi {
    package = "Cython";
    inherit version;
    sha256 = "d687fb1cd9df28c1515666174c62e54bd894a6a6d0862f89705063cd47739f83";
  };

  meta = with lib; {
    description = "An optimising static compiler for the Python and Cython programming languages";
    homepage = http://cython.org;
    license = licenses.asl20;
    maintainers = with maintainers; [
      codyopel
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
