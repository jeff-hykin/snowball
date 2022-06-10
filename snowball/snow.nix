{
        # commit date: 2022-04-21
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/881ea516cf552fbb159aed4462873762a8297409/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "881ea516cf552fbb159aed4462873762a8297409";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/881ea516cf552fbb159aed4462873762a8297409.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python311;
                    packages."aarch64-linux"  = pkgs.python311;
                    packages."i686-linux"     = pkgs.python311;
                    packages."x86_64-darwin"  = pkgs.python311;
                    packages."aarch64-darwin" = pkgs.python311;
                }
        ;
    }