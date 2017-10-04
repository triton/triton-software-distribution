{ stdenv
, buildPythonPackage
, fetchPyPi

, libarchive-c
, python-magic
}:

let
  version = "87";
in
buildPythonPackage rec {
  name = "diffoscope-${version}";

  src = fetchPyPi {
    package = "diffoscope";
    inherit version;
    sha256 = "b62a69f095cb056f1b9e43b9d345e36b3b52b9ebe3de135978ae84ae88feba86";
  };

  postPatch = /* Fix invalid encoding in README */ ''
    sed -i setup.py \
      -e '/long_description/d'
  '';

  propagatedBuildInputs = [
    libarchive-c
    python-magic
  ];

  meta = with stdenv.lib; {
    description = "Perform in-depth comparison of files, archives, and directories";
    homepage = https://wiki.debian.org/ReproducibleBuilds;
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
