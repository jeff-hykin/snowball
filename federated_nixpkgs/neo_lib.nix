# no "with" allowed
# no " or " allowed

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
    
    

let
    # 
    # lib/minver.nix
    # 
    _minver = "2.3";
    
    # 
    # lib/ascii-table.nix
    # 
    _asciiTable = {
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
    _zipIntBits = (
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
    
    #*# DIRTY env, ABORT, DIRTY trace
    _warn = (
        if builtins.elem (builtins.getEnv "NIX_ABORT_ON_WARN") ["1" "true" "yes"]
        then msg: builtins.trace "[1;31mwarning: ${msg}[0m" (builtins.abort "NIX_ABORT_ON_WARN=true; warnings are treated as unrecoverable errors.")
        else msg: builtins.trace "[1;31mwarning: ${msg}[0m";
    );
    
    #*# THROW
    _throwIfNot = cond: msg: if cond then x: x else builtins.throw msg;
    
    _subtractLists = e: builtins.filter (x: !(builtins.elem x e));
    
    _foldr = op: nul: list:
        let
            len = builtins.length list;
            fold' = n:
                if n == len
                then nul
                else op (builtins.elemAt list n) (fold' (n + 1));
        in
            fold' 0;
    
    _functionArgs = (
        f:
            if f ? __functor
            then
                if f ? __functionArgs
                then
                    f.__functionArgs
                else
                    # recursion
                    (_functionArgs (f.__functor f))
            else
                builtins.functionArgs f
    );
    
    _isFunction = f: builtins.isFunction f || (f ? __functor && _isFunction (f.__functor f));
    
    _reverseList = (
        xs:
            let
                l = builtins.length xs;
            in
                builtins.genList (n: builtins.elemAt xs (l - n - 1)) l
    );
    
    _concatStrings = builtins.concatStringsSep "";

    _concatMapStrings = f: list: _concatStrings (builtins.map f list);
    
    _toBaseDigits = (
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
                _reverseList (go i)
    )
    
    # 
    # lib/trivial.nix
    # 
    _trivial = {
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
        
        pipe = (
            val: functions:
                let
                    reverseApply = x: f: f x;
                in
                    builtins.foldl' reverseApply val functions
        );
        
        concat = x: y: x ++ y;

        or = x: y: x || y;

        and = x: y: x && y;
        
        #*# ASSERT
        bitAnd = (
            if builtins.hasAttr "bitAnd" builtins
            then
                builtins.bitAnd
            else 
                (_zipIntBits
                    (a: b: if a==1 && b==1 then 1 else 0)
                )
        );

        #*# ASSERT
        bitOr = (
            if builtins.hasAttr "bitOr" builtins
            then
                builtins.bitOr
            else 
                (_zipIntBits
                    (a: b: if a==1 || b==1 then 1 else 0)
                )
        );

        #*# ASSERT
        bitXor = (
            if builtins.hasAttr "bitXor" builtins
            then
                builtins.bitXor
            else 
                (_zipIntBits
                    (a: b: if a!=b then 1 else 0)
                )
        );

        bitNot = builtins.sub (-1);
        
        boolToString = b: if b then "true" else "false";
        
        mergeAttrs = x: y: x // y;
        
        flip = f: a: b: f b a;
        
        mapNullable = f: a: if a == null then a else f a;
        
        min = x: y: if x < y then x else y;
  
        max = x: y: if x > y then x else y;
            
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
        warn = _warn;
        #*# DIRTY env, ABORT, DIRTY trace
        warnIf = cond: msg: if cond then _warn msg else x: x;
        #*# DIRTY env, ABORT, DIRTY trace
        warnIfNot = cond: msg: if cond then x: x else _warn msg;
        
        #*# THROW
        throwIfNot = _throwIfNot;
        #*# THROW
        throwIf = cond: msg: if cond then builtins.throw msg else x: x;
        
        #*# THROW
        checkListOfEnum = (
            msg: valid: given:
                let
                    unexpected = _subtractLists valid given;
                in
                    _throwIfNot (unexpected == [])
                        "${msg}: ${builtins.concatStringsSep ", " (builtins.map builtins.toString unexpected)} unexpected; valid ones: ${builtins.concatStringsSep ", " (builtins.map builtins.toString valid)}"
        );
        
        #*# DIRTY trace
        info = msg: builtins.trace "INFO: ${msg}";
        
        #*# DIRTY env, ABORT, DIRTY trace
        showWarnings = warnings: res: _foldr (w: x: _warn w x) res warnings;
        
        setFunctionArgs = (
            f: args:
                {
                    __functor = self: f;
                    __functionArgs = args;
                }
        );
        
        functionArgs = _functionArgs;
        
        isFunction = _isFunction;
        
        toFunction = (
            # Any value
            v:
                if _isFunction v
                then
                    v
                else
                    k: v
        );
        
        #*# ASSERT
        toBaseDigits = _toBaseDigits;
        
        toHexString = (
            i:
                let
                    toHexDigit = d:
                        if d < 10
                        then toString d
                        else
                            {
                                "10" = "A";
                                "11" = "B";
                                "12" = "C";
                                "13" = "D";
                                "14" = "E";
                                "15" = "F";
                            }.${toString d};
                in
                    _concatMapStrings toHexDigit (_toBaseDigits 16 i)
        );
    };
in
    {
        minver = _minver;
        asciiTable = _asciiTable;
        zipIntBits = _zipIntBits;
        trivial = _trivial;
    }