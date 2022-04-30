# tools = import (builtins.fetchurl "https://raw.githubusercontent.com/jeff-hykin/snowball/29a4cb39d8db70f9b6d13f52b3a37a03aae48819/tools.nix")
{
    # a function for cutting down on boilerplate
    nixpkgsAt =  commitHash : 
        (builtins.import
            (builtins.fetchTarball 
                ({
                    url = "https://github.com/NixOS/nixpkgs/archive/${commitHash}.tar.gz";
                })
            )
            ({})
        )
    ;
}