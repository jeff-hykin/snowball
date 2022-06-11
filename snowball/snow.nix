{
        # commit date: 2021-01-11
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/b4c0ea6a072ca8478312a69d7c47b57911f1b60e/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "b4c0ea6a072ca8478312a69d7c47b57911f1b60e";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/b4c0ea6a072ca8478312a69d7c47b57911f1b60e.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python36Full;
                    packages."aarch64-linux"  = pkgs.python36Full;
                    packages."i686-linux"     = pkgs.python36Full;
                    packages."x86_64-darwin"  = pkgs.python36Full;
                    packages."aarch64-darwin" = pkgs.python36Full;
                }
        ;
    }