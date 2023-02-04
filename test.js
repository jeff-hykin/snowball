import { parse } from "./fornix/support/nix_parser.bundle.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.8/string.js"
import { FileSystem } from "https://deno.land/x/quickr@0.6.16/main/file_system.js"

var nixStuff = Deno.readTextFileSync("fornix/documentation/snowball_format.nix")
var nixStuff = Deno.readTextFileSync("/Users/jeffhykin/repos/nix-ros-overlay/distros/rolling/velodyne-driver/default.nix")
var nixStuff = Deno.readTextFileSync("/Users/jeffhykin/repos/nixpkgs/pkgs/stdenv/darwin/default.nix")


function nodeList(node) {
    return [ node, ...(node.children||[]).map(nodeList) ].flat(Infinity)
}

var realParse = (string)=>{
    const tree = parse(string)
    const rootNode = tree.rootNode
    Object.defineProperties(tree, {
        rootNode: {
            get() {
                return rootNode
            }
        }
    })
    const allNodes = nodeList(tree.rootNode)
    let indent = ""
    // mutate nodes
    for (const eachNode of allNodes) {
        if (eachNode.children.length) {
            const newChildren = []
            const childrenCopy = [...eachNode.children]
            let firstChild = childrenCopy.shift()
            // preceding whitespace
            if (eachNode.startIndex != firstChild.startIndex) {
                const whitespaceText = string.slice(eachNode.startIndex, firstChild.startIndex)
                if (whitespaceText.match(/\n/)) {
                    indent = whitespaceText.split(/\n/).slice(-1)[0]
                }
                newChildren.push({
                    typeId: -1,
                    type: "whitespace",
                    text: whitespaceText,
                    startIndex: eachNode.startIndex,
                    endIndex: firstChild.startIndex,
                    indent,
                })
            }
            firstChild.indent = indent
            newChildren.push(firstChild)
            // gaps between sibilings
            let prevChild = firstChild
            for (const eachSecondaryNode of childrenCopy) {
                if (prevChild.endIndex != eachSecondaryNode.startIndex) {
                    const whitespaceText = string.slice(prevChild.endIndex, eachSecondaryNode.startIndex)
                    if (whitespaceText.match(/\n/)) {
                        indent = whitespaceText.split(/\n/).slice(-1)[0]
                    }
                    newChildren.push({
                        typeId: -1,
                        type: "whitespace",
                        text: whitespaceText,
                        startIndex: prevChild.endIndex,
                        endIndex: eachSecondaryNode.startIndex,
                        indent,
                    })
                }
                eachSecondaryNode.indent = indent
                newChildren.push(eachSecondaryNode)
                prevChild = eachSecondaryNode
            }
            
            // 
            // inject whitespace "nodes"
            // 
            Object.defineProperties(eachNode, {
                children: {
                    get() {
                        return newChildren
                    }
                }
            })
        }
    }
    return tree
}

var nodeAsJsonObject = (node)=>{
    if (node.children && node.children.length) {
        return {
            typeId: node.typeId,
            type: node.type,
            startIndex: node.startIndex,
            endIndex: node.endIndex,
            children: node.children.map(each=>nodeAsJsonObject(each)),
            indent: node.indent,
        }
    } else {
        return {
            typeId: node.typeId,
            type: node.type,
            text: node.text,
            startIndex: node.startIndex,
            endIndex: node.endIndex,
            indent: node.indent,
        }
    }
}

function nix2json(path) {
    return nodeAsJsonObject(realParse(Deno.readTextFileSync(path)).rootNode)
}

function json2Nix(jsonTree) {
    return nodeList(jsonTree).map(each=>each.text||"").join("")
}

// console.log(JSON.stringify( nodeAsJsonObject(realParse(" { lib}: 10").rootNode),0,4))

function getInputs(path) {
    const tree = realParse(Deno.readTextFileSync(path))
    let indent = ""
    for (const each of tree.rootNode.children) {
        if (each.type == "function_expression" && each.children.length) {
            const parameterAreas = each.children.filter(each=>each.type == "formals")
            if (parameterAreas.length > 0 && parameterAreas[0].children.length) {
                const parameterNodes = parameterAreas[0].children
                return parameterNodes.filter(
                        eachParameterNode=>eachParameterNode.type == "formal"
                    ).map(
                        // expession = "lib ? (thing.call {} 'whatever')"
                        // identifier = "lib"
                        eachParameterExpression=>eachParameterExpression.children.filter(
                            eachLiteral=>eachLiteral.type == "identifier"
                        )[0].text
                    )
            }
        }
    }
}

// const baseIndentSize = 2
// async function format(path) {
//     const string = await FileSystem.read(path)
//     if (!string) {
//         throw Error(`${FileSystem.normalize(path)} doesn't contain anything`)
//     }
//     const tree = realParse(string)
//     const jsonableTree = nodeAsJsonObject(tree.rootNode)
//     function innerFormat(node, runningIndentSize=0) {
//         const indent = "\n"+(" ".repeat(runningIndentSize))
//         // change the whitespace nodes
//         if (node.type == "whitespace") {
//             node.text = node.text.replace(/\n */g,indent)
//             return node
//         // check if indent should be changed
//         } else if (node.type == "function_expression") {
//             if (node.children[0].type == "formals") {
//                 const parameterArea = node.children[0]
//                 // 
//                 // find {
//                 // 
//                 if (parameterArea.children && parameterArea.children.length) {
//                     const isAttributeFunction = parameterArea.children[0].type == "{"
//                     if (isAttributeFunction) {
//                         // remove trailing whitespace
//                         if (parameterArea.children[1]?.type == "whitespace") {
//                             parameterArea.children.splice(1,1)
//                         }
//                         // add formatted whitespace
//                         parameterArea.children.splice(1,0,{ type: "whitespace", text:indent })
//                         parameterArea.children.push({ type: "whitespace", text:indent })
//                         // format all the middle nodes
//                         parameterArea.children.slice(2,-1).map(each=>innerFormat(each, runningIndentSize+baseIndentSize))
//                     }
//                     let newChildren = []
//                     for (const each of node.children) {
//                         newChildren.push(each)
//                         if (each.text == ":") {
//                             newChildren.push({ type: "whitespace", text: "\n" })
//                         }
//                     }
//                     node.children = newChildren
//                     console.debug(`node.children is:`,node.children)
//                     node.children.slice(1).map(each=>innerFormat(each, runningIndentSize+baseIndentSize))
//                 }
//             }
//             return node
//         } else if (node.children && node.children.length) {
//             node.children.map(each=>innerFormat(each, runningIndentSize)) 
//             return node
//         } else {
//             return node
//         }
//     }
//     const newJsonableTree = innerFormat(jsonableTree)
//     return FileSystem.write({
//         path: path,
//         data: json2Nix(newJsonableTree),
//     })
// }

async function innerBundle(path, callStack=[]) {
    callStack = [...callStack] // local copy (dont mutate parent copy)
    callStack.push(path)
    
    const string = await FileSystem.read(path)
    if (!string) {
        throw Error(`${FileSystem.normalize(path)} doesn't contain anything`)
    }
    const tree = realParse(string)
    const jsonableTree = nodeAsJsonObject(tree.rootNode)
    const allNodes = nodeList(jsonableTree)
    const promises = []
    for (const eachNode of allNodes) {
        if (eachNode.children && eachNode.children.length >= 3) {
            const childrenTypes = eachNode.children.map(eachNode=>eachNode.type)
            // FIXME: this gets the first import, but its slightly possible for there to be multiple in the same set of children
            const indexOfVariableExpression = childrenTypes.indexOf("variable_expression")
            const indexOfPathExpression = childrenTypes.indexOf("path_expression")
            
            // confirm necessary outer structure
            if (
                indexOfVariableExpression >= 0
                && eachNode.children[indexOfVariableExpression + 1]
                && (eachNode.children[indexOfVariableExpression + 1]?.type == "whitespace")
                && indexOfVariableExpression + 2 == indexOfPathExpression
            ) {
                // confirm necessary inner structure for importing from relative path
                if (
                    (eachNode.children[indexOfVariableExpression]?.children||[{}])[0].type == "identifier" && 
                    (eachNode.children[indexOfVariableExpression]?.children||[{}])[0].text == "import" && 
                    (eachNode.children[indexOfPathExpression]?.children||[{}])[0].type == "path_fragment"
                ) {
                    const relativePath = eachNode.children[indexOfPathExpression].children[0].text
                    const rawTarget = `${FileSystem.parentPath(path)}/${relativePath}`
                    const infoForTarget = await FileSystem.info(rawTarget)
                    let realTargetPath = rawTarget
                    const replaceWithNull = (reason)=>{
                        const importPlusWhitespacePlusPathLiteral = 3
                        eachNode.children.splice(indexOfVariableExpression, importPlusWhitespacePlusPathLiteral, { text: `null /* ${reason}*/` })
                    }
                    if (!infoForTarget.exists) {
                        replaceWithNull(`doesnt exist: import ${FileSystem.normalize(rawTarget)}`)
                        console.warn(`import doesn't exist: ${JSON.stringify(FileSystem.normalize(rawTarget))}, search for: ${relativePath}, in ${callStack.slice(-1)[0]}`)
                        continue // no replacement
                    } else if (infoForTarget.isFolder) {
                        realTargetPath = `${rawTarget}/default.nix`
                        const infoForTarget = await FileSystem.info(realTargetPath)
                        if (!infoForTarget.exists) {
                            replaceWithNull(`doesnt exist: import ${FileSystem.normalize(realTargetPath)}`)
                            console.warn(`import doesn't exist: ${JSON.stringify(FileSystem.normalize(rawTarget))}, search for: ${relativePath}, in ${callStack.slice(-1)[0]}`)
                            continue // no replacement
                        }
                    }
                    realTargetPath = FileSystem.normalize(realTargetPath)
                    
                    if (callStack.includes(realTargetPath)) {
                        console.warn(`recursive import: ${relativePath}, import stack: ${JSON.stringify(callStack.concat([realTargetPath]))}`)
                        continue // no replacement
                    }

                    console.debug(`pulling in:`, realTargetPath)
                    promises.push(
                        innerBundle(realTargetPath, callStack).then(resultTree=>{
                            const indentedImport = indent({
                                string: json2Nix(resultTree),
                                by: eachNode.indent+"  ",
                            })
                            const wrappedImport = `(# ${JSON.stringify(realTargetPath)}\n${indentedImport}\n${eachNode.indent})`
                            const importPlusWhitespacePlusPathLiteral = 3
                            eachNode.children.splice(indexOfVariableExpression, importPlusWhitespacePlusPathLiteral, { text: wrappedImport })
                        })
                    )
                }
            }
        }
    }
    await Promise.all(promises)
    return jsonableTree
}

async function bundle(path) {
    let [ folders, name, ext ] = await FileSystem.pathPieces(path)
    await FileSystem.write({
        path: FileSystem.join(...folders)+`/${name}.bundle${ext}`,
        data: json2Nix(await innerBundle(path)),
    })
}

await bundle("./test.nix")
// await format("./test.nix")