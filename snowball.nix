url : 
    let 
        meta = (builtins.fromTOML (builtins.readFile (builtins.fetchurl "${url}/package/info.toml"))).meta;
        snowball = (builtins.import (builtins.fetchurl "${url}/package/snowball.nix"));
        outputs = (snowball.outputs 
            ({
                meta = meta;
                inputs = snowball.inputs;
            })
        );
    in
        outputs.nixShell