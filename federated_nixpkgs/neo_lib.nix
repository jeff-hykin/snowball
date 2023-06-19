# no "with" allowed
# no " or " allowed
let 
    zipListsWith' = fst: snd: null
in
    10
# intentionally missing:
    # lib.release = lib.strings.fileContents ../.version;
    # lib.version = release + versionSuffix;
    # lib.oldestSupportedRelease = 2211;
    # lib.versionSuffix =
    #     let suffixFile = ../.version-suffix;
    #     in if pathExists suffixFile
    #     then lib.strings.fileContents suffixFile
    #     else "pre-git";
    # lib.codeName = "Tapir";
    # lib.revisionWithDefault = default:
    #     let
    #         revisionFile = "${toString ./..}/.git-revision";
    #         gitRepo      = "${toString ./..}/.git";
    #     in if lib.pathIsGitRepo gitRepo
    #         then lib.commitIdFromGitRepo gitRepo
    #         else if lib.pathExists revisionFile then lib.fileContents revisionFile
    #         else default;
    # lib.inNixShell = builtins.getEnv "IN_NIX_SHELL" != "";
    # lib.inPureEvalMode = ! builtins ? currentSystem;
    # lib.isInOldestRelease =
    #     release:
    #         release <= lib.trivial.oldestSupportedRelease;
    # lib.string.replaceChars = lib.warn "replaceChars is a deprecated alias of builtins.replaceStrings, replace usages of it with builtins.replaceStrings." builtins.replaceStrings;
    

let
    # 
    # lib/minver.nix
    # 
    _-minver = "2.3";
    
    # 
    # lib/ascii-table.nix
    # 
    _-asciiTable = {
        "\t" =  9;
        "\n" = 10;
        "\r" = 13;
        " "  = 32;
        "!"  = 33;
        "\"" = 34;
        "#"  = 35;
        "$"  = 36;
        "%"  = 37;
        "&"  = 38;
        "'"  = 39;
        "("  = 40;
        ")"  = 41;
        "*"  = 42;
        "+"  = 43;
        ","  = 44;
        "-"  = 45;
        "."  = 46;
        "/"  = 47;
        "0"  = 48;
        "1"  = 49;
        "2"  = 50;
        "3"  = 51;
        "4"  = 52;
        "5"  = 53;
        "6"  = 54;
        "7"  = 55;
        "8"  = 56;
        "9"  = 57;
        ":"  = 58;
        ";"  = 59;
        "<"  = 60;
        "="  = 61;
        ">"  = 62;
        "?"  = 63;
        "@"  = 64;
        "A"  = 65;
        "B"  = 66;
        "C"  = 67;
        "D"  = 68;
        "E"  = 69;
        "F"  = 70;
        "G"  = 71;
        "H"  = 72;
        "I"  = 73;
        "J"  = 74;
        "K"  = 75;
        "L"  = 76;
        "M"  = 77;
        "N"  = 78;
        "O"  = 79;
        "P"  = 80;
        "Q"  = 81;
        "R"  = 82;
        "S"  = 83;
        "T"  = 84;
        "U"  = 85;
        "V"  = 86;
        "W"  = 87;
        "X"  = 88;
        "Y"  = 89;
        "Z"  = 90;
        "["  = 91;
        "\\" = 92;
        "]"  = 93;
        "^"  = 94;
        "_"  = 95;
        "`"  = 96;
        "a"  = 97;
        "b"  = 98;
        "c"  = 99;
        "d"  = 100;
        "e"  = 101;
        "f"  = 102;
        "g"  = 103;
        "h"  = 104;
        "i"  = 105;
        "j"  = 106;
        "k"  = 107;
        "l"  = 108;
        "m"  = 109;
        "n"  = 110;
        "o"  = 111;
        "p"  = 112;
        "q"  = 113;
        "r"  = 114;
        "s"  = 115;
        "t"  = 116;
        "u"  = 117;
        "v"  = 118;
        "w"  = 119;
        "x"  = 120;
        "y"  = 121;
        "z"  = 122;
        "{"  = 123;
        "|"  = 124;
        "}"  = 125;
        "~"  = 126;
    };
    
    # 
    # lib/zip-int-bits.nix
    # 
    # Helper function to implement a fallback for the bit operators
    # `bitAnd`, `bitOr` and `bitXor` on older nix version.
    #*# ASSERT
    _-zipIntBits = (
        f: x: y:
            let
                # (intToBits 6) -> [ 0 1 1 ]
                intToBits = x:
                    if x == 0 || x == -1 then
                        []
                    else
                        let
                            headbit  = if (x / 2) * 2 != x then 1 else 0;          # x & 1
                            tailbits = if x < 0 then ((x + 1) / 2) - 1 else x / 2; # x >> 1
                        in
                            [headbit] ++ (intToBits tailbits);

                # (bitsToInt [ 0 1 1 ] 0) -> 6
                # (bitsToInt [ 0 1 0 ] 1) -> -6
                bitsToInt = l: signum:
                    if l == [] then
                        (if signum == 0 then 0 else -1)
                    else
                        (builtins.head l) + (2 * (bitsToInt (builtins.tail l) signum));

                xsignum = if x < 0 then 1 else 0;
                ysignum = if y < 0 then 1 else 0;
                zipListsWith' = fst: snd:
                    if fst==[] && snd==[] then
                        []
                    else if fst==[] then
                        [(f xsignum             (builtins.head snd))] ++ (zipListsWith' []                  (builtins.tail snd))
                    else if snd==[] then
                        [(f (builtins.head fst) ysignum            )] ++ (zipListsWith' (builtins.tail fst) []                 )
                    else
                        [(f (builtins.head fst) (builtins.head snd))] ++ (zipListsWith' (builtins.tail fst) (builtins.tail snd));
            in
                assert (builtins.isInt x) && (builtins.isInt y);
                bitsToInt (zipListsWith' (intToBits x) (intToBits y)) (f xsignum ysignum)
    );
    
    # 
    # will end up as part of attrsets
    # 
        _-getOutput = (
            output: pkg:
                if ! pkg ? outputSpecified || ! pkg.outputSpecified
                then
                    if builtins.hasAttr output pkg
                    then
                        pkg."${output}"
                    else if pkg ? out
                    then
                        pkg.out
                    else
                        pkg
                else
                    pkg
        );
        _-mapAttrsToList = (
            # A function, given an attribute's name and value, returns a new value.
            f:
            # Attribute set to map over.
            attrs:
                (builtins.map
                    (name: f name attrs."${name}")
                    (builtins.attrNames attrs)
                )
        );
    
    # 
    # will end up as part of asserts
    # 
        #*# THROW
        _'assertMsg = (
            # Predicate that needs to succeed, otherwise `msg` is thrown
            pred:
            # Message to throw in case `pred` fails
            msg:
                pred || builtins.throw msg
        );
    
    # 
    # will end up as part of lists
    # 
        _-imap1 = f: list: builtins.genList (n: f (n + 1) (builtins.elemAt list n)) (builtins.length list);
        _-subtractLists = e: builtins.filter (x: !(builtins.elem x e));
        _-foldr = op: nul: list:
            let
                len = builtins.length list;
                fold' = n:
                    if n == len
                    then nul
                    else op (builtins.elemAt list n) (fold' (n + 1));
            in
                fold' 0;
        _-all = if builtins ? all then builtins.all else (pred: _-foldr (x: y: if pred x then y else false) true);
        _-any = if builtins ? any then builtins.any else (pred: _-foldr (x: y: if pred x then true else y) false);
        _-reverseList = (
            xs:
                let
                    l = builtins.length xs;
                in
                    builtins.genList (n: builtins.elemAt xs (l - n - 1)) l
        );
        _-concatMap = if builtins ? concatMap then builtins.concatMap else (f: list: builtins.concatLists (builtins.map f list));
        _-range = (
            # First integer in the range
            first:
            # Last integer in the range
            last:
                if first > last then
                    []
                else
                    (builtins.genList
                        (n: first + n)
                        (last - first + 1)
                    )
        );
        #*# THROW, ASSERT
        _'last = (
            list:
                assert _'assertMsg (list != []) "lists.last: list must not be empty!";
                builtins.elemAt list (builtins.length list - 1)
        );
    
    
    # 
    # will end up as part of strings
    # 
        _-intersperse = (
            # Separator to add between elements
            separator:
            # Input list
            list:
                if list == [] || builtins.length list == 1
                then list
                else builtins.tail (_-concatMap (x: [separator x]) list)
        );
        _-concatStringsSep = (
            if builtins ? concatStringsSep
            then
                builtins.concatStringsSep
            else
                (separator: list:
                    builtins.foldl' (x: y: x + y) "" (_-intersperse separator list)
                )
        );
        _-concatStrings = _-concatStringsSep "";
        _-concatMapStrings = f: list: _-concatStrings (builtins.map f list);
        _-concatMapStringsSep = (
            # Separator to add between elements
            sep:
            # Function to map over the list
            f:
            # List of input strings
            list: 
                _-concatStringsSep sep (builtins.map f list)
        );
    
        _-makeSearchPath = (
            # Directory name to append
            subDir:
            # List of base paths
            paths:
                (_-concatStringsSep
                    ":"
                    (builtins.map
                        (path: path + "/" + subDir)
                        (builtins.filter
                            (x: x != null)
                            paths
                        )
                    )
                )
        );
        _-makeSearchPathOutput = (
            # Package output to use
            output:
            # Directory name to append
            subDir:
            # List of packages
            pkgs: _-makeSearchPath subDir (builtins.map (_-getOutput output) pkgs)
        );
        
        _-optionalString = (
            # Condition
            cond:
            # String to return if condition is true
            string:
                if cond then string else ""
        );
        
        _-stringToCharacters = (
            s:
                (builtins.map
                    (p: builtins.substring p 1 s)
                    (_-range
                        0
                        (builtins.stringLength (s - 1))
                    )
                )
        );
        _-charToInt = c: builtins.getAttr c _-asciiTable;
        _-escape = (
            list:
                (builtins.replaceStrings
                    list
                    (builtins.map
                        (c: "\\${c}")
                        list
                    )
                )
        );
        _-escapeRegex = _-escape (_-stringToCharacters "\\[{()^$?*+|.");
        _-lowerChars = _-stringToCharacters "abcdefghijklmnopqrstuvwxyz";
        _-upperChars = _-stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        _-toLower = builtins.replaceStrings _-upperChars _-lowerChars;
        _-toUpper = builtins.replaceStrings _-lowerChars _-upperChars;
        #*# ASSERT, THROW
        _'fixedWidthString = (
            width: filler: str:
                let
                    strw = builtins.stringLength str;
                    reqWidth = width - (builtins.stringLength filler);
                in
                    assert _'assertMsg (strw <= width) "fixedWidthString: requested string length (${builtins.toString width}) must not be shorter than actual length (${builtins.toString strw})";
                    if strw == width
                    then
                        str
                    else
                        filler + _'fixedWidthString reqWidth filler str
        );
        _-escapeShellArg = arg: "'${builtins.replaceStrings ["'"] ["'\\''"] (builtins.toString arg)}'";
        _-escapeShellArgs = _-concatMapStringsSep " " _-escapeShellArg;
        
        _-isValidPosixName = name: (builtins.match "[a-zA-Z_][a-zA-Z0-9_]*" name) != null;
        
        #*# THROW
        _'toShellVar = (
            name: value:
                (_'throwIfNot
                    (_-isValidPosixName name)
                    "toShellVar: ${name} is not a valid shell variable name" 
                    (
                        if builtins.isAttrs value && ! _-isStringLike value
                        then
                            let
                                newValue = (_-concatStringsSep
                                    " " 
                                    (_-mapAttrsToList
                                        (n: v:
                                            "[${_-escapeShellArg n}]=${_-escapeShellArg v}"
                                        )
                                        value
                                    )
                                );
                            in
                                "declare -A ${name}=(${newValue})"
                        else if builtins.isList value then
                            "declare -a ${name}=(${_-escapeShellArgs value})"
                        else
                            "${name}=${_-escapeShellArg value}"
                    )
                )
        );
        _-escapeNixString = s: _-escape ["$"] (builtins.toJSON s);
        _-addContextFrom = a: b: builtins.substring 0 0 a + b;
        _-splitString = (
            sep: s:
                let
                    splits = (builtins.filter
                        builtins.isString
                        (builtins.split
                            (_-escapeRegex (builtins.toString sep))
                            (builtins.toString s)
                        )
                    );
                in
                    builtins.map (_-addContextFrom s) splits
        );
        _-versionOlder = v1: v2: builtins.compareVersions v2 v1 == 1;
        _-mesonOption = ( 
            feature: value:
                assert (builtins.isString feature);
                assert (builtins.isString value);
                "-D${feature}=${value}"
        );
        _-enableFeature = (
            enable: feat:
                assert builtins.isString feat; # e.g. passing openssl instead of "openssl"
                "--${if enable then "enable" else "disable"}-${feat}"
        );
        _-withFeature = (
            with_: feat:
                assert builtins.isString feat; # e.g. passing openssl instead of "openssl"
                "--${if with_ then "with" else "without"}-${feat}"
        );
            
        _-isStringLike = (
            x:
                builtins.isString x ||
                builtins.isPath x ||
                x ? outPath ||
                x ? __toString
        );
        
        _-isConvertibleWithToString = x:
            _-isStringLike x ||
            builtins.elem (builtins.typeOf x) [ "null" "int" "float" "bool" ] ||
            (builtins.isList x && _-all _-isConvertibleWithToString x)
    # 
    # will end up as part of trivial
    # 
        #*# DIRTY env, ABORT, DIRTY trace
        _'warn = (
            if builtins.elem (builtins.getEnv "NIX_ABORT_ON_WARN") ["1" "true" "yes"]
            then msg: builtins.trace "[1;31mwarning: ${msg}[0m" (builtins.abort "NIX_ABORT_ON_WARN=true; warnings are treated as unrecoverable errors.")
            else msg: builtins.trace "[1;31mwarning: ${msg}[0m";
        );
        #*# DIRTY env, ABORT, DIRTY trace
        _'warnIf = cond: msg: if cond then _'warn msg else x: x;
        
        #*# THROW
        _'throwIfNot = cond: msg: if cond then x: x else builtins.throw msg;
        
        _-functionArgs = (
            f:
                if f ? __functor
                then
                    if f ? __functionArgs
                    then
                        f.__functionArgs
                    else
                        # recursion
                        (_-functionArgs (f.__functor f))
                else
                    builtins.functionArgs f
        );
        
        _-isFunction = f: builtins.isFunction f || (f ? __functor && _-isFunction (f.__functor f));
        
        _-pipe = (
            val: functions:
                let
                    reverseApply = x: f: f x;
                in
                    builtins.foldl' reverseApply val functions
        );
        
        _-max = x: y: if x > y then x else y;
        _-min = x: y: if x < y then x else y;
        
        _-boolToString = b: if b then "true" else "false";
        
        #*# ASSERT
        _'toBaseDigits = (
            base: i:
                let
                    go = i:
                        if i < base
                        then [i]
                        else
                            let
                                r = i - ((i / base) * base);
                                q = (i - r) / base;
                            in
                                [r] ++ go q;
                in
                    assert (builtins.isInt base);
                    assert (builtins.isInt i);
                    assert (base >= 2);
                    assert (i >= 0);
                    _-reverseList (go i)
        );
        #*# ASSERT
        _'toHexString = (
            i:
                let
                    toHexDigit = d:
                        if d < 10
                        then builtins.toString d
                        else
                            {
                                "10" = "A";
                                "11" = "B";
                                "12" = "C";
                                "13" = "D";
                                "14" = "E";
                                "15" = "F";
                            }."${builtins.toString d}";
                in
                    _-concatMapStrings toHexDigit (_'toBaseDigits 16 i)
        );
        
    
    # 
    # will be part of string
    # 
        #*# DIRTY env, ABORT, DIRTY trace
        _'hasSuffix = (
            # Suffix to check for
            suffix:
            # Input string
            content:
                let
                    lenContent = builtins.stringLength content;
                    lenSuffix = builtins.stringLength suffix;
                in
                    # Before 23.05, paths would be copied to the store before converting them
                    # to strings and comparing. This was surprising and confusing.
                    (_'warnIf
                        (builtins.isPath suffix)
                        ''
                            lib.strings.hasSuffix: The first argument (${builtins.toString suffix}) is a path value, but only strings are supported.
                                There is almost certainly a bug in the calling code, since this function always returns `false` in such a case.
                                This function also copies the path to the Nix store, which may not be what you want.
                                This behavior is deprecated and will throw an error in the future.
                        ''
                        (
                            lenContent >= lenSuffix
                            && (builtins.substring
                                    (lenContent - lenSuffix)
                                    lenContent
                                    (content == suffix)
                                )
                        )
                    )
        );
        
        #*# DIRTY env, ABORT, DIRTY trace
        _'hasPrefix = (
            # Prefix to check for
            pref:
            # Input string
            str:
                # Before 23.05, paths would be copied to the store before converting them
                # to strings and comparing. This was surprising and confusing.
                (_'warnIf
                    (builtins.isPath pref)
                    ''
                        lib.strings.hasPrefix: The first argument (${builtins.toString pref}) is a path value, but only strings are supported.
                            There is almost certainly a bug in the calling code, since this function always returns `false` in such a case.
                            This function also copies the path to the Nix store, which may not be what you want.
                            This behavior is deprecated and will throw an error in the future.
                    ''
                    (builtins.substring 0 (builtins.stringLength pref) str == pref)
                )
        );
        
        _'removeSuffix =  (
            # Suffix to remove if it matches
            suffix:
            # Input string
            str:
                # Before 23.05, paths would be copied to the store before converting them
                # to strings and comparing. This was surprising and confusing.
                (_'warnIf
                    (builtins.isPath suffix)
                    ''
                        lib.strings.removeSuffix: The first argument (${builtins.toString suffix}) is a path value, but only strings are supported.
                            There is almost certainly a bug in the calling code, since this function never removes any suffix in such a case.
                            This function also copies the path to the Nix store, which may not be what you want.
                            This behavior is deprecated and will throw an error in the future.
                    ''
                    (
                        let
                            sufLen = builtins.stringLength suffix;
                            sLen = builtins.stringLength str;
                        in
                            if sufLen <= sLen && suffix == (builtins.substring (sLen - sufLen) sufLen str)
                            then
                                builtins.substring 0 (sLen - sufLen) str
                            else
                                str
                    )
                )
        );
        
        _-commonPrefixLength = (
            a: b:
                let
                    m = _-min (builtins.stringLength a) (builtins.stringLength b);
                    go = (
                        i:
                            if i >= m then
                                m
                            else if builtins.substring i 1 a == builtins.substring i 1 b
                            then
                                go (i + 1)
                            else
                                i
                    );
                in
                    go 0
        );
        
        _-commonSuffixLength = (
            a: b:
                let
                    m = _-min (builtins.stringLength a) (builtins.stringLength b);
                    go = (
                        i:
                            if i >= m
                            then
                                m
                            else if builtins.substring (builtins.stringLength a - i - 1) 1 a == builtins.substring (builtins.stringLength b - i - 1) 1 b
                            then
                                go (i + 1)
                            else
                                i
                    );
                in
                    go 0
        );
        
        _-levenshtein = (
            a: b:
                let
                    # Two dimensional array with dimensions (builtins.stringLength a + 1, builtins.stringLength b + 1)
                    arr = (builtins.genList
                        (i:
                            (builtins.genList
                                (j:
                                    dist i j
                                )
                                (builtins.stringLength b + 1)
                            )
                        )
                        (builtins.stringLength a + 1)
                    );
                    d = x: y: builtins.elemAt (builtins.elemAt arr x) y;
                    dist = i: j:
                        let
                            c = (
                                if builtins.substring (i - 1) 1 a == builtins.substring (j - 1) 1 b
                                then
                                    0
                                else
                                    1
                            );
                        in
                            if j == 0 then
                                i
                            else if i == 0 then
                                j
                            else
                                (_-min
                                    (_-min
                                        (d
                                            (i - 1)
                                            (j + 1)
                                        )
                                        (d
                                            i
                                            ((j - 1) + 1)
                                        )
                                    )
                                    (d
                                        (i - 1)
                                        ((j - 1) + c)
                                    )
                                );
                in
                    (d
                        (builtins.stringLength a)
                        (builtins.stringLength b)
                    )
        );
        
    
    # 
    # lib/trivial.nix
    # 
    _-trivial = {
        isBool         = builtins.isBool;
        isInt          = builtins.isInt;
        isFloat        = builtins.isFloat;
        add            = builtins.add;
        sub            = builtins.sub;
        lessThan       = builtins.lessThan;
        seq            = builtins.seq;
        deepSeq        = builtins.deepSeq;
        genericClosure = builtins.genericClosure;
        
        id = x: x;
        
        const = x: y: x;
        
        pipe = _-pipe;
        
        concat = x: y: x ++ y;

        or = x: y: x || y;

        and = x: y: x && y;
        
        #*# ASSERT
        bitAnd = (
            if builtins.hasAttr "bitAnd" builtins
            then
                builtins.bitAnd
            else 
                (_-zipIntBits
                    (a: b: if a==1 && b==1 then 1 else 0)
                )
        );

        #*# ASSERT
        bitOr = (
            if builtins.hasAttr "bitOr" builtins
            then
                builtins.bitOr
            else 
                (_-zipIntBits
                    (a: b: if a==1 || b==1 then 1 else 0)
                )
        );

        #*# ASSERT
        bitXor = (
            if builtins.hasAttr "bitXor" builtins
            then
                builtins.bitXor
            else 
                (_-zipIntBits
                    (a: b: if a!=b then 1 else 0)
                )
        );

        bitNot = builtins.sub (-1);
        
        boolToString = _-boolToString;
        
        mergeAttrs = x: y: x // y;
        
        flip = f: a: b: f b a;
        
        mapNullable = f: a: if a == null then a else f a;
        
        min = _-min;
  
        max = _-max;
            
        mod = base: int: base - (int * (builtins.div base int));
        
        compare = (
            a: b:
                if a < b
                then -1
                else if a > b
                    then 1
                    else 0
        );

        splitByAndCompare =
            # Predicate
            p:
            # Comparison function if predicate holds for both values
            yes:
            # Comparison function if predicate holds for neither value
            no:
            # First value to compare
            a:
            # Second value to compare
            b:
                if p a
                then if p b then yes a b else -1
                else if p b then 1 else no a b;
        
        #*# DIRTY read
        pathExists     = builtins.pathExists;
        #*# DIRTY read
        readFile       = builtins.readFile;
        #*# DIRTY read
        importJSON = path:
            builtins.fromJSON (builtins.readFile path);
        #*# DIRTY read
        importTOML = path:
            builtins.fromTOML (builtins.readFile path);
        #*# DIRTY env, ABORT, DIRTY trace
        warn = _'warn;
        #*# DIRTY env, ABORT, DIRTY trace
        warnIf = _'warnIf;
        #*# DIRTY env, ABORT, DIRTY trace
        warnIfNot = cond: msg: if cond then x: x else _'warn msg;
        
        #*# THROW
        throwIfNot = _'throwIfNot;
        #*# THROW
        throwIf = cond: msg: if cond then builtins.throw msg else x: x;
        
        #*# THROW
        checkListOfEnum = (
            msg: valid: given:
                let
                    unexpected = _-subtractLists valid given;
                in
                    _'throwIfNot (unexpected == [])
                        "${msg}: ${_-concatStringsSep ", " (builtins.map builtins.toString unexpected)} unexpected; valid ones: ${_-concatStringsSep ", " (builtins.map builtins.toString valid)}"
        );
        
        #*# DIRTY trace
        info = msg: builtins.trace "INFO: ${msg}";
        
        #*# DIRTY env, ABORT, DIRTY trace
        showWarnings = warnings: res: _-foldr (w: x: _'warn w x) res warnings;
        
        setFunctionArgs = (
            f: args:
                {
                    __functor = self: f;
                    __functionArgs = args;
                }
        );
        
        functionArgs = _-functionArgs;
        
        isFunction = _-isFunction;
        
        toFunction = (
            # Any value
            v:
                if _-isFunction v
                then
                    v
                else
                    k: v
        );
        
        #*# ASSERT
        toBaseDigits = _'toBaseDigits;
        
        #*# ASSERT
        toHexString = _'toHexString;
    };
    
    _-string = {
        compareVersions            = builtins.compareVersions;
        elem                       = builtins.elem;
        elemAt                     = builtins.elemAt;
        filter                     = builtins.filter;
        head                       = builtins.head;
        isInt                      = builtins.isInt;
        isList                     = builtins.isList;
        isAttrs                    = builtins.isAttrs;
        isPath                     = builtins.isPath;
        isString                   = builtins.isString;
        match                      = builtins.match;
        parseDrvName               = builtins.parseDrvName;
        replaceStrings             = builtins.replaceStrings;
        split                      = builtins.split;
        storeDir                   = builtins.storeDir;
        stringLength               = builtins.stringLength;
        substring                  = builtins.substring;
        tail                       = builtins.tail;
        toJSON                     = builtins.toJSON;
        typeOf                     = builtins.typeOf;
        unsafeDiscardStringContext = builtins.unsafeDiscardStringContext;
        #*# DIRTY read
        fromJSON                   = builtins.fromJSON;
        #*# DIRTY read
        readFile                   = builtins.readFile;
        
        
        concatStrings = _-concatStrings;
        concatMapStrings = _-concatMapStrings;
        concatImapStrings = f: list: _-concatStrings (_-imap1 f list);
        intersperse = _-intersperse;
        concatStringsSep = _-concatStringsSep;
        concatMapStringsSep = _-concatMapStringsSep;
        concatImapStringsSep = (
            # Separator to add between elements
            sep:
            # Function that receives elements and their positions
            f:
            # List of input strings
            list: _-concatStringsSep sep (_-imap1 f list)
        );
        
        concatLines = _-concatMapStrings (s: s + "\n");
        
        makeSearchPath       = _-makeSearchPath;
        makeSearchPathOutput = _-makeSearchPathOutput;
        makeLibraryPath      = _-makeSearchPathOutput "lib" "lib";
        makeBinPath          = _-makeSearchPathOutput "bin" "bin";
        #*# DIRTY env, ABORT, DIRTY trace
        normalizePath = (
            s:
            (_'warnIf
                (builtins.isPath s)
                ''
                    lib.strings.normalizePath: The argument (${builtins.toString s}) is a path value, but only strings are supported.
                        Path values are always normalised in Nix, so there's no need to call this function on them.
                        This function also copies the path to the Nix store and returns the store path, the same as "''${path}" will, which may not be what you want.
                        This behavior is deprecated and will throw an error in the future.
                ''
                (
                    builtins.foldl'
                    (x: y: if y == "/" && _'hasSuffix "/" x then x else x+y)
                    ""
                    (_-stringToCharacters s)
                )
            )
        );
        optionalString = _-optionalString;
        #*# DIRTY env, ABORT, DIRTY trace
        hasPrefix = _'hasPrefix;
        #*# DIRTY env, ABORT, DIRTY trace
        hasInfix = (
            infix: content:
                # Before 23.05, paths would be copied to the store before converting them
                # to strings and comparing. This was surprising and confusing.
                (_'warnIf
                    (builtins.isPath infix)
                    ''
                        lib.strings.hasInfix: The first argument (${builtins.toString infix}) is a path value, but only strings are supported.
                            There is almost certainly a bug in the calling code, since this function always returns `false` in such a case.
                            This function also copies the path to the Nix store, which may not be what you want.
                            This behavior is deprecated and will throw an error in the future.
                    ''
                    (builtins.match
                        ".*${_-escapeRegex infix}.*"
                        "${content}" != null
                    )
                )
        );
        
        stringToCharacters = _-stringToCharacters;
        
        stringAsChars = (
            # Function to builtins.map over each individual character
            f:
            # Input string
            s:
                _-concatStrings (
                    (builtins.map
                        f
                        (_-stringToCharacters s)
                    )
                )
        );
        
        charToInt = _-charToInt;
        escape = _-escape;
        
        #*# ASSERT
        escapeC = (
            list: (builtins.replaceStrings
                list
                (builtins.map
                    (c:
                        "\\x${_-toLower (_'toHexString (_-charToInt c))}"
                    )
                    list
                )
            )
        );
        
        #*# ASSERT, THROW
        escapeURL = (
            let
                unreserved = [ "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "-" "_" "." "~" ];
                toEscape = builtins.removeAttrs _-asciiTable unreserved;
            in
                (builtins.replaceStrings
                    (builtins.attrNames toEscape)
                    (_-mapAttrsToList
                        (_: c: "%${_'fixedWidthString 2 "0" (_'toHexString c)}")
                        toEscape
                    )
                )
        );
        
        escapeShellArg = _-escapeShellArg;
        
        escapeShellArgs = _-escapeShellArgs;
        
        isValidPosixName = _-isValidPosixName;
        
        #*# THROW
        toShellVar = _'toShellVar;
        
        #*# THROW
        toShellVars = vars: _-concatStringsSep "\n" (_-mapAttrsToList _'toShellVar vars);
        
        escapeNixString = _-escapeNixString;
        
        escapeRegex = _-escapeRegex;
        
        escapeNixIdentifier = (
            s:
                # Regex from https://github.com/NixOS/nix/blob/d048577909e383439c2549e849c5c2f2016c997e/src/libexpr/lexer.l#L91
                if builtins.match "[a-zA-Z_][a-zA-Z0-9_'-]*" s != null
                then
                    s 
                else
                    _-escapeNixString s
        );
        escapeXML = builtins.replaceStrings ["\"" "'" "<" ">" "&"] ["&quot;" "&apos;" "&lt;" "&gt;" "&amp;"];
        
        toLower = _-toLower;
        toUpper = _-toUpper;
        addContextFrom = _-addContextFrom;
        splitString = _-splitString;
        #*# DIRTY env, ABORT, DIRTY trace
        removePrefix = (
            # Prefix to remove if it matches
            prefix:
            # Input string
            str:
                # Before 23.05, paths would be copied to the store before converting them
                # to strings and comparing. This was surprising and confusing.
                (_'warnIf
                    (builtins.isPath prefix)
                    ''
                        lib.strings.removePrefix: The first argument (${builtins.toString prefix}) is a path value, but only strings are supported.
                            There is almost certainly a bug in the calling code, since this function never removes any prefix in such a case.
                            This function also copies the path to the Nix store, which may not be what you want.
                            This behavior is deprecated and will throw an error in the future.
                    ''
                    (
                        let
                            preLen = builtins.stringLength prefix;
                            sLen = builtins.stringLength str;
                        in
                            if builtins.substring 0 preLen str == prefix
                            then
                                builtins.substring preLen (sLen - preLen) str
                            else
                                str
                    )
                )
        );
        
        #*# DIRTY env, ABORT, DIRTY trace
        removeSuffix = _'removeSuffix;
        
        versionOlder = _-versionOlder;
        
        versionAtLeast = v1: v2: !_-versionOlder v1 v2;
        
        getName = (
            x:
                let
                    parse = drv: (builtins.parseDrvName drv).name;
                in 
                    if builtins.isString x
                    then
                        parse x
                    else if x ? pname
                    then
                        x.pname
                    else
                        (parse x.name)
        );
        
        getVersion = (
            x:
            let
                parse = drv: (parseDrvName drv).version;
            in
                if builtins.isString x
                then
                    parse x
                else if x ? version
                then
                    x.version
                else
                    (parse x.name)
        );
        
        #*# ASSERT, THROW
        nameFromURL = (
            url: sep:
                let
                    components = _-splitString "/" url;
                    filename = _'last components;
                    name = builtins.head (_-splitString sep filename);
                in
                    assert name != filename; name
        );
        
        mesonOption = _-mesonOption;
        
        mesonBool = (
            condition: flag:
                assert (builtins.isString condition);
                assert (builtins.isBool flag);
                _-mesonOption condition (_-boolToString flag)
        );
        
        mesonEnable = (
            feature: flag:
                assert (builtins.isString feature);
                assert (builtins.isBool flag);
                _-mesonOption feature (if flag then "enabled" else "disabled")
        );
        
        enableFeature = _-enableFeature;
        
        enableFeatureAs = (
            enable: feat: value:
                _-enableFeature enable feat + _-optionalString enable "=${value}"
        );
        
        withFeature = _-withFeature;
        
        withFeatureAs = with_: feat: value: _-withFeature with_ feat + _-optionalString with_ "=${value}";
        
        #*# ASSERT, THROW
        fixedWidthString = _'fixedWidthString;
        
        #*# ASSERT, THROW
        fixedWidthNumber = width: n: _'fixedWidthString width "0" (builtins.toString n);
        
        #*# ASSERT, THROW
        floatToString = (
            float:
                let
                    result = builtins.toString float;
                    precise = float == builtins.fromJSON result;
                in
                    (_'warnIf
                        (!precise)
                        "Imprecise conversion from float to string ${result}"
                        result
                    )
        );
        
        isCoercibleToString = _-isConvertibleWithToString;
        isConvertibleWithToString = _-isConvertibleWithToString;
        isStringLike = _-isStringLike;
        isStorePath = (x:
            if _-isStringLike x then
                let
                    str = builtins.toString x;
                in
                    (builtins.substring 0 1 str) == "/" && (builtins.dirOf str) == storeDir
            else
                false
        );
        
        #*# THROW
        toInt = (
            str:
                let
                    # RegEx: Match any leading whitespace, possibly a '-', one or more digits,
                    # and finally match any trailing whitespace.
                    strippedInput = builtins.match "[[:space:]]*(-?[[:digit:]]+)[[:space:]]*" str;
                    # RegEx: Match a leading '0' then one or more digits.
                    isLeadingZero = builtins.match "0[[:digit:]]+" (builtins.head strippedInput) == [];
                    # Attempt to parse input
                    parsedInput = builtins.fromJSON (builtins.head strippedInput);
                    generalError = "toInt: Could not convert ${_-escapeNixString str} to int.";
                    octalAmbigError = "toInt: Ambiguity in interpretation of ${_-escapeNixString str} between octal and zero padded integer.";
                in
                    # Error on presence of non digit characters.
                    if strippedInput == null
                    then
                        builtins.throw generalError
                    # Error on presence of leading zero/octal ambiguity.
                    else if isLeadingZero
                    then
                        builtins.throw octalAmbigError
                    # Error if parse function fails.
                    else if !builtins.isInt parsedInput
                    then
                        builtins.throw generalError
                    # Return result.
                else
                    parsedInput
        );
        
        #*# THROW
        toIntBase10 = (
            str:
                let
                    # RegEx: Match any leading whitespace, then match any zero padding,
                    # capture possibly a '-' followed by one or more digits,
                    # and finally match any trailing whitespace.
                    strippedInput = builtins.match "[[:space:]]*0*(-?[[:digit:]]+)[[:space:]]*" str;

                    # RegEx: Match at least one '0'.
                    isZero = builtins.match "0+" (builtins.head strippedInput) == [];

                    # Attempt to parse input
                    parsedInput = builtins.fromJSON (builtins.head strippedInput);

                    generalError = "toIntBase10: Could not convert ${_-escapeNixString str} to int.";

                in
                    # Error on presence of non digit characters.
                    if strippedInput == null
                    then
                        builtins.throw generalError
                    # In the special case zero-padded zero (00000), return early.
                    else if isZero
                    then
                        0
                    # Error if parse function fails.
                    else if !builtins.isInt parsedInput
                    then
                        builtins.throw generalError
                    # Return result.
                    else 
                        parsedInput
        );
        
        #*# DIRTY env, ABORT, DIRTY trace
        readPathsFromFile = (
            (_'warn
                "lib.readPathsFromFile is deprecated, use a list instead"
                (rootPath: file:
                    let
                        lines = _-splitString "\n" (builtins.readFile file);
                        removeComments = builtins.filter (line: line != "" && !(_'hasPrefix "#" line));
                        relativePaths = removeComments lines;
                        absolutePaths = builtins.map (path: rootPath + "/${path}") relativePaths;
                    in
                        absolutePaths
                )
            )
        );
        
        #*# DIRTY env, ABORT, DIRTY trace
        fileContents = file: _'removeSuffix "\n" (builtins.readFile file);
        
        
        sanitizeDerivationName = (
            let
                okRegex = builtins.match "[[:alnum:]+_?=-][[:alnum:]+._?=-]*";
                magicNumber = 207;
            in
                string:
                # First detect the common case of already valid strings, to speed those up
                if builtins.stringLength string <= magicNumber && okRegex string != null
                then
                    builtins.unsafeDiscardStringContext string
                else
                    _-pipe string [
                        # Get rid of string context. This is safe under the assumption that the
                        # resulting string is only used as a derivation name
                        builtins.unsafeDiscardStringContext
                        # Strip all leading "."
                        (x: builtins.elemAt (builtins.match "\\.*(.*)" x) 0)
                        # Split out all invalid characters
                        # https://github.com/NixOS/nix/blob/2.3.2/src/libstore/store-api.cc#L85-L112
                        # https://github.com/NixOS/nix/blob/2242be83c61788b9c0736a92bb0b5c7bbfc40803/nix-rust/src/store/path.rs#L100-L125
                        (builtins.split "[^[:alnum:]+._?=-]+")
                        # Replace invalid character ranges with a "-"
                        (_-concatMapStrings (s: if builtins.isList s then "-" else s))
                        # Limit to 211 characters (minus 4 chars for ".drv")
                        (x: builtins.substring (_-max (builtins.stringLength x - magicNumber) 0) (-1) x)
                        # If the result is empty, replace it with "unknown"
                        (x: if builtins.stringLength x == 0 then "unknown" else x)
                    ]
        );
        
        levenshtein = _-levenshtein;
        
        commonPrefixLength = _-commonPrefixLength;
        
        commonSuffixLength = _-commonSuffixLength;
        
        levenshteinAtMost = (
            let
                infixDifferAtMost1 = x: y: builtins.stringLength x <= 1 && builtins.stringLength y <= 1;
                
                # This function takes two strings stripped by their common pre and suffix,
                # and returns whether they differ by at most two by Levenshtein distance.
                # Because of this stripping, if they do indeed differ by at most two edits,
                # we know that those edits were (if at all) done at the start or the end,
                # while the middle has to have stayed the same. This fact is used in the
                # implementation.
                infixDifferAtMost2 = (
                    x: y:
                        let
                            xlen = builtins.stringLength x;
                            ylen = builtins.stringLength y;
                            # This function is only called with |x| >= |y| and |x| - |y| <= 2, so
                            # diff is one of 0, 1 or 2
                            diff = xlen - ylen;

                            # Infix of x and y, stripped by the left and right most character
                            xinfix = builtins.substring 1 (xlen - 2) x;
                            yinfix = builtins.substring 1 (ylen - 2) y;

                            # x and y but a character deleted at the left or right
                            xdelr = builtins.substring 0 (xlen - 1) x;
                            xdell = builtins.substring 1 (xlen - 1) x;
                            ydelr = builtins.substring 0 (ylen - 1) y;
                            ydell = builtins.substring 1 (ylen - 1) y;
                        in
                            # A length difference of 2 can only be gotten with 2 delete edits,
                            # which have to have happened at the start and end of x
                            # Example: "abcdef" -> "bcde"
                            if diff == 2
                            then
                                xinfix == y
                            # A length difference of 1 can only be gotten with a deletion on the
                            # right and a replacement on the left or vice versa.
                            # Example: "abcdef" -> "bcdez" or "zbcde"
                            else if diff == 1
                            then
                                xinfix == ydelr || xinfix == ydell
                            # No length difference can either happen through replacements on both
                            # sides, or a deletion on the left and an insertion on the right or
                            # vice versa
                            # Example: "abcdef" -> "zbcdez" or "bcdefz" or "zabcde"
                            else xinfix == yinfix || xdelr == ydell || xdell == ydelr
                );
            in
                k:
                    if k <= 0
                    then
                        a: b:
                            a == b
                    else
                        let
                            f = (
                                a: b:
                                    let
                                        alen = builtins.stringLength a;
                                        blen = builtins.stringLength b;
                                        prelen = _-commonPrefixLength a b;
                                        suflen = _-commonSuffixLength a b;
                                        presuflen = prelen + suflen;
                                        ainfix = builtins.substring prelen (alen - presuflen) a;
                                        binfix = builtins.substring prelen (blen - presuflen) b;
                                    in
                                        # Make a be the bigger string
                                        if alen < blen
                                        then
                                            f b a
                                        # If a has over k more characters than b, even with k deletes on a, b can't be reached
                                        else if alen - blen > k
                                        then
                                            false
                                        else if k == 1
                                        then
                                            infixDifferAtMost1 ainfix binfix
                                        else if k == 2
                                        then
                                            infixDifferAtMost2 ainfix binfix
                                        else
                                            _-levenshtein ainfix binfix <= k
                            );
                        in
                            f
        );
    };
in
    {
        minver = _-minver;
        asciiTable = _-asciiTable;
        zipIntBits = _-zipIntBits;
        trivial = _-trivial;
        string  = _-string;
    }