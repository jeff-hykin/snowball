import { parse } from "./fornix/support/nix_parser.bundle.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.8/string.js"
import { FileSystem } from "https://deno.land/x/quickr@0.6.17/main/file_system.js"
import { yellow } from "https://deno.land/x/quickr@0.6.17/main/console.js"

import { createArgsFileFor, getCallPackagePaths, realParse, nodeAsJsonObject, nodeList } from "./tools.js"

const _ = (await import('https://cdn.skypack.dev/lodash'))

const postfix = "__args"

// 
// create args for all the default paths
// 
for (const eachPath of await FileSystem.listFilePathsIn("../nixpkgs", { recursively: true })) {
    if (FileSystem.basename(eachPath) == "default.nix") {
        createArgsFileFor(eachPath, postfix)
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
                createArgsFileFor(fullPath, postfix).then(success=>{
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
for (const [pathToFileThatNeedsUpdating, replacements] of Object.entries(replacementMapping)) {
    // FIXME: make a function that parses the attr = callPackage, and adds another attr = after it
    
    const tree = realParse(await FileSystem.read(pathToFileThatNeedsUpdating))
    const jsonableTree = nodeAsJsonObject(tree.rootNode)
    const allNodes = nodeList(jsonableTree)
    // attach an index to each
    allNodes.map((each, index)=>{
        each.nodeIndex = index
        return each
    })
    for (const each of allNodes) {
        // find the main piece
        if (each.type == "identifier" && each.text == "callPackage") {
            const index = each.nodeIndex
            // make sure the surrounding code matches the pattern
            if (
                each.nodeIndex <= 9 &&
                allNodes[index-9].type == "binding"             &&
                allNodes[index-8].type == "attrpath"            &&
                allNodes[index-7].type == "identifier"          &&
                allNodes[index-6].type == "whitespace"          &&
                allNodes[index-5].type == "="                   &&
                allNodes[index-4].type == "whitespace"          &&
                allNodes[index-3].type == "apply_expression"    &&
                allNodes[index-2].type == "apply_expression"    &&
                allNodes[index-1].type == "variable_expression" &&
                allNodes[index+1]?.type == "whitespace"         &&
                allNodes[index+2]?.type == "path_expression"    
                allNodes[index+3]?.type == "path_fragment"    
            ) {
                const relativePathFragment = allNodes[index+3].text
                let nodeToCopy = JSON.parse(JSON.stringify(allNodes[index-9]))
                // FIXME: finish copying the node, replace the name, replace the path
            }
        }
    }

    // binding_set
    //     binding
    //         attrpath
    //             identifier
    //         '='
    //         whitespace
    //         apply_expression
    //             apply_expression
    //                 variable_expression
    //                     identifier(callPackage)
    //                 whitespace
    //                 path_expression
    
}

// {
//     "typeId": 62,
//     "type": "source_code",
//     "startIndex": 1,
//     "endIndex": 213,
//     "children": [
//         {
//             "typeId": 68,
//             "type": "function_expression",
//             "startIndex": 1,
//             "endIndex": 212,
//             "children": [
//                 {
//                     "typeId": 2,
//                     "type": "identifier",
//                     "text": "self",
//                     "startIndex": 1,
//                     "endIndex": 5,
//                     "indent": ""
//                 },
//                 {
//                     "typeId": 8,
//                     "type": ":",
//                     "text": ":",
//                     "startIndex": 5,
//                     "endIndex": 6,
//                     "indent": ""
//                 },
//                 {
//                     "typeId": -1,
//                     "type": "whitespace",
//                     "text": " ",
//                     "startIndex": 6,
//                     "endIndex": 7,
//                     "indent": ""
//                 },
//                 {
//                     "typeId": 68,
//                     "type": "function_expression",
//                     "startIndex": 7,
//                     "endIndex": 212,
//                     "children": [
//                         {
//                             "typeId": 2,
//                             "type": "identifier",
//                             "text": "super",
//                             "startIndex": 7,
//                             "endIndex": 12,
//                             "indent": ""
//                         },
//                         {
//                             "typeId": 8,
//                             "type": ":",
//                             "text": ":",
//                             "startIndex": 12,
//                             "endIndex": 13,
//                             "indent": ""
//                         },
//                         {
//                             "typeId": -1,
//                             "type": "whitespace",
//                             "text": " ",
//                             "startIndex": 13,
//                             "endIndex": 14,
//                             "indent": ""
//                         },
//                         {
//                             "typeId": 72,
//                             "type": "with_expression",
//                             "startIndex": 14,
//                             "endIndex": 212,
//                             "children": [
//                                 {
//                                     "typeId": 17,
//                                     "type": "with",
//                                     "text": "with",
//                                     "startIndex": 14,
//                                     "endIndex": 18,
//                                     "indent": ""
//                                 },
//                                 {
//                                     "typeId": -1,
//                                     "type": "whitespace",
//                                     "text": " ",
//                                     "startIndex": 18,
//                                     "endIndex": 19,
//                                     "indent": ""
//                                 },
//                                 {
//                                     "typeId": 64,
//                                     "type": "variable_expression",
//                                     "startIndex": 19,
//                                     "endIndex": 23,
//                                     "children": [
//                                         {
//                                             "typeId": 2,
//                                             "type": "identifier",
//                                             "text": "self",
//                                             "startIndex": 19,
//                                             "endIndex": 23,
//                                             "indent": ""
//                                         }
//                                     ],
//                                     "indent": ""
//                                 },
//                                 {
//                                     "typeId": 16,
//                                     "type": ";",
//                                     "text": ";",
//                                     "startIndex": 23,
//                                     "endIndex": 24,
//                                     "indent": ""
//                                 },
//                                 {
//                                     "typeId": -1,
//                                     "type": "whitespace",
//                                     "text": " ",
//                                     "startIndex": 24,
//                                     "endIndex": 25,
//                                     "indent": ""
//                                 },
//                                 {
//                                     "typeId": 86,
//                                     "type": "attrset_expression",
//                                     "startIndex": 25,
//                                     "endIndex": 212,
//                                     "children": [
//                                         {
//                                             "typeId": 10,
//                                             "type": "{",
//                                             "text": "{",
//                                             "startIndex": 25,
//                                             "endIndex": 26,
//                                             "indent": ""
//                                         },
//                                         {
//                                             "typeId": -1,
//                                             "type": "whitespace",
//                                             "text": "\n  ",
//                                             "startIndex": 26,
//                                             "endIndex": 29,
//                                             "indent": "  "
//                                         },
//                                         {
//                                             "typeId": 91,
//                                             "type": "binding_set",
//                                             "startIndex": 29,
//                                             "endIndex": 210,
//                                             "children": [
//                                                 {
//                                                     "typeId": 92,
//                                                     "type": "binding",
//                                                     "startIndex": 29,
//                                                     "endIndex": 89,
//                                                     "children": [
//                                                         {
//                                                             "typeId": 95,
//                                                             "type": "attrpath",
//                                                             "startIndex": 29,
//                                                             "endIndex": 34,
//                                                             "children": [
//                                                                 {
//                                                                     "typeId": 2,
//                                                                     "type": "identifier",
//                                                                     "text": "numpy",
//                                                                     "startIndex": 29,
//                                                                     "endIndex": 34,
//                                                                     "indent": "  "
//                                                                 }
//                                                             ],
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": -1,
//                                                             "type": "whitespace",
//                                                             "text": " ",
//                                                             "startIndex": 34,
//                                                             "endIndex": 35,
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": 49,
//                                                             "type": "=",
//                                                             "text": "=",
//                                                             "startIndex": 35,
//                                                             "endIndex": 36,
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": -1,
//                                                             "type": "whitespace",
//                                                             "text": " ",
//                                                             "startIndex": 36,
//                                                             "endIndex": 37,
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": 81,
//                                                             "type": "apply_expression",
//                                                             "startIndex": 37,
//                                                             "endIndex": 88,
//                                                             "children": [
//                                                                 {
//                                                                     "typeId": 81,
//                                                                     "type": "apply_expression",
//                                                                     "startIndex": 37,
//                                                                     "endIndex": 84,
//                                                                     "children": [
//                                                                         {
//                                                                             "typeId": 64,
//                                                                             "type": "variable_expression",
//                                                                             "startIndex": 37,
//                                                                             "endIndex": 48,
//                                                                             "children": [
//                                                                                 {
//                                                                                     "typeId": 2,
//                                                                                     "type": "identifier",
//                                                                                     "text": "callPackage",
//                                                                                     "startIndex": 37,
//                                                                                     "endIndex": 48,
//                                                                                     "indent": "  "
//                                                                                 }
//                                                                             ],
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": -1,
//                                                                             "type": "whitespace",
//                                                                             "text": " ",
//                                                                             "startIndex": 48,
//                                                                             "endIndex": 49,
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": 65,
//                                                                             "type": "path_expression",
//                                                                             "startIndex": 49,
//                                                                             "endIndex": 84,
//                                                                             "children": [
//                                                                                 {
//                                                                                     "typeId": 59,
//                                                                                     "type": "path_fragment",
//                                                                                     "text": "../development/python-modules/numpy",
//                                                                                     "startIndex": 49,
//                                                                                     "endIndex": 84,
//                                                                                     "indent": "  "
//                                                                                 }
//                                                                             ],
//                                                                             "indent": "  "
//                                                                         }
//                                                                     ],
//                                                                     "indent": "  "
//                                                                 },
//                                                                 {
//                                                                     "typeId": -1,
//                                                                     "type": "whitespace",
//                                                                     "text": " ",
//                                                                     "startIndex": 84,
//                                                                     "endIndex": 85,
//                                                                     "indent": "  "
//                                                                 },
//                                                                 {
//                                                                     "typeId": 86,
//                                                                     "type": "attrset_expression",
//                                                                     "startIndex": 85,
//                                                                     "endIndex": 88,
//                                                                     "children": [
//                                                                         {
//                                                                             "typeId": 10,
//                                                                             "type": "{",
//                                                                             "text": "{",
//                                                                             "startIndex": 85,
//                                                                             "endIndex": 86,
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": -1,
//                                                                             "type": "whitespace",
//                                                                             "text": " ",
//                                                                             "startIndex": 86,
//                                                                             "endIndex": 87,
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": 11,
//                                                                             "type": "}",
//                                                                             "text": "}",
//                                                                             "startIndex": 87,
//                                                                             "endIndex": 88,
//                                                                             "indent": "  "
//                                                                         }
//                                                                     ],
//                                                                     "indent": "  "
//                                                                 }
//                                                             ],
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": 16,
//                                                             "type": ";",
//                                                             "text": ";",
//                                                             "startIndex": 88,
//                                                             "endIndex": 89,
//                                                             "indent": "  "
//                                                         }
//                                                     ],
//                                                     "indent": ""
//                                                 },
//                                                 {
//                                                     "typeId": -1,
//                                                     "type": "whitespace",
//                                                     "text": "\n  ",
//                                                     "startIndex": 89,
//                                                     "endIndex": 92,
//                                                     "indent": "  "
//                                                 },
//                                                 {
//                                                     "typeId": 92,
//                                                     "type": "binding",
//                                                     "startIndex": 92,
//                                                     "endIndex": 166,
//                                                     "children": [
//                                                         {
//                                                             "typeId": 95,
//                                                             "type": "attrpath",
//                                                             "startIndex": 92,
//                                                             "endIndex": 102,
//                                                             "children": [
//                                                                 {
//                                                                     "typeId": 2,
//                                                                     "type": "identifier",
//                                                                     "text": "numpy_Args",
//                                                                     "startIndex": 92,
//                                                                     "endIndex": 102,
//                                                                     "indent": "  "
//                                                                 }
//                                                             ],
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": -1,
//                                                             "type": "whitespace",
//                                                             "text": " ",
//                                                             "startIndex": 102,
//                                                             "endIndex": 103,
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": 49,
//                                                             "type": "=",
//                                                             "text": "=",
//                                                             "startIndex": 103,
//                                                             "endIndex": 104,
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": -1,
//                                                             "type": "whitespace",
//                                                             "text": " ",
//                                                             "startIndex": 104,
//                                                             "endIndex": 105,
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": 81,
//                                                             "type": "apply_expression",
//                                                             "startIndex": 105,
//                                                             "endIndex": 165,
//                                                             "children": [
//                                                                 {
//                                                                     "typeId": 81,
//                                                                     "type": "apply_expression",
//                                                                     "startIndex": 105,
//                                                                     "endIndex": 161,
//                                                                     "children": [
//                                                                         {
//                                                                             "typeId": 64,
//                                                                             "type": "variable_expression",
//                                                                             "startIndex": 105,
//                                                                             "endIndex": 116,
//                                                                             "children": [
//                                                                                 {
//                                                                                     "typeId": 2,
//                                                                                     "type": "identifier",
//                                                                                     "text": "callPackage",
//                                                                                     "startIndex": 105,
//                                                                                     "endIndex": 116,
//                                                                                     "indent": "  "
//                                                                                 }
//                                                                             ],
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": -1,
//                                                                             "type": "whitespace",
//                                                                             "text": " ",
//                                                                             "startIndex": 116,
//                                                                             "endIndex": 117,
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": 65,
//                                                                             "type": "path_expression",
//                                                                             "startIndex": 117,
//                                                                             "endIndex": 161,
//                                                                             "children": [
//                                                                                 {
//                                                                                     "typeId": 59,
//                                                                                     "type": "path_fragment",
//                                                                                     "text": "../development/python-modules/numpy/args.nix",
//                                                                                     "startIndex": 117,
//                                                                                     "endIndex": 161,
//                                                                                     "indent": "  "
//                                                                                 }
//                                                                             ],
//                                                                             "indent": "  "
//                                                                         }
//                                                                     ],
//                                                                     "indent": "  "
//                                                                 },
//                                                                 {
//                                                                     "typeId": -1,
//                                                                     "type": "whitespace",
//                                                                     "text": " ",
//                                                                     "startIndex": 161,
//                                                                     "endIndex": 162,
//                                                                     "indent": "  "
//                                                                 },
//                                                                 {
//                                                                     "typeId": 86,
//                                                                     "type": "attrset_expression",
//                                                                     "startIndex": 162,
//                                                                     "endIndex": 165,
//                                                                     "children": [
//                                                                         {
//                                                                             "typeId": 10,
//                                                                             "type": "{",
//                                                                             "text": "{",
//                                                                             "startIndex": 162,
//                                                                             "endIndex": 163,
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": -1,
//                                                                             "type": "whitespace",
//                                                                             "text": " ",
//                                                                             "startIndex": 163,
//                                                                             "endIndex": 164,
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": 11,
//                                                                             "type": "}",
//                                                                             "text": "}",
//                                                                             "startIndex": 164,
//                                                                             "endIndex": 165,
//                                                                             "indent": "  "
//                                                                         }
//                                                                     ],
//                                                                     "indent": "  "
//                                                                 }
//                                                             ],
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": 16,
//                                                             "type": ";",
//                                                             "text": ";",
//                                                             "startIndex": 165,
//                                                             "endIndex": 166,
//                                                             "indent": "  "
//                                                         }
//                                                     ],
//                                                     "indent": "  "
//                                                 },
//                                                 {
//                                                     "typeId": -1,
//                                                     "type": "whitespace",
//                                                     "text": "\n  ",
//                                                     "startIndex": 166,
//                                                     "endIndex": 169,
//                                                     "indent": "  "
//                                                 },
//                                                 {
//                                                     "typeId": 92,
//                                                     "type": "binding",
//                                                     "startIndex": 169,
//                                                     "endIndex": 210,
//                                                     "children": [
//                                                         {
//                                                             "typeId": 95,
//                                                             "type": "attrpath",
//                                                             "startIndex": 169,
//                                                             "endIndex": 176,
//                                                             "children": [
//                                                                 {
//                                                                     "typeId": 2,
//                                                                     "type": "identifier",
//                                                                     "text": "gitsrht",
//                                                                     "startIndex": 169,
//                                                                     "endIndex": 176,
//                                                                     "indent": "  "
//                                                                 }
//                                                             ],
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": -1,
//                                                             "type": "whitespace",
//                                                             "text": " ",
//                                                             "startIndex": 176,
//                                                             "endIndex": 177,
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": 49,
//                                                             "type": "=",
//                                                             "text": "=",
//                                                             "startIndex": 177,
//                                                             "endIndex": 178,
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": -1,
//                                                             "type": "whitespace",
//                                                             "text": " ",
//                                                             "startIndex": 178,
//                                                             "endIndex": 179,
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": 81,
//                                                             "type": "apply_expression",
//                                                             "startIndex": 179,
//                                                             "endIndex": 209,
//                                                             "children": [
//                                                                 {
//                                                                     "typeId": 81,
//                                                                     "type": "apply_expression",
//                                                                     "startIndex": 179,
//                                                                     "endIndex": 205,
//                                                                     "children": [
//                                                                         {
//                                                                             "typeId": 83,
//                                                                             "type": "select_expression",
//                                                                             "startIndex": 179,
//                                                                             "endIndex": 195,
//                                                                             "children": [
//                                                                                 {
//                                                                                     "typeId": 64,
//                                                                                     "type": "variable_expression",
//                                                                                     "startIndex": 179,
//                                                                                     "endIndex": 183,
//                                                                                     "children": [
//                                                                                         {
//                                                                                             "typeId": 2,
//                                                                                             "type": "identifier",
//                                                                                             "text": "self",
//                                                                                             "startIndex": 179,
//                                                                                             "endIndex": 183,
//                                                                                             "indent": "  "
//                                                                                         }
//                                                                                     ],
//                                                                                     "indent": "  "
//                                                                                 },
//                                                                                 {
//                                                                                     "typeId": 39,
//                                                                                     "type": ".",
//                                                                                     "text": ".",
//                                                                                     "startIndex": 183,
//                                                                                     "endIndex": 184,
//                                                                                     "indent": "  "
//                                                                                 },
//                                                                                 {
//                                                                                     "typeId": 95,
//                                                                                     "type": "attrpath",
//                                                                                     "startIndex": 184,
//                                                                                     "endIndex": 195,
//                                                                                     "children": [
//                                                                                         {
//                                                                                             "typeId": 2,
//                                                                                             "type": "identifier",
//                                                                                             "text": "callPackage",
//                                                                                             "startIndex": 184,
//                                                                                             "endIndex": 195,
//                                                                                             "indent": "  "
//                                                                                         }
//                                                                                     ],
//                                                                                     "indent": "  "
//                                                                                 }
//                                                                             ],
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": -1,
//                                                                             "type": "whitespace",
//                                                                             "text": " ",
//                                                                             "startIndex": 195,
//                                                                             "endIndex": 196,
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": 65,
//                                                                             "type": "path_expression",
//                                                                             "startIndex": 196,
//                                                                             "endIndex": 205,
//                                                                             "children": [
//                                                                                 {
//                                                                                     "typeId": 59,
//                                                                                     "type": "path_fragment",
//                                                                                     "text": "./git.nix",
//                                                                                     "startIndex": 196,
//                                                                                     "endIndex": 205,
//                                                                                     "indent": "  "
//                                                                                 }
//                                                                             ],
//                                                                             "indent": "  "
//                                                                         }
//                                                                     ],
//                                                                     "indent": "  "
//                                                                 },
//                                                                 {
//                                                                     "typeId": -1,
//                                                                     "type": "whitespace",
//                                                                     "text": " ",
//                                                                     "startIndex": 205,
//                                                                     "endIndex": 206,
//                                                                     "indent": "  "
//                                                                 },
//                                                                 {
//                                                                     "typeId": 86,
//                                                                     "type": "attrset_expression",
//                                                                     "startIndex": 206,
//                                                                     "endIndex": 209,
//                                                                     "children": [
//                                                                         {
//                                                                             "typeId": 10,
//                                                                             "type": "{",
//                                                                             "text": "{",
//                                                                             "startIndex": 206,
//                                                                             "endIndex": 207,
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": -1,
//                                                                             "type": "whitespace",
//                                                                             "text": " ",
//                                                                             "startIndex": 207,
//                                                                             "endIndex": 208,
//                                                                             "indent": "  "
//                                                                         },
//                                                                         {
//                                                                             "typeId": 11,
//                                                                             "type": "}",
//                                                                             "text": "}",
//                                                                             "startIndex": 208,
//                                                                             "endIndex": 209,
//                                                                             "indent": "  "
//                                                                         }
//                                                                     ],
//                                                                     "indent": "  "
//                                                                 }
//                                                             ],
//                                                             "indent": "  "
//                                                         },
//                                                         {
//                                                             "typeId": 16,
//                                                             "type": ";",
//                                                             "text": ";",
//                                                             "startIndex": 209,
//                                                             "endIndex": 210,
//                                                             "indent": "  "
//                                                         }
//                                                     ],
//                                                     "indent": "  "
//                                                 }
//                                             ],
//                                             "indent": "  "
//                                         },
//                                         {
//                                             "typeId": -1,
//                                             "type": "whitespace",
//                                             "text": "\n",
//                                             "startIndex": 210,
//                                             "endIndex": 211,
//                                             "indent": ""
//                                         },
//                                         {
//                                             "typeId": 11,
//                                             "type": "}",
//                                             "text": "}",
//                                             "startIndex": 211,
//                                             "endIndex": 212,
//                                             "indent": ""
//                                         }
//                                     ],
//                                     "indent": ""
//                                 }
//                             ],
//                             "indent": ""
//                         }
//                     ],
//                     "indent": ""
//                 }
//             ],
//             "indent": ""
//         }
//     ]
// }