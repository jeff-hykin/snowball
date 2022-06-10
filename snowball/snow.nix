{
        # commit date: 2021-03-31
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/9b9e9cff00b07d680f02d5541756c93735f5074d/pkgs/development/interpreters/python/cpython/2.7/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "9b9e9cff00b07d680f02d5541756c93735f5074d";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/9b9e9cff00b07d680f02d5541756c93735f5074d.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.pythonFull;
                    packages."aarch64-linux"  = pkgs.pythonFull;
                    packages."i686-linux"     = pkgs.pythonFull;
                    packages."x86_64-darwin"  = pkgs.pythonFull;
                    packages."aarch64-darwin" = pkgs.pythonFull;
                }
        ;
    }