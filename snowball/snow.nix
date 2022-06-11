{
        # commit date: 2020-08-24
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/784e8190706c7c0eb00b14d08864ec1f54241e5c/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "784e8190706c7c0eb00b14d08864ec1f54241e5c";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/784e8190706c7c0eb00b14d08864ec1f54241e5c.tar.gz";}) ) ({}) );
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