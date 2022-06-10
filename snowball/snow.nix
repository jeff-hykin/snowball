{
        # commit date: 2021-02-26
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/fdc872fa200a32456f12cc849d33b1fdbd6a933c/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "fdc872fa200a32456f12cc849d33b1fdbd6a933c";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/fdc872fa200a32456f12cc849d33b1fdbd6a933c.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python37;
                    packages."aarch64-linux"  = pkgs.python37;
                    packages."i686-linux"     = pkgs.python37;
                    packages."x86_64-darwin"  = pkgs.python37;
                    packages."aarch64-darwin" = pkgs.python37;
                }
        ;
    }