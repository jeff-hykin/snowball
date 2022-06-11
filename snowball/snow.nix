{
        # commit date: 2020-04-05
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/e50c67ad7eefa8e77436fbd0366b69638b1c8713/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "e50c67ad7eefa8e77436fbd0366b69638b1c8713";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/e50c67ad7eefa8e77436fbd0366b69638b1c8713.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python35;
                    packages."aarch64-linux"  = pkgs.python35;
                    packages."i686-linux"     = pkgs.python35;
                    packages."x86_64-darwin"  = pkgs.python35;
                    packages."aarch64-darwin" = pkgs.python35;
                }
        ;
    }