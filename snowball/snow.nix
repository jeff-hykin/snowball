{
        # commit date: 2020-03-29
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/c392d705181cf3677d1326351bf361354a65e52f/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "c392d705181cf3677d1326351bf361354a65e52f";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/c392d705181cf3677d1326351bf361354a65e52f.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python38Full;
                    packages."aarch64-linux"  = pkgs.python38Full;
                    packages."i686-linux"     = pkgs.python38Full;
                    packages."x86_64-darwin"  = pkgs.python38Full;
                    packages."aarch64-darwin" = pkgs.python38Full;
                }
        ;
    }