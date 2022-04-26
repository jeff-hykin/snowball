url : 
    let 
        meta = (builtins.fromTOML (builtins.fetchurl "${url}/package/info.toml"));
        snowball = (builtins.import (builtins.fetchurl "${url}/package/snowball.nix"));
        outputs = (snowball.outputs 
            ({
                meta = meta;
                inputs = snowball.inputs;
            })
        );
    in
        outputs.nixShell