{
    # snowball = import (builtins.fetchurl "https://raw.githubusercontent.com/jeff-hykin/snowball/29a4cb39d8db70f9b6d13f52b3a37a03aae48819/snowball.nix")
    # ikill = snowball "https://raw.githubusercontent.com/jeff-hykin/snowball/283c245be12fe40d4ff2b7402e9de06ae9baf698/"
    inputs =  {};
    outputs = { variant, stdenv, lib, callPackage, fetchFromGitHub, rustPlatform, installShellFiles, libiconv, libobjc, Security, CoreServices, Metal, Foundation, QuartzCore, librusty_v8, ... }: {
        values = {
            load = url : 
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
                    outputs
            ;
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
        };
    };
}