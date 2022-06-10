{
        # commit date: 2021-04-05
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/7c932296e05b32e5414140d69aac75a039d0a7f0/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "7c932296e05b32e5414140d69aac75a039d0a7f0";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/7c932296e05b32e5414140d69aac75a039d0a7f0.tar.gz";}) ) ({}) );
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