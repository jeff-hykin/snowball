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
    packSnowball = { inputs, outputs } : 
        let
            evaledInputs = (builtins.foldl'
                # with each input add the key-value pair to a set, and evaluate any inputs that are functions, giving them the already-evaled inputs as inputs
                (accumulator:
                    {key, value}:
                        accumulator // {
                            "${key}" =
                                if (builtins.isFunction (value))
                                then value (accumulator)
                                else value
                            ;
                        }
                )
                # start with an empty {}
                ({ })
                # create a list of {key=, value=}
                (builtins.map
                    (each: 
                        {
                            key = each;
                            value = (builtins.getAttr (each) inputs);
                        }
                    )
                    (builtins.attrNames inputs)
                )
            );
            outputs = (snow.outputs (evaledInputs));
        in
            outputs
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