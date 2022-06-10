{
        # commit date: 2021-09-15
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/ff94eef5c14da66ede95e968425afb1eda2c788b/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "ff94eef5c14da66ede95e968425afb1eda2c788b";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/ff94eef5c14da66ede95e968425afb1eda2c788b.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python3Full;
                    packages."aarch64-linux"  = pkgs.python3Full;
                    packages."i686-linux"     = pkgs.python3Full;
                    packages."x86_64-darwin"  = pkgs.python3Full;
                    packages."aarch64-darwin" = pkgs.python3Full;
                }
        ;
    }