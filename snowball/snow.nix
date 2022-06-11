{
        # commit date: 2019-09-06
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/076860e0340a5e4a909b9a710e186508b14d1c90/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "076860e0340a5e4a909b9a710e186508b14d1c90";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/076860e0340a5e4a909b9a710e186508b14d1c90.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python37Full;
                    packages."aarch64-linux"  = pkgs.python37Full;
                    packages."i686-linux"     = pkgs.python37Full;
                    packages."x86_64-darwin"  = pkgs.python37Full;
                    packages."aarch64-darwin" = pkgs.python37Full;
                }
        ;
    }