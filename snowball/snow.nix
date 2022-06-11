{
        # commit date: 2020-06-15
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/ff5f77688612a46bddcba990a3e3d8dc7e257c81/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "ff5f77688612a46bddcba990a3e3d8dc7e257c81";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/ff5f77688612a46bddcba990a3e3d8dc7e257c81.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python35;
                    packages."aarch64-linux"  = pkgs.python35;
                    packages."i686-linux"     = pkgs.python35;
                    packages."x86_64-darwin"  = pkgs.python35;
                    packages."aarch64-darwin" = pkgs.python35;
                }
        ;
    }