{
        # commit date: 2019-09-09
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/0107ee8c322e57cdb2ebcc1c9c4286ff7db53d5c/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "0107ee8c322e57cdb2ebcc1c9c4286ff7db53d5c";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/0107ee8c322e57cdb2ebcc1c9c4286ff7db53d5c.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python35Full;
                    packages."aarch64-linux"  = pkgs.python35Full;
                    packages."i686-linux"     = pkgs.python35Full;
                    packages."x86_64-darwin"  = pkgs.python35Full;
                    packages."aarch64-darwin" = pkgs.python35Full;
                }
        ;
    }