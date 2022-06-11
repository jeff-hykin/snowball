{
        # commit date: 2020-11-09
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/5a5122418ae3f4c7cafaa867915826afda3a5b5d/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "5a5122418ae3f4c7cafaa867915826afda3a5b5d";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/5a5122418ae3f4c7cafaa867915826afda3a5b5d.tar.gz";}) ) ({}) );
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