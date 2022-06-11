{
        # commit date: 2021-01-23
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/79c610283db1fba2ab50515151e7bf09639cd433/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "79c610283db1fba2ab50515151e7bf09639cd433";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/79c610283db1fba2ab50515151e7bf09639cd433.tar.gz";}) ) ({}) );
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