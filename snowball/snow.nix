{
        # commit date: 2020-11-28
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/2622548c138fbf151fd3f130fe41864590520121/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "2622548c138fbf151fd3f130fe41864590520121";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/2622548c138fbf151fd3f130fe41864590520121.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python3;
                    packages."aarch64-linux"  = pkgs.python3;
                    packages."i686-linux"     = pkgs.python3;
                    packages."x86_64-darwin"  = pkgs.python3;
                    packages."aarch64-darwin" = pkgs.python3;
                }
        ;
    }