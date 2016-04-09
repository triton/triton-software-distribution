{ stdenv
, fetchFromGitHub
, python2
, ninja

, llvmPackages
}:

stdenv.mkDerivation {
  name = "libclc-2016-02-09";

  src = fetchFromGitHub {
    owner = "llvm-mirror";
    repo = "libclc";
    rev = "b518692b52a0bbdf9cf0e2167b9629dd9501abcd";
    sha256 = "177077f93449033d3e453fb601ab0aebb1b1badd70ec3d9d5112cadcf7b0c6c5";
  };

  nativeBuildInputs = [
    python2
    ninja
  ];
  buildInputs = [
    llvmPackages.llvm
    llvmPackages.clang
  ];

  postPatch = ''
    sed -i 's,^\(llvm_clang =\).*,\1 "${llvmPackages.clang}/bin/clang",g' configure.py
    patchShebangs .
  '';

  preConfigure = ''
    configureFlagsArray+=("--pkgconfigdir=$out/lib/pkgconfig")
  '';

  configureScript = "./configure.py";

  configureFlags = [
    "-g" "ninja"
    "--with-cxx-compiler=${llvmPackages.clang}/bin/clang++"
  ];

  meta = with stdenv.lib; {
    homepage = http://libclc.llvm.org/;
    description = "Implementation of the library requirements of the OpenCL C programming language";
    license = licenses.mit;
    maintainers = with maintainers; [
      wkennington
    ];
    platforms = with platforms;
      i686-linux
      ++ x86_64-linux;
  };
}
