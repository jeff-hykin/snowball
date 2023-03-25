import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.8/string.js"
import { FileSystem } from "https://deno.land/x/quickr@0.6.18/main/file_system.js"
// import { run, throwIfFails, zipInto, mergeInto, returnAsString, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo } from "https://deno.land/x/quickr@0.6.18/main/run.js"
import { run, throwIfFails, zipInto, mergeInto, returnAsString, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo } from "/Users/jeffhykin/repos/quickr/main/run.js"
import { yellow } from "https://deno.land/x/quickr@0.6.18/main/console.js"
import { recursivelyAllKeysOf, get, set, remove, merge, compareProperty } from "https://deno.land/x/good@0.7.8/object.js"

async function runNix(code) {
    return await run`nix eval -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/aa0e8072a57e879073cee969a780e586dbe57997.tar.gz --impure --expr ${'(builtins.attrNames (import <nixpkgs> {}))'} ${Stdout(returnAsString)}`
}

await runNix(`(builtins.toJSON
            (builtins.attrNames
                (import <nixpkgs> {})
            )
        )
    `)