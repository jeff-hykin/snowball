{
        # commit date: 2021-01-18
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/b7e5fea35effd4fa9adaf747b6ed543b04ae2682/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "b7e5fea35effd4fa9adaf747b6ed543b04ae2682";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/b7e5fea35effd4fa9adaf747b6ed543b04ae2682.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python39;
                    packages."aarch64-linux"  = pkgs.python39;
                    packages."i686-linux"     = pkgs.python39;
                    packages."x86_64-darwin"  = pkgs.python39;
                    packages."aarch64-darwin" = pkgs.python39;
                }
        ;
    }