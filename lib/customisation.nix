let

  lib = import ./default.nix;
  inherit (builtins) attrNames isFunction;

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
     virtual machine.
  */
  overrideDerivation = drv: f:
    let
      newDrv = derivation (drv.drvAttrs // (f drv));
    in addPassthru newDrv (
      { meta = drv.meta or {};
        passthru = if drv ? passthru then drv.passthru else {};
      }
      //
      (drv.passthru or {})
      //
      (if (drv ? crossDrv && drv ? nativeDrv)
       then {
         crossDrv = overrideDerivation drv.crossDrv f;
         nativeDrv = overrideDerivation drv.nativeDrv f;
       }
       else { }));


  makeOverridable = f: origArgs:
    let
      ff = f origArgs;
      overrideWith = newArgs: origArgs // (if builtins.isFunction newArgs then newArgs origArgs else newArgs);
    in
      if builtins.isAttrs ff then (ff //
        { override = newArgs: makeOverridable f (overrideWith newArgs);
          overrideDerivation = fdrv:
            makeOverridable (args: overrideDerivation (f args) fdrv) origArgs;
        })
      else if builtins.isFunction ff then
        { override = newArgs: makeOverridable f (overrideWith newArgs);
          __functor = self: ff;
          overrideDerivation = throw "overrideDerivation not yet supported for functors";
        }
      else ff;


  /* Call the package function in the file `fn' with the required
    arguments automatically.  The function is called with the
    arguments `args', but any missing arguments are obtained from
    `autoArgs'.  This function is intended to be partially
    parameterised, e.g.,

      callPackage = callPackageWith pkgs;
      pkgs = {
        libfoo = callPackage ./foo.nix { };
        libbar = callPackage ./bar.nix { };
      };

    If the `libbar' function expects an argument named `libfoo', it is
    automatically passed as an argument.  Overrides or missing
    arguments can be supplied in `args', e.g.

      libbar = callPackage ./bar.nix {
        libfoo = null;
        enableX11 = true;
      };
  */
  callPackageWith = autoArgs: fn: args:
    let
      f = if builtins.isFunction fn then fn else import fn;
      auto = builtins.intersectAttrs (builtins.functionArgs f) autoArgs;
    in makeOverridable f (auto // args);


  /* Like callPackage, but for a function that returns an attribute
     set of derivations. The override function is added to the
     individual attributes. */
  callPackagesWith = autoArgs: fn: args:
    let
      f = if builtins.isFunction fn then fn else import fn;
      auto = builtins.intersectAttrs (builtins.functionArgs f) autoArgs;
      finalArgs = auto // args;
      pkgs = f finalArgs;
      mkAttrOverridable = name: pkg: pkg // {
        override = newArgs: mkAttrOverridable name (f (finalArgs // newArgs)).${name};
      };
    in lib.mapAttrs mkAttrOverridable pkgs;


  /* Add attributes to each output of a derivation without changing
     the derivation itself. */
  addPassthru = drv: passthru:
    let
      outputs = drv.outputs or [ "out" ];

      commonAttrs = drv // (builtins.listToAttrs outputsList) //
        ({ all = map (x: x.value) outputsList; }) // passthru;

      outputToAttrListElement = outputName:
        { name = outputName;
          value = commonAttrs // {
            inherit (drv.${outputName}) outPath drvPath type outputName;
          };
        };

      outputsList = map outputToAttrListElement outputs;
  in commonAttrs.${drv.outputName};


  /* Strip a derivation of all non-essential attributes, returning
     only those needed by hydra-eval-jobs. Also strictly evaluate the
     result to ensure that there are no thunks kept alive to prevent
     garbage collection. */
  hydraJob = drv:
    let
      outputs = drv.outputs or ["out"];

      commonAttrs =
        { inherit (drv) name system meta; inherit outputs; }
        // lib.optionalAttrs (drv._hydraAggregate or false) {
          _hydraAggregate = true;
          constituents = map hydraJob (lib.flatten drv.constituents);
        }
        // (lib.listToAttrs outputsList);

      makeOutput = outputName:
        let output = drv.${outputName}; in
        { name = outputName;
          value = commonAttrs // {
            outPath = output.outPath;
            drvPath = output.drvPath;
            type = "derivation";
            inherit outputName;
          };
        };

      outputsList = map makeOutput outputs;

      drv' = (lib.head outputsList).value;
    in lib.deepSeq drv' drv';

  /**
   * Implements a generic function for creating implmentation
   * specific configure flags (e.g. autotools, cmake, scons).
   * This also ensures that the entire flag is returned as a
   * single string.
   *
   * preFlag: Prepend to beginning of flag (e.g. --enable or -D)
   * flag: The name of the flag
   * postFlag: Append to end of flag
   * valueSep: The flag/value seperator, typically '='
   * value: A value (or string) to pass to the flag (e.g. --flag=val)
   *
   * Returns a configure flag string
   */
  genericFlag = preFlag: flag: postFlag: valueSep: value:
    let
      # Prevent coercing null to a string
      ifNotNull = x:
        if x != null then
          x
        else
          "";
      _preFlag = ifNotNull preFlag;
      _postFlag = ifNotNull postFlag;
      _valueSep = ifNotNull valueSep;
      _value = ifNotNull value;
    in
    assert flag == "" ->
      throw "genericFlag argument `flag` cannot be null";
    _preFlag + flag + _postFlag + _valueSep + _value;

  /**
   * Autoconf style generic configure flag function
   *
   * trueStr: Prepended when cond is true (string)
   * falseStr: Prepended when cond is false (string)
   * flag: The flag name (string)
   * boolean: The condition for the prepended string and value (boolean)
   *   - flag is not passed if null
   * value: The value of the flag is only appended when boolean is
   *        true (null/string)
   *
   * Returns an Autoconf formatted configure flag string
   */
  acFlag = trueStr: falseStr: flag: boolean: value:
    let
      # Prevent coercing null to a string
      ifNotNull = x:
        if x != null then
          x
        else
          "";
      preFlag =
        "--${
              if boolean == true then
                ifNotNull trueStr
              else
                ifNotNull falseStr
            }${
              # Allow autoconf flags without prepended true/false strings
              if (boolean && trueStr != null && trueStr != "")
                 || (!boolean && falseStr != null && falseStr != "") then
                "-"
              else
                ""
            }";
      valueSep =
        if boolean == true && value != null && value != "" then
          "="
        else
          null;
      _value =
        if boolean == true && value != null && value != "" then
          value
        else
          null;
    in
    if boolean == null then
      null
    else
      genericFlag preFlag flag null valueSep _value;

  /**
   * Autoconf style --enable/--disable configure flag
   *
   * flag: The name of the flag (string)
   * boolean: The condition for the prepended string and value (boolean)
   *   - flag is not passed if null
   * value: The value of the flag is only appended when boolean is
   *        true (null/string)
   *
   * Returns an Autoconf --enable/--disable formatted configure flag string
   */
  enFlag = flag: boolean: value:
    acFlag "enable" "disable" flag boolean value;

  /**
   * Autoconf style --with/--without configure flag
   *
   * flag: The name of the flag (string)
   * boolean: The condition for the prepended string and value (boolean/null)
   *   - flag is not passed if null
   * value: The value of the flag is only appended when boolean is
   *        true (null/string)
   *
   * Returns an Autoconf --with/--without formatted configure flag string
   */
  wtFlag = flag: boolean: value:
    acFlag "with" "without" flag boolean value;

  /* Make a set of packages with a common scope. All packages called
     with the provided `callPackage' will be evaluated with the same
     arguments. Any package in the set may depend on any other. The
     `override' function allows subsequent modification of the package
     set in a consistent way, i.e. all packages in the set will be
     called with the overridden packages. The package sets may be
     hierarchical: the packages in the set are called with the scope
     provided by `newScope' and the set provides a `newScope' attribute
     which can form the parent scope for later package sets. */
  makeScope = newScope: f:
    let self = f self // {
          newScope = scope: newScope (self // scope);
          callPackage = self.newScope {};
          override = g: makeScope newScope (self_:
            let super = f self_;
            in super // g super self_);
        };
    in self;

}
