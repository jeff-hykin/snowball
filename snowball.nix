url : 
    let 
        snowball =  (builtins.import
            (builtins.toPath
                "${builtins.fetchurl url}"
            )
        );
        outputs = (snowball.outputs 
            ({
                meta = snowball.meta;
                inputs = snowball.inputs;
            })
        );
    in
        outputs.nixShell