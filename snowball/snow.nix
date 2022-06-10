{
        # commit date: 2021-10-05
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/c55acca2a82327750d0e685306a454d5d3f84091/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "c55acca2a82327750d0e685306a454d5d3f84091";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/c55acca2a82327750d0e685306a454d5d3f84091.tar.gz";}) ) ({}) );
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