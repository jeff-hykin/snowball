{
        # commit date: 2022-04-20
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/ba02fd0434ed92b7335f17c97af689b9db1413e0/pkgs/development/interpreters/python/cpython/default.nix
        inputs = {
            nixpkgsHash   = { ...} : "ba02fd0434ed92b7335f17c97af689b9db1413e0";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/ba02fd0434ed92b7335f17c97af689b9db1413e0.tar.gz";}) ) ({}) );
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
                    packages."x86_64-linux"   = pkgs.python3Full;
                    packages."aarch64-linux"  = pkgs.python3Full;
                    packages."i686-linux"     = pkgs.python3Full;
                    packages."x86_64-darwin"  = pkgs.python3Full;
                    packages."aarch64-darwin" = pkgs.python3Full;
                }
        ;
    }