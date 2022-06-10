{
        # commit date: 2022-01-09
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/76e5d2339c193ef84493c20dd365e8d51364902b/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "76e5d2339c193ef84493c20dd365e8d51364902b";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/76e5d2339c193ef84493c20dd365e8d51364902b.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python310;
                    packages."aarch64-linux"  = pkgs.python310;
                    packages."i686-linux"     = pkgs.python310;
                    packages."x86_64-darwin"  = pkgs.python310;
                    packages."aarch64-darwin" = pkgs.python310;
                }
        ;
    }