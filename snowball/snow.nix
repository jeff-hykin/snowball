{
        # commit date: 2022-02-10
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/60f9a9c262a69f1a490d8596d7c4fc2b401b77e0/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "60f9a9c262a69f1a490d8596d7c4fc2b401b77e0";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/60f9a9c262a69f1a490d8596d7c4fc2b401b77e0.tar.gz";}) ) ({}) );
            # customInput1 = { pkgs, ...} : pkgs.something;
            # customInput2 = { customInput1, ...} : customInput1.subPackage;
        };
        outputs = { pkgs, ... }@input:
            let
                exampleValue1 = "blah";
                exampleValue2 = "blah";
            in
                {
                    # packages."x86_64-linux" = pkgs.stdenv.mkDerivation {
                    # 
                    # };
                    packages."x86_64-linux"   = pkgs.python311;
                    packages."aarch64-linux"  = pkgs.python311;
                    packages."i686-linux"     = pkgs.python311;
                    packages."x86_64-darwin"  = pkgs.python311;
                    packages."aarch64-darwin" = pkgs.python311;
                }
        ;
    }