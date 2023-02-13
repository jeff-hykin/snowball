
        nix eval -I 'nixpkgs=https://github.com/NixOS/nixpkgs/archive/aa0e8072a57e879073cee969a780e586dbe57997.tar.gz' --impure --expr  '
    let
        n = import <nixpkgs> {};
    in
        (builtins.toJSON
            (builtins.attrNames
                n
            )
        )
'
    