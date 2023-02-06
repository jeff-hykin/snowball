import { parse } from "./fornix/support/nix_parser.bundle.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.8/string.js"
import { FileSystem } from "https://deno.land/x/quickr@0.6.17/main/file_system.js"
import { yellow } from "https://deno.land/x/quickr@0.6.17/main/console.js"

import { createArgsFileFor } from "./tools.js"

// 
// create args for all the default paths
// 
for (const eachPath of await FileSystem.listFilePathsIn("../nixpkgs", { recursively: true })) {
    if (FileSystem.basename(eachPath) == "default.nix") {
        createArgsFileFor(eachPath)
    }
}