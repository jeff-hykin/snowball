{
        # commit date: 2022-04-17
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/95af2245a32f8e1310ad4e3bf50b76d86ddbbc0a/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "95af2245a32f8e1310ad4e3bf50b76d86ddbbc0a";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/95af2245a32f8e1310ad4e3bf50b76d86ddbbc0a.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python38;
                    packages."aarch64-linux"  = pkgs.python38;
                    packages."i686-linux"     = pkgs.python38;
                    packages."x86_64-darwin"  = pkgs.python38;
                    packages."aarch64-darwin" = pkgs.python38;
                }
        ;
    }