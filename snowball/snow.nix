{
        # commit date: 2021-07-20
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/586a9e6bffb1b4e0e444bf4013169d8f415f2987/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "586a9e6bffb1b4e0e444bf4013169d8f415f2987";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/586a9e6bffb1b4e0e444bf4013169d8f415f2987.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.gnuradio3_8Packages.python;
                    packages."aarch64-linux"  = pkgs.gnuradio3_8Packages.python;
                    packages."i686-linux"     = pkgs.gnuradio3_8Packages.python;
                    packages."x86_64-darwin"  = pkgs.gnuradio3_8Packages.python;
                    packages."aarch64-darwin" = pkgs.gnuradio3_8Packages.python;
                }
        ;
    }