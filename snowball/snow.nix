{
        # commit date: 2020-07-13
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/377324ca6d05eaf76788ff95f17bcb6895bdcf10/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "377324ca6d05eaf76788ff95f17bcb6895bdcf10";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/377324ca6d05eaf76788ff95f17bcb6895bdcf10.tar.gz";}) ) ({}) );
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