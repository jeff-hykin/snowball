{
        # commit date: 2021-09-24
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/a78925d568e884da7e7812bed09e02c750e8d3b0/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "a78925d568e884da7e7812bed09e02c750e8d3b0";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/a78925d568e884da7e7812bed09e02c750e8d3b0.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python38Full;
                    packages."aarch64-linux"  = pkgs.python38Full;
                    packages."i686-linux"     = pkgs.python38Full;
                    packages."x86_64-darwin"  = pkgs.python38Full;
                    packages."aarch64-darwin" = pkgs.python38Full;
                }
        ;
    }