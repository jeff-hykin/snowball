{
        # commit date: 2020-06-22
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/b7ce309e6c6fbad584df85d9fd62c5185153e8f9/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "b7ce309e6c6fbad584df85d9fd62c5185153e8f9";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/b7ce309e6c6fbad584df85d9fd62c5185153e8f9.tar.gz";}) ) ({}) );
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