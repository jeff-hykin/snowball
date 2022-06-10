{
        # commit date: 2022-03-15
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/8d18f29b6001756116cbb188468ef10178f44046/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "8d18f29b6001756116cbb188468ef10178f44046";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/8d18f29b6001756116cbb188468ef10178f44046.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python310;
                    packages."aarch64-linux"  = pkgs.python310;
                    packages."i686-linux"     = pkgs.python310;
                    packages."x86_64-darwin"  = pkgs.python310;
                    packages."aarch64-darwin" = pkgs.python310;
                }
        ;
    }