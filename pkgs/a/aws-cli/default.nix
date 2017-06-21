{ stdenv
, buildPythonPackage
, fetchzip
, lib

, botocore
, colorama
, docutils
, pyyaml
, rsa
, s3transfer
}:

let
  version = "1.11.109";
in
buildPythonPackage rec {
  name = "aws-cli-${version}";

  src = fetchzip {
    version = 3;
    url = "https://github.com/aws/aws-cli/archive/${version}.tar.gz";
    sha256 = "4bda37a6057bdf5e1c14db7b2891b092d152ddcde187c2800672cdefdbf95004";
  };

  propagatedBuildInputs = [
    botocore
    colorama
    docutils
    pyyaml
    rsa
    s3transfer
  ];

  postPatch = /* Allow using newer dependencies */ ''
    sed -i setup.py \
      -e "s/colorama.*/colorama',/"
    sed -i requirements.txt \
      -i setup.cfg \
      -e "s/,<.*//g"
  '';

  postInstall = ''
    rm -f "$out"/bin/{aws.cmd,aws_completer,aws_bash_completer,aws_zsh_completer.sh}
  '';

  meta = with lib; {
    description = "Command Line Interface for Amazon Web Services";
    homepage = https://github.com/aws/aws-cli;
    license = licenses.asl20;
    maintainers = with maintainers; [
      codyopel
    ];
    platforms = with platforms;
      x86_64-linux;
  };
}
