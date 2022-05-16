{
    inputs = 
        let 
            nixpkgsHash = (builtins.fromJSON (builtins.readFile ./pinned.json)).nixpkgsHash;
            pkgs = (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/${nixpkgsHash}.tar.gz";}) ) ({}) );
        in
            {
                pkgs = pkgs;
                custom = {
                    # example: forceSingleThreded = false; would be something that belongs in custom
                };
                # args and default values here
            };
    outputs = {pkgs, custom, ...}@input:
        let
            something = "blah";
        in
            # pkgs.stdenv.mkDerivation {
            # 
            # }
            pkgs#{{attributePathToPackage}}
    ;
}