{
        # commit date: 2021-01-04
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/4a6916aba3ec57667d5e5582e84bbd1613e1a056/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "4a6916aba3ec57667d5e5582e84bbd1613e1a056";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/4a6916aba3ec57667d5e5582e84bbd1613e1a056.tar.gz";}) ) ({}) );
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