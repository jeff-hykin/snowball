{
        # commit date: 2019-12-19
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/d244b77850263501c149435f2ff2de357b9db72c/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "d244b77850263501c149435f2ff2de357b9db72c";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/d244b77850263501c149435f2ff2de357b9db72c.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python39;
                    packages."aarch64-linux"  = pkgs.python39;
                    packages."i686-linux"     = pkgs.python39;
                    packages."x86_64-darwin"  = pkgs.python39;
                    packages."aarch64-darwin" = pkgs.python39;
                }
        ;
    }