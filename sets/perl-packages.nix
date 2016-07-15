{ stdenv
, pkgs
, perl
, self
}:

let
  callPackage = pkgs.newScope (self // {
    inherit pkgs;
    perlPackages = self;
  });
in {

inherit perl;

buildPerlPackage = callPackage ../all-pkgs/build-perl-package { };

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
############################### BEGIN ALL PKGS #################################
################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

DBD-SQLite = callPackage ../all-pkgs/DBD-SQLite { };

DBI = callPackage ../all-pkgs/DBI { };

Locale-gettext = callPackage ../all-pkgs/Locale-gettext { };
}
