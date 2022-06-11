{
        # commit date: 2020-11-10
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/3e7fae8eae52f9260d2e251d3346f4d36c0b3116/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "3e7fae8eae52f9260d2e251d3346f4d36c0b3116";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/3e7fae8eae52f9260d2e251d3346f4d36c0b3116.tar.gz";}) ) ({}) );
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