{
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/78af98a068906cb88fa14c31bd703341562bf890/pkgs/development/interpreters/python/cpython/2.7/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "78af98a068906cb88fa14c31bd703341562bf890";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/78af98a068906cb88fa14c31bd703341562bf890.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python2Full;
                    packages."aarch64-linux"  = pkgs.python2Full;
                    packages."i686-linux"     = pkgs.python2Full;
                    packages."x86_64-darwin"  = pkgs.python2Full;
                    packages."aarch64-darwin" = pkgs.python2Full;
                }
        ;
    }