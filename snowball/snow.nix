{
        # commit date: 2021-03-19
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/f5e8bdd07d1afaabf6b37afc5497b1e498b8046f/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "f5e8bdd07d1afaabf6b37afc5497b1e498b8046f";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/f5e8bdd07d1afaabf6b37afc5497b1e498b8046f.tar.gz";}) ) ({}) );
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