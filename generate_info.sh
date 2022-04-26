#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash_5 deno nix -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/7e9b0dff974c89e070da1ad85713ff3c20b0ca97.tar.gz

# NOTE: deno dependency, and only tested on nix 2.3.7 
package_path="$PWD/$1"
variant="$2"
if [ -z "$variant" ]
then
    variant="_"
fi
info_path="$(dirname "$package_path")/variants/$variant.json"
mkdir -p "$(dirname "$info_path")"
NO_COLOR="true" deno eval "console.log(JSON.stringify(JSON.parse($(ARG1="$package_path" ARG2="$variant" nix eval '(let 
        snowball = (builtins.import (builtins.getEnv ("ARG1")));
        outputs = (snowball.outputs (snowball.inputs // { variant = (builtins.getEnv ("ARG2")); }));
    in
        (builtins.toJSON (outputs.info))
)')),0,4))" > "$info_path"