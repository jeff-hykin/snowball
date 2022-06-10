{
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/d9de79194aaa0077fe19e8296711c22dfe238e96/pkgs/development/interpreters/python/cpython/2.7/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "d9de79194aaa0077fe19e8296711c22dfe238e96";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/d9de79194aaa0077fe19e8296711c22dfe238e96.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.pythonFull;
                    packages."aarch64-linux"  = pkgs.pythonFull;
                    packages."i686-linux"     = pkgs.pythonFull;
                    packages."x86_64-darwin"  = pkgs.pythonFull;
                    packages."aarch64-darwin" = pkgs.pythonFull;
                }
        ;
    }