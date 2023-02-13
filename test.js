import { parse } from "./fornix/support/nix_parser.bundle.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.8/string.js"
import { FileSystem } from "https://deno.land/x/quickr@0.6.17/main/file_system.js"
import { yellow } from "https://deno.land/x/quickr@0.6.17/main/console.js"

import { createArgsFileFor, getCallPackagePaths } from "./tools.js"
const _ = (await import('https://cdn.skypack.dev/lodash'))

// 
// create args for all the default paths
// 
for (const eachPath of await FileSystem.listFilePathsIn("../nixpkgs", { recursively: true })) {
    if (FileSystem.basename(eachPath) == "default.nix") {
        createArgsFileFor(eachPath)
    }
}

// 
// find all the files with callPackage in them
// 
let callPackageFrequencyCount = {}
let promises = []
for (const eachPath of await FileSystem.listFilePathsIn("../nixpkgs", { recursively: true })) {
    promises.append(
        FileSystem.read(eachPath).then(eachString=>{
            const callPackageMatch = eachString.match(/\bcallPackage\b/g)
            if (callPackageMatch) {
                callPackageMatch[eachPath] = callPackageMatch.length
            }
        })
    )
}
await Promise.all(promises); promises = []

// 
// find their target values
// 
const findTargetPromises = []
const handleCreateArgsPromises = []
for (const [path, callPackageCount] of _.sortBy(Object.entries(callPackageFrequencyCount), ['1']).reverse()) {
    findTargetPromises.push(
        getCallPackagePaths(path).then(([ relativePath, fullPath, source ])=>{
            handleCreateArgsPromises.push(
                createArgsFileFor(fullPath).then(success=>{
                    if (success) {
                        return [relativePath, source]
                    }
                })
            )
        })
    )
}
await Promise.all(findTargetPromises)
const replacements = await Promise.all(handleCreateArgsPromises)
const replacementMapping = {}
for (let [ relativePath, source ] of replacements.filter(each=>each instanceof Array)) {
    replacementMapping[source] = {
        [relativePath]: true,
        ...replacementMapping[source],
    }
}
// for each file that needs some replacements
for (const [path, replacements] of Object.entries(replacementMapping)) {
    // FIXME: make a function that parses the attr = callPackage, and adds another attr = after it
}