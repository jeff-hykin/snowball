// import { parse } from "./fornix/support/nix_parser.bundle.js"
// import { createArgsFileFor, getCallPackagePaths } from "./tools.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.8/string.js"
import { FileSystem } from "https://deno.land/x/quickr@0.6.18/main/file_system.js"
// import { run, throwIfFails, zipInto, mergeInto, returnAsString, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo } from "https://deno.land/x/quickr@0.6.18/main/run.js"
import { run, throwIfFails, zipInto, mergeInto, returnAsString, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo } from "/Users/jeffhykin/repos/quickr/main/run.js"
import { yellow } from "https://deno.land/x/quickr@0.6.18/main/console.js"
import { recursivelyAllKeysOf, get, set, remove, merge, compareProperty } from "https://deno.land/x/good@0.7.8/object.js"

const _ = await import("https://cdn.skypack.dev/lodash")

let commitHash = "aa0e8072a57e879073cee969a780e586dbe57997"

async function runNix(code) {
    const tempFolder = `temp.ignore/`
    const seed = `${Math.random()}`.replace(/\./, "")
    const stdoutPath = `${tempFolder}/nix_stdout_${seed}.log`
    const stderrPath = `${tempFolder}/nix_stderr_${seed}.log`
    const executablePath = "temp.ignore/nix_code.sh"
    // shell escape
    code = code.replace(/'/, `'"'"'`)
    await FileSystem.write({
        path: executablePath,
        data: `
            nix eval -I 'nixpkgs=https://github.com/NixOS/nixpkgs/archive/${commitHash}.tar.gz' --impure --expr '${code}' >'${stdoutPath}' 2>'${stderrPath}'
        `,
    })
    var process = Deno.run({
        "cmd": [
            "bash",
            executablePath,
        ],
    })
    await process.status()
    const stdout = await FileSystem.read(stdoutPath)
    const stderr = await FileSystem.read(stderrPath)
    return {stdout, stderr}
}

async function getAttributesFor(attrPath) {
    const path = ["(import <nixpkgs> {})"].concat(attrPath)
    const code = `
        (builtins.toJSON
            (builtins.attrNames
                (${path.join(".")})
            )
        )
    `
    // TODO: nix-escape these values since some of them might need quotes
    try {
        var output = (await runNix(code)).stdout
        return JSON.parse(JSON.parse(
            output
        ))
    } catch (error) {
        return []
    }
}

console.log(await getAttributesFor([]))

// const output = run`bash ./code.sh ${Stdout(returnAsString)}`
// console.debug(`output.stdout is:`, output)
// console.debug(`output is:`, output)
