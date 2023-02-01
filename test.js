import { parse } from "./fornix/support/nix_parser.bundle.js"
var nixStuff = Deno.readTextFileSync("fornix/documentation/snowball_format.nix")


function nodeList(node) {
    return [ node, ...node.children.map(nodeList) ].flat(Infinity)
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
                    console.debug(`${prevChild.endIndex} != ${eachSecondaryNode.startIndex}`,)
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
            const addedWhitespace = newChildren.length != eachNode.children.length
            Object.defineProperties(eachNode, {
                children: {
                    get() {
                        return newChildren
                    }
                }
            })
            if (addedWhitespace) {
                console.debug(`eachNode.children is:`,eachNode.children)
            }
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

// var tree = parse(nixStuff)
// console.log(JSON.stringify(nodeAsJsonObject(tree.rootNode),0,4))

var tree2 = realParse(nixStuff)
console.log(JSON.stringify(nodeAsJsonObject(tree2.rootNode),0,4))