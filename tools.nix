# tools = import (builtins.fetchurl "https://raw.githubusercontent.com/jeff-hykin/snowball/5e568e55e44819606cffa5ad25a3b26a14fee11a/tools.nix")
rec {
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
    getSnowball = { url, inputs, ... } : 
        let 
            snow = (builtins.import (builtins.fetchurl url));
            outputs = (snow.outputs 
                ({
                    inputs = snow.inputs // inputs;
                })
            );
        in
            outputs
    ;
    snowball = {
        values = args: (getSnowball (args)).values;
    };
}