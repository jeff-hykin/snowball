{
        # commit date: 2020-05-29
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/b27a19d5bf799f581a8afc2b554f178e58c1f524/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "b27a19d5bf799f581a8afc2b554f178e58c1f524";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/b27a19d5bf799f581a8afc2b554f178e58c1f524.tar.gz";}) ) ({}) );
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