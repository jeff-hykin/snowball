{
        # commit date: 2020-11-19
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/93b430bc6ba3c084d66f96546dd7b95a2835eceb/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "93b430bc6ba3c084d66f96546dd7b95a2835eceb";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/93b430bc6ba3c084d66f96546dd7b95a2835eceb.tar.gz";}) ) ({}) );
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