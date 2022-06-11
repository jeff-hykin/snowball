{
        # commit date: 2020-05-31
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/2379e36124a07db4730f8f2f7529952aa8e57743/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "2379e36124a07db4730f8f2f7529952aa8e57743";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/2379e36124a07db4730f8f2f7529952aa8e57743.tar.gz";}) ) ({}) );
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