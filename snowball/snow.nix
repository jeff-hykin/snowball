{
        # commit date: 2020-03-31
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/84cf00f98031e93f389f1eb93c4a7374a33cc0a9/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "84cf00f98031e93f389f1eb93c4a7374a33cc0a9";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/84cf00f98031e93f389f1eb93c4a7374a33cc0a9.tar.gz";}) ) ({}) );
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