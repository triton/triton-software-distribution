let lib = import ./default.nix;
    inherit (builtins) isFunction hasAttr getAttr head tail isList isAttrs attrNames;

in

with import ./lists.nix;
with import ./attrsets.nix;
with import ./strings.nix;

rec {


  # accumulates / merges all attr sets until null is fed.
  # example: sumArgs id { a = 'a'; x = 'x'; } { y = 'y'; x = 'X'; } null
  # result : { a = 'a'; x = 'X'; y = 'Y'; }
  innerSumArgs = f : x : y : (if y == null then (f x)
	else (innerSumArgs f (x // y)));
  sumArgs = f : innerSumArgs f {};

  # Advanced sumArgs version. Hm, twice as slow, I'm afraid.
  # composedArgs id (x:x//{a="b";}) (x:x//{b=x.a + "c";}) null;
  # {a="b" ; b="bc";};
  innerComposedArgs = f : x : y : (if y==null then (f x)
  	else (if (builtins.isAttrs y) then 
		(innerComposedArgs f (x//y))
	else (innerComposedArgs f (y x))));
  composedArgs = f: innerComposedArgs f {};

  defaultMergeArg = x : y: if builtins.isAttrs y then
    y
  else 
    (y x);
  defaultMerge = x: y: x // (defaultMergeArg x y);
  sumTwoArgs = f: x: y: 
    f (defaultMerge x y);
  foldArgs = merger: f: init: x: 
    let arg=(merger init (defaultMergeArg init x)); in  
      # now add the function with composed args already applied to the final attrs
    setAttrMerge "passthru" {} (f arg) ( x : x // { function = foldArgs merger f arg; } );

  # predecessors: proposed replacement for applyAndFun (which has a bug cause it merges twice)
  # the naming "overridableDelayableArgs" tries to express that you can
  # - override attr values which have been supplied earlier
  # - use attr values before they have been supplied by accessing the fix point
  #   name "fixed"
  # f: the (delayed overridden) arguments are applied to this
  #
  # initial: initial attrs arguments and settings. see defaultOverridableDelayableArgs
  #
  # returns: f applied to the arguments // special attributes attrs
  #     a) merge: merge applied args with new args. Wether an argument is overridden depends on the merge settings
  #     b) replace: this let's you replace and remove names no matter which merge function has been set
  #
  # examples: see test cases "res" below;
  overridableDelayableArgs =
          f :        # the function applied to the arguments
          initial :  # you pass attrs, the functions below are passing a function taking the fix argument
    let
        takeFixed = if (isFunction initial) then initial else (fixed : initial); # transform initial to an expression always taking the fixed argument
        tidy = args : 
            let # apply all functions given in "applyPreTidy" in sequence
                applyPreTidyFun = fold ( n : a : x : n ( a x ) ) lib.id (maybeAttr "applyPreTidy" [] args);
            in removeAttrs (applyPreTidyFun args) ( ["applyPreTidy"] ++ (maybeAttr  "removeAttrs" [] args) ); # tidy up args before applying them
        fun = n : x :
             let newArgs = fixed :
                     let args = takeFixed fixed; 
                         mergeFun = getAttr n args;
                     in if isAttrs x then (mergeFun args x)
                        else assert isFunction x;
                             mergeFun args (x ( args // { inherit fixed; }));
             in overridableDelayableArgs f newArgs;
    in
    (f (tidy (lib.fix takeFixed))) // {
      merge   = fun "mergeFun";
      replace = fun "keepFun";
    };
  defaultOverridableDelayableArgs = f : 
      let defaults = {
            mergeFun = mergeAttrByFunc; # default merge function. merge strategie (concatenate lists, strings) is given by mergeAttrBy
            keepFun = a : b : { inherit (a) removeAttrs mergeFun keepFun mergeAttrBy; } // b; # even when using replace preserve these values
            applyPreTidy = []; # list of functions applied to args before args are tidied up (usage case : prepareDerivationArgs)
            mergeAttrBy = mergeAttrBy // {
              applyPreTidy = a : b : a ++ b;
              removeAttrs = a : b: a ++ b;
            };
            removeAttrs = ["mergeFun" "keepFun" "mergeAttrBy" "removeAttrs" "fixed" ]; # before applying the arguments to the function make sure these names are gone
          };
      in (overridableDelayableArgs f defaults).merge;



  # rec { # an example of how composedArgsAndFun can be used
  #  a  = composedArgsAndFun (x : x) { a = ["2"]; meta = { d = "bar";}; };
  #  # meta.d will be lost ! It's your task to preserve it (eg using a merge function)
  #  b  = a.passthru.function { a = [ "3" ]; meta = { d2 = "bar2";}; };
  #  # instead of passing/ overriding values you can use a merge function:
  #  c  = b.passthru.function ( x: { a = x.a  ++ ["4"]; }); # consider using (maybeAttr "a" [] x)
  # }
  # result:
  # {
  #   a = { a = ["2"];     meta = { d = "bar"; }; passthru = { function = .. }; };
  #   b = { a = ["3"];     meta = { d2 = "bar2"; }; passthru = { function = .. }; };
  #   c = { a = ["3" "4"]; meta = { d2 = "bar2"; }; passthru = { function = .. }; };
  #   # c2 is equal to c
  # }
  composedArgsAndFun = f: foldArgs defaultMerge f {};

  # example a = pairMap (x : y : x + y) ["a" "b" "c" "d"];
  # result: ["ab" "cd"]
  innerPairMap = acc: f: l: 
  	if l == [] then acc else
	innerPairMap (acc ++ [(f (head l)(head (tail l)))])
		f (tail (tail l));
  pairMap = innerPairMap [];

  
  # shortcut for attrByPath ["name"] default attrs
  maybeAttr = name: default: attrs:
    if (__hasAttr name attrs) then (__getAttr name attrs) else default;


  # Return the second argument if the first one is true or the empty version
  # of the second argument.
  ifEnable = cond: val:
    if cond then val
    else if builtins.isList val then []
    else if builtins.isAttrs val then {}
    # else if builtins.isString val then ""
    else if (val == true || val == false) then false
    else null;

    
  # Return true only if there is an attribute and it is true.
  checkFlag = attrSet: name:
	if (name == "true") then true else
	if (name == "false") then false else
	if (elem name (attrByPath ["flags"] [] attrSet)) then true else
	attrByPath [name] false attrSet ;


  # Input : attrSet, [ [name default] ... ], name
  # Output : its value or default.
  getValue = attrSet: argList: name:
  ( attrByPath [name] (if checkFlag attrSet name then true else
	if argList == [] then null else
	let x = builtins.head argList; in
		if (head x) == name then 
			(head (tail x))
		else (getValue attrSet 
			(tail argList) name)) attrSet );

                        
  # Input : attrSet, [[name default] ...], [ [flagname reqs..] ... ]
  # Output : are reqs satisfied? It's asserted.
  checkReqs = attrSet : argList : condList :
  (
    fold lib.and true 
      (map (x: let name = (head x) ; in
	
	((checkFlag attrSet name) -> 
	(fold lib.and true
	(map (y: let val=(getValue attrSet argList y); in
		(val!=null) && (val!=false)) 
	(tail x))))) condList)) ;
	

  # !!! This function has O(n^2) performance, so you probably don't want to use it!
  uniqList = {inputList, outputList ? []}:
	if (inputList == []) then outputList else
	let x=head inputList; 
	newOutputList = outputList ++
	 (if elem x outputList then [] else [x]);
	in uniqList {outputList=newOutputList; 
		inputList = (tail inputList);};

  uniqListExt = {inputList, outputList ? [],
    getter ? (x : x), compare ? (x: y: x==y)}:
	if (inputList == []) then outputList else
	let x=head inputList; 
	isX = y: (compare (getter y) (getter x));
	newOutputList = outputList ++
	 (if any isX outputList then [] else [x]);
	in uniqListExt {outputList=newOutputList; 
		inputList = (tail inputList);
		inherit getter compare;
		};


                
  condConcat = name: list: checker:
	if list == [] then name else
	if checker (head list) then 
		condConcat 
			(name + (head (tail list))) 
			(tail (tail list)) 
			checker
	else condConcat
		name (tail (tail list)) checker;

  # Merge sets of attributes and use the function f to merge
  # attributes values.
  zip = f: sets:
    zipWithNames (concatMap builtins.attrNames sets) f sets;

  zipWithNames = names: f: sets:
    builtins.listToAttrs (map (name: {
      inherit name;
      value =
        f name
          (map (__getAttr name)
            (filter (__hasAttr name) sets));
    }) names);

  lazyGenericClosure = {startSet, operator}:
    let
      work = list: doneKeys: result:
        if list == [] then
          result
        else
          let x = head list; key = x.key; in
          if elem key doneKeys then
            work (tail list) doneKeys result
          else
            work (tail list ++ operator x) ([key] ++ doneKeys) ([x] ++ result);
    in
      work startSet [] [];

  genericClosure =
    if builtins ? genericClosure then builtins.genericClosure
    else lazyGenericClosure;

  innerModifySumArgs = f: x: a: b: if b == null then (f a b) // x else 
	innerModifySumArgs f x (a // b);
  modifySumArgs = f: x: innerModifySumArgs f x {};


  innerClosePropagation = ready: list: if list == [] then ready else
    if (head list) ? propagatedBuildInputs then 
      innerClosePropagation (ready ++ [(head list)]) 
        ((head list).propagatedBuildInputs ++ (tail list)) else
      innerClosePropagation (ready ++ [(head list)]) (tail list);

  closePropagation = list: (uniqList {inputList = (innerClosePropagation [] list);});

  # calls a function (f attr value ) for each record item. returns a list
  mapAttrsFlatten = f : r : map (attr: f attr (builtins.getAttr attr r) ) (attrNames r);
  mapRecordFlatten = builtins.trace "deprecated usage of mapRecordFlatten, use mapAttrsFlatten instead" mapAttrsFlatten;

  # attribute set containing one attribute
  nvs = name : value : listToAttrs [ (nameValuePair name value) ];
  # adds / replaces an attribute of an attribute set
  setAttr = set : name : v : set // (nvs name v);

  # setAttrMerge (similar to mergeAttrsWithFunc but only merges the values of a particular name)
  # setAttrMerge "a" [] { a = [2];} (x : x ++ [3]) -> { a = [2 3]; } 
  # setAttrMerge "a" [] {         } (x : x ++ [3]) -> { a = [  3]; }
  setAttrMerge = name : default : attrs : f :
    setAttr attrs name (f (maybeAttr name default attrs));

  # Using f = a : b = b the result is similar to //
  # merge attributes with custom function handling the case that the attribute
  # exists in both sets
  mergeAttrsWithFunc = f : set1 : set2 :
    fold (n: set : if (__hasAttr n set) 
                        then setAttr set n (f (__getAttr n set) (__getAttr n set2))
                        else set )
           (set2 // set1) (__attrNames set2);

  # merging two attribute set concatenating the values of same attribute names
  # eg { a = 7; } {  a = [ 2 3 ]; } becomes { a = [ 7 2 3 ]; }
  mergeAttrsConcatenateValues = mergeAttrsWithFunc ( a : b : (toList a) ++ (toList b) );

  # merges attributes using //, if a name exisits in both attributes
  # an error will be triggered unless its listed in mergeLists
  # so you can mergeAttrsNoOverride { buildInputs = [a]; } { buildInputs = [a]; } {} to get
  # { buildInputs = [a b]; }
  # merging buildPhase does'nt really make sense. The cases will be rare where appending /prefixing will fit your needs?
  # in these cases the first buildPhase will override the second one
  # ! deprecated, use mergeAttrByFunc instead
  mergeAttrsNoOverride = { mergeLists ? ["buildInputs" "propagatedBuildInputs"],
                           overrideSnd ? [ "buildPhase" ]
                         } : attrs1 : attrs2 :
    fold (n: set : 
        setAttr set n ( if (__hasAttr n set) 
            then # merge 
              if elem n mergeLists # attribute contains list, merge them by concatenating
                then (__getAttr n attrs2) ++ (__getAttr n attrs1)
              else if elem n overrideSnd
                then __getAttr n attrs1
              else throw "error mergeAttrsNoOverride, attribute ${n} given in both attributes - no merge func defined"
            else __getAttr n attrs2 # add attribute not existing in attr1
           )) attrs1 (__attrNames attrs2);


  # example usage:
  # mergeAttrByFunc  {
  #   inherit mergeAttrBy; # defined below
  #   buildInputs = [ a b ];
  # } {
  #  buildInputs = [ c d ];
  # };
  # will result in
  # { mergeAttrsBy = [...]; buildInputs = [ a b c d ]; }
  # is used by prepareDerivationArgs, defaultOverridableDelayableArgs and can be used when composing using
  # foldArgs, composedArgsAndFun or applyAndFun. Example: composableDerivation in all-packages.nix
  mergeAttrByFunc = x : y :
    let
          mergeAttrBy2 = { mergeAttrBy=lib.mergeAttrs; }
                      // (maybeAttr "mergeAttrBy" {} x)
                      // (maybeAttr "mergeAttrBy" {} y); in
    fold lib.mergeAttrs {} [
      x y
      (mapAttrs ( a : v : # merge special names using given functions
          if (hasAttr a x)
             then if (hasAttr a y)
               then v (getAttr a x) (getAttr a y) # both have attr, use merge func
               else (getAttr a x) # only x has attr
             else (getAttr a y) # only y has attr)
          ) (removeAttrs mergeAttrBy2
                         # don't merge attrs which are neither in x nor y
                         (filter (a : (! hasAttr a x) && (! hasAttr a y) )
                                 (attrNames mergeAttrBy2))
            )
      )
    ];
  mergeAttrsByFuncDefaults = foldl mergeAttrByFunc { inherit mergeAttrBy; };
  # sane defaults (same name as attr name so that inherit can be used)
  mergeAttrBy = # { buildInputs = concatList; [...]; passthru = mergeAttr; [..]; }
    listToAttrs (map (n : nameValuePair n lib.concat) [ "buildInputs" "propagatedBuildInputs" "configureFlags" "prePhases" "postAll" ])
    // listToAttrs (map (n : nameValuePair n lib.mergeAttrs) [ "passthru" "meta" "cfg" "flags" ])
    // listToAttrs (map (n : nameValuePair n (a: b: "${a}\n${b}") ) [ "preConfigure" ])
  ;

  # returns atribute values as a list 
  flattenAttrs = set : map ( attr : builtins.getAttr attr set) (attrNames set);
  mapIf = cond : f :  fold ( x : l : if (cond x) then [(f x)] ++ l else l) [];

  # pick attrs subset_attr_names and apply f 
  subsetmap = f : attrs : subset_attr_names : 
    listToAttrs (fold ( attr : r : if hasAttr attr attrs
          then r ++ [ ( nameValuePair attr ( f (getAttr attr attrs) ) ) ] else r ) []
      subset_attr_names );

  # prepareDerivationArgs tries to make writing configurable derivations easier
  # example:
  #  prepareDerivationArgs {
  #    mergeAttrBy = {
  #       myScript = x : y : x ++ "\n" ++ y;
  #    };
  #    cfg = {
  #      readlineSupport = true;
  #    };
  #    flags = {
  #      readline = {
  #        set = {
  #           configureFlags = [ "--with-compiler=${compiler}" ];
  #           buildInputs = [ compiler ];
  #           pass = { inherit compiler; READLINE=1; };
  #           assertion = compiler.dllSupport;
  #           myScript = "foo";
  #        };
  #        unset = { configureFlags = ["--without-compiler"]; };
  #      };
  #    };
  #    src = ...
  #    buildPhase = '' ... '';
  #    name = ...
  #    myScript = "bar";
  #  };
  # if you don't have need for unset you can omit the surrounding set = { .. } attr
  # all attrs except flags cfg and mergeAttrBy will be merged with the
  # additional data from flags depending on config settings
  # It's used in composableDerivation in all-packages.nix. It's also used
  # heavily in the new python and libs implementation
  #
  # should we check for misspelled cfg options?
  # TODO use args.mergeFun here as well?
  prepareDerivationArgs = args:
    let args2 = { cfg = {}; flags = {}; } // args;
        flagName = name : "${name}Support";
        cfgWithDefaults = (listToAttrs (map (n : nameValuePair (flagName n) false) (attrNames args2.flags)))
                          // args2.cfg;
        opts = flattenAttrs (mapAttrs (a : v :
                let v2 = if (v ? set || v ? unset) then v else { set = v; };
                    n = if (getAttr (flagName a) cfgWithDefaults) then "set" else "unset";
                    attr = maybeAttr n {} v2; in
                if (maybeAttr "assertion" true attr)
                  then attr
                  else throw "assertion of flag ${a} of derivation ${args.name} failed"
               ) args2.flags );
    in removeAttrs
      (mergeAttrsByFuncDefaults ([args] ++ opts ++ [{ passthru = cfgWithDefaults; }]))
      ["flags" "cfg" "mergeAttrBy" ];


  # deep, strict equality testing. This should be implemented as primop
  eqStrict = a : b :
    let eqListStrict = a : b :
      if (a == []) != (b == []) then false
      else if a == [] then true
      else eqStrict (head a) (head b) && eqListStrict (tail a) (tail b);
    in
    if isList a && isList b then eqListStrict a b
    else if isAttrs a && isAttrs b then
      (eqListStrict (attrNames a) (attrNames b))
      && (eqListStrict (lib.attrValues a) (lib.attrValues b))
    else a == b; # FIXME !
}
