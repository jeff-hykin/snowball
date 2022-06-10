{
        # commit date: 2022-04-14
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/5c7148bd9fbd855f29ba33506724c38f7f0ec484/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "5c7148bd9fbd855f29ba33506724c38f7f0ec484";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/5c7148bd9fbd855f29ba33506724c38f7f0ec484.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python310;
                    packages."aarch64-linux"  = pkgs.python310;
                    packages."i686-linux"     = pkgs.python310;
                    packages."x86_64-darwin"  = pkgs.python310;
                    packages."aarch64-darwin" = pkgs.python310;
                }
        ;
    }