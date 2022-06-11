{
        # commit date: 2020-08-04
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/8a78890a08dfa697be21891619f799738b956aa5/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "8a78890a08dfa697be21891619f799738b956aa5";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/8a78890a08dfa697be21891619f799738b956aa5.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python3Full;
                    packages."aarch64-linux"  = pkgs.python3Full;
                    packages."i686-linux"     = pkgs.python3Full;
                    packages."x86_64-darwin"  = pkgs.python3Full;
                    packages."aarch64-darwin" = pkgs.python3Full;
                }
        ;
    }