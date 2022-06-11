{
        # commit date: 2021-01-03
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/f7267e9797ac07efd6e9e2f4b21bb0068779b5b6/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "f7267e9797ac07efd6e9e2f4b21bb0068779b5b6";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/f7267e9797ac07efd6e9e2f4b21bb0068779b5b6.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python37;
                    packages."aarch64-linux"  = pkgs.python37;
                    packages."i686-linux"     = pkgs.python37;
                    packages."x86_64-darwin"  = pkgs.python37;
                    packages."aarch64-darwin" = pkgs.python37;
                }
        ;
    }