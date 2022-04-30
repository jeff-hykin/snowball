# tools = import (builtins.fetchurl "https://raw.githubusercontent.com/jeff-hykin/snowball/5e568e55e44819606cffa5ad25a3b26a14fee11a/tools.nix")
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