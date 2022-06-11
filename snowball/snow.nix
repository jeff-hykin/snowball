{
        # commit date: 2020-01-15
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/c5f3c184a72833b96a41aeaf8d6ff1aef4e24ed8/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "c5f3c184a72833b96a41aeaf8d6ff1aef4e24ed8";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/c5f3c184a72833b96a41aeaf8d6ff1aef4e24ed8.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python36;
                    packages."aarch64-linux"  = pkgs.python36;
                    packages."i686-linux"     = pkgs.python36;
                    packages."x86_64-darwin"  = pkgs.python36;
                    packages."aarch64-darwin" = pkgs.python36;
                }
        ;
    }