{
        # commit date: 2019-10-14
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/81d15948cc19c2584f13031518349327ce353c82/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "81d15948cc19c2584f13031518349327ce353c82";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/81d15948cc19c2584f13031518349327ce353c82.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python38;
                    packages."aarch64-linux"  = pkgs.python38;
                    packages."i686-linux"     = pkgs.python38;
                    packages."x86_64-darwin"  = pkgs.python38;
                    packages."aarch64-darwin" = pkgs.python38;
                }
        ;
    }