let lib = import ./default.nix;
    inherit (builtins) getAttr attrNames isFunction;

in

rec {


  /* `overrideDerivation drv f' takes a derivation (i.e., the result
     of a call to the builtin function `derivation') and returns a new
     derivation in which the attributes of the original are overriden
     according to the function `f'.  The function `f' is called with
     the original derivation attributes.

     `overrideDerivation' allows certain "ad-hoc" customisation
     scenarios (e.g. in ~/.nixpkgs/config.nix).  For instance, if you
     want to "patch" the derivation returned by a package function in
     Nixpkgs to build another version than what the function itself
     provides, you can do something like this:

       mySed = overrideDerivation pkgs.gnused (oldAttrs: {
         name = "sed-4.2.2-pre";
         src = fetchurl {
           url = ftp://alpha.gnu.org/gnu/sed/sed-4.2.2-pre.tar.bz2;
           sha256 = "11nq06d131y4wmf3drm0yk502d2xc6n5qy82cg88rb9nqd2lj41k";
         };
         patches = [];
       });

     For another application, see build-support/vm, where this
     function is used to build arbitrary derivations inside a QEMU
     virtual machine. */
     
  overrideDerivation = drv: f:
    let
      # Filter out special attributes.
      drop = ["meta" "passthru" "outPath" "drvPath" "hostDrv" "buildDrv" "type" "override" "deepOverride" "origArgs"]
              # also drop functions such as .merge .override etc
             ++ lib.filter (n: isFunction (getAttr n drv)) (attrNames drv);
      attrs = removeAttrs drv drop;
      newDrv = derivation (attrs // (f drv));
    in newDrv //
      { meta = if drv ? meta then drv.meta else {};
        passthru = if drv ? passthru then drv.passthru else {};
      };


  # usage: (you can use override multiple times)
  # let d = makeOverridable stdenv.mkDerivation { name = ..; buildInputs; }
  #     noBuildInputs = d.override { buildInputs = []; }
  #     additionalBuildInputs = d.override ( args : args // { buildInputs = args.buildInputs ++ [ additional ]; } )
  makeOverridable = f: origArgs: f origArgs //
    { override = newArgs:
        makeOverridable f (origArgs // (if builtins.isFunction newArgs then newArgs origArgs else newArgs));
      deepOverride = newArgs:
        makeOverridable f ((lib.mapAttrs (deepOverrider newArgs) origArgs) // newArgs);
      origArgs = origArgs;
    };


  deepOverrider = newArgs: name: x: if builtins.isAttrs x then (
    if x ? deepOverride then (x.deepOverride newArgs) else
    if x ? override then (x.override newArgs) else
    x) else x;
    
        
}
