import { parse } from "./fornix/support/nix_parser.bundle.js"
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
    // mutate nodes
    for (const eachNode of allNodes) {
        if (eachNode.children.length) {
            const newChildren = []
            const childrenCopy = [...eachNode.children]
            let firstChild = childrenCopy.shift()
            // preceding whitespace
            if (eachNode.startIndex != firstChild.startIndex) {
                newChildren.push({
                    typeId: -1,
                    type: "whitespace",
                    text: string.slice(eachNode.startIndex, firstChild.startIndex),
                    startIndex: eachNode.startIndex,
                    endIndex: firstChild.startIndex,
                })
            }
            newChildren.push(firstChild)
            // gaps between sibilings
            let prevChild = firstChild
            for (const eachSecondaryNode of childrenCopy) {
                if (prevChild.endIndex != eachSecondaryNode.startIndex) {
                    newChildren.push({
                        typeId: -1,
                        type: "whitespace",
                        text: string.slice(prevChild.endIndex, eachSecondaryNode.startIndex),
                        startIndex: prevChild.endIndex,
                        endIndex: eachSecondaryNode.startIndex,
                    })
                }
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
            children: node.children.map(each=>nodeAsJsonObject(each))
        }
    } else {
        return {
            typeId: node.typeId,
            type: node.type,
            text: node.text,
            startIndex: node.startIndex,
            endIndex: node.endIndex,
        }
    }
}

function nix2json(path) {
    return nodeAsJsonObject(realParse(Deno.readTextFileSync(path)).rootNode)
}

function json2Nix(jsonTree) {
    return nodeList(jsonTree).map(each=>each.text||"").join("")
}


function getInputs(path) {
    const tree = realParse(Deno.readTextFileSync(path))
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