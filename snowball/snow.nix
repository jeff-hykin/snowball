{
        # commit date: 2021-01-13
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/07e7cea102b7254ed29185d4da504aa07a77dd2b/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "07e7cea102b7254ed29185d4da504aa07a77dd2b";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/07e7cea102b7254ed29185d4da504aa07a77dd2b.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python3;
                    packages."aarch64-linux"  = pkgs.python3;
                    packages."i686-linux"     = pkgs.python3;
                    packages."x86_64-darwin"  = pkgs.python3;
                    packages."aarch64-darwin" = pkgs.python3;
                }
        ;
    }