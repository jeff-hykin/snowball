{
        # commit date: 2021-11-02
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/94d91a448b87a70204485bd768977c07575911e8/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "94d91a448b87a70204485bd768977c07575911e8";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/94d91a448b87a70204485bd768977c07575911e8.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python39Full;
                    packages."aarch64-linux"  = pkgs.python39Full;
                    packages."i686-linux"     = pkgs.python39Full;
                    packages."x86_64-darwin"  = pkgs.python39Full;
                    packages."aarch64-darwin" = pkgs.python39Full;
                }
        ;
    }