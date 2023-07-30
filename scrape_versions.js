import { FileSystem } from "https://deno.land/x/quickr@0.6.36/main/file_system.js"
import { Console, clearAnsiStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, strikethrough, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.6.36/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString, regex, escapeRegexMatch, escapeRegexReplace, extractFirst, isValidIdentifier } from "https://deno.land/x/good@1.4.4.1/string.js"
import { BinaryHeap, ascend, descend } from "https://deno.land/x/good@1.4.4.1/binary_heap.js"


// idea:
    // pull nixpkgs commit
    // use static analysis to find the quantity of packages (look for attrsets with version and name attribute)
    // then iterate till at least all static-analysis packages have been found

const waitTime = 100 // miliections

/**
 * @example
 *     var { runNixCommand, practicalRunNixCommand, send, write } = createNixCommandRunner(`aa0e8072a57e879073cee969a780e586dbe57997`)
 */
function createNixCommandRunner(nixpkgsHash) {
    // saftey/cleaning
    nixpkgsHash = nixpkgsHash.replace(/[^a-fA-F0-9]/g,"").toLowerCase()

    // 
    // setup subprocess
    // 
        var command = new Deno.Command(
            `nix`,
            {
                args: [`repl`, `-I`, `nixpkgs=https://github.com/NixOS/nixpkgs/archive/${nixpkgsHash}.tar.gz`],
                stdin: 'piped',
                stdout: 'piped',
                stderr: 'piped' 
            }
        )
        var child = command.spawn()
        var stdin = child.stdin.getWriter()
        var write = (text)=>stdin.write( new TextEncoder().encode(text) )
        var send = (text)=>stdin.write( new TextEncoder().encode(text+"\n") )



    // 
    // stdout
    // 
        var stdout = child.stdout.getReader()
        var stdoutRead = ()=>stdout.read().then(({value, done})=>new TextDecoder().decode(value))
        var stdoutTextBuffer = ""
        ;((async ()=>{
            while (true) {
                stdoutTextBuffer += await stdoutRead()
            }
        })())
        let prevStdoutIndex = 0
        // returns all text since last grab
        var grabStdout = ()=>{
            const output = stdoutTextBuffer
            stdoutTextBuffer = ""
            return output
        }

    // 
    // stderr
    // 
        var stderr = child.stderr.getReader()
        var stderrRead = ()=>stderr.read().then(({value, done})=>new TextDecoder().decode(value))
        var stderrTextBuffer = ""
        ;((async ()=>{
            while (true) {
                stderrTextBuffer += await stderrRead()
            }
        })())
        let prevStderrIndex = 0
        // returns all text since last grab
        var grabStderr = ()=>{
            const output = stderrTextBuffer
            stderrTextBuffer = ""
            return output
        }

    // 
    // repl helper
    // 
        const commonStderrStartString = `Failed tcsetattr(TCSADRAIN): Inappropriate ioctl for device\n`
        async function runNixCommand(command) {
            var bigRandomStartInt = `${Math.random()}`.replace(".","").replace(/^0*/,"")
            var bigRandomEndInt = `${Math.random()}`.replace(".","").replace(/^0*/,"")
            await send(`builtins.trace "${bigRandomStartInt}" "${bigRandomStartInt}"`)
            await send(command)
            await send(`builtins.trace "${bigRandomEndInt}" "${bigRandomEndInt}"`)
            const fullMessagePattern = regex`${/[\w\W]*/}${bigRandomStartInt}${/([\w\W]*)/}${bigRandomEndInt}${/[\w\W]*/}`
            const fullMessagePatternStdout = regex`[\\w\\W]*"${bigRandomStartInt}"\\u001b\\[0m${/\n\n([\w\W]*)\n/}\\u001b\\[35;1m"${bigRandomEndInt}${/[\w\W]*/}`
            const fullMessagePatternStderr = regex`${/[\w\W]*/}${bigRandomStartInt}${/\n([\w\W]*)/}(?:\\n?${commonStderrStartString})?trace: ${bigRandomEndInt}${/[\w\W]*/}`
            let stdoutText = ""
            let stderrText = ""
            // accumulate all the text for this particular command
            while (true) {
                const stdoutIsDone = stdoutText.match(fullMessagePattern)
                const stderrIsDone = stderrText.match(fullMessagePattern)
                if (stdoutIsDone && stderrIsDone) {
                    break
                }
                if (!stdoutIsDone) {
                    stdoutText += grabStdout()
                }
                if (!stderrIsDone) {
                    stderrText += grabStderr()
                }
                await new Promise((resolve, reject)=>setTimeout(resolve, waitTime))
            }
            return {
                stdout: stdoutText.replace(fullMessagePatternStdout, "$1"),
                stderr: stderrText.replace(fullMessagePatternStderr, "$1"),
            }
        }
    

    const purgeWarnings = regex`(^(?:${commonStderrStartString})+|(?:${commonStderrStartString})+$)`.g
    async function practicalRunNixCommand(command) {
        const { stdout, stderr } = await runNixCommand(command)
        return {
            stdout: clearAnsiStylesFrom(stdout).replace(/\n*$/,""),
            stderr: stderr.replace(purgeWarnings, "").replace(/\n$/,""),
        }
    }

    return { runNixCommand, practicalRunNixCommand, send, write }
}

var escapeNixString = (string)=>{
    return `"${string.replace(/\$\{|[\\"]/g, '\\$&').replace(/\u0000/g, '\\0')}"`
}

/**
 * @example
 *     await getAttrNames(["builtins", "nixVersion"], practicalRunNixCommand)
 *     // [] 
 *     // non-attrset values return empty lists
 * 
 *     await getAttrNames("builtins", practicalRunNixCommand)
 *     // [ "abort", "add", "addErrorContext", ... ]
 *
 *     await getAttrNames(["builtins"], practicalRunNixCommand)
 *     // [ "abort", "add", "addErrorContext", ... ]
 *
 */
async function getAttrNames(attrList, practicalRunNixCommand) {
    if (typeof attrList == 'string') {
        attrList = [attrList]
    }
    let attrString
    if (attrList.length == 1) {
        attrString = attrList[0]
    } else {
        attrString = attrList[0]+"."+(attrList.slice(1,).map(escapeNixString).join("."))
    }
    const command = `
        (builtins.trace
            (
                if
                    (builtins.isAttrs (${attrString}))
                then 
                    (builtins.toJSON
                        (builtins.attrNames
                            (${attrString})
                        )
                    )
                else
                    (builtins.toJSON [])
            )
            null
        )
    `
    const { stdout, stderr } = await practicalRunNixCommand(command)
    try {
        return JSON.parse(stderr.replace(/^trace: /,""))
    } catch (error) {
        throw Error(`
            getAttrNames failed under the following conditions:
                attrList: ${indent({ string:  toRepresentation(attrList), by: "                ", noLead: true })}
                command: ${indent({ string:  toRepresentation(command), by: "                ", noLead: true })}
                stdout: ${indent({ string:  toRepresentation(stdout), by: "                ", noLead: true })}
                stderr: ${indent({ string:  toRepresentation(stderr), by: "                ", noLead: true })}
        `)
    }
}

const attrNameCount = {}
class Node {
    packageId = undefined
    attrName = ""
    depth = 0
    parent = null
    hitError = false
    children = {}
    constructor(values) {
        Object.assign(this, values)
        attrNameCount[this.attrName] = attrNameCount[this.attrName]+1 || 1
    }
    // this is a getter to help with memory usage
    get attrPath() {
        let parent = this.parent
        const attrPath = [ this.attrName ]
        while (parent) {
            attrPath.push(parent.attrName)
            parent = parent.parent
        }
        return attrPath.reverse()
    }
    toJSON() {
        return {
            packageId: this.packageId,
            attrName: this.attrName,
            depth: this.depth,
            hitError: this.hitError,
            attrPath: this.attrPath,
        }
    }
}

var rootNode
var _binaryHeap
async function* attrTreeIterator(workers) {
    const root = rootNode = new Node({
        attrName: `pkgs`,
        depth:0,
        parent: null,
    })
    const branchesToExplore = _binaryHeap = new BinaryHeap(
        // if a name is really common (ex: "out") it gets deprioritized heavily
        (a,b)=>ascend(
            attrNameCount[a.attrName]*a.depth,
            attrNameCount[b.attrName]*b.depth,
        )
    )
    branchesToExplore.push(root)
    while (branchesToExplore.length > 0 || workers.some(each=>each.isBusy)) {
        // wait for workers to add to que, or wait for workers to become available
        if (branchesToExplore.length == 0 || workers.every(each=>each.isBusy)) {
            // console.log(`waiting because:`)
            // console.debug(`    branchesToExplore.length is:`,branchesToExplore.length)
            // console.debug(`    workers.every(each=>each.isBusy) is:`,workers.every(each=>each.isBusy))
            // console.debug(`    workers.map(each=>each.isBusy) is:`,workers.map(each=>each.isBusy))
            await new Promise((resolve, reject)=>setTimeout(resolve, waitTime))
            continue
        }
        // assign some work
        const currentNode = branchesToExplore.pop()
        for (const eachWorker of workers) {
            if (!eachWorker.isBusy) {
                eachWorker.getAttrNames(currentNode.attrPath).then(
                    names=>{
                        for (const attrName of names) {
                            branchesToExplore.push(
                                currentNode.children[attrName] = new Node({
                                    attrName,
                                    depth: currentNode.depth + 1,
                                    parent: currentNode,
                                })
                            )
                        }
                    }
                ).catch(
                    error=>{
                        currentNode.hitError = `${error}`
                    }
                )
                // only need one worker
                break
            }
        }
        yield currentNode
    }
}

class Worker {
    static all = []
    constructor(nixpkgsHash) {
        this.isBusy = true
        Object.assign(this, createNixCommandRunner(nixpkgsHash))
        this.send(`pkgs = import <nixpkgs> {}`).then(()=>{
            this.isBusy = false
            console.log(`worker${this.index} has initalized`)
        })
        this.index = Worker.all.length
        console.log(`worker${this.index} created`)
        Worker.all.push(this)
    }
    async getAttrNames(attrList) {
        this.isBusy = true
        try {
            // console.log(`worker ${this.index} is working on a job`)
            const output = await getAttrNames(attrList, this.practicalRunNixCommand)
            // console.log(`worker ${this.index} is finished job`)
            return output
        } finally {
            this.isBusy = false
        }
    }
}

const stdoutLogRate = 500 // every __ miliseconds
const nodeListOutputPath = "attr_tree.yaml"
const numberOfParallelNixProcesses = 40
var nixpkgsHash = `aa0e8072a57e879073cee969a780e586dbe57997`
const workers = [...Array(numberOfParallelNixProcesses)].map(each=>new Worker(nixpkgsHash))
const startTime = (new Date()).getTime()
let numberOfNodes = 0

// logging
setInterval(() => {
    const currentTime = (new Date()).getTime()
    Deno.stdout.write(new TextEncoder().encode(`nodeCount: ${numberOfNodes}, _binaryHeap: ${_binaryHeap.length}, spending ${Math.round((currentTime-startTime)/numberOfNodes)}ms per node                                     \r`))
}, stdoutLogRate)

// file writing
let buffer = ""
await FileSystem.ensureIsFolder(FileSystem.parentPath(nodeListOutputPath))
const file = await Deno.open(nodeListOutputPath, {read:true, write: true, create: true})
await file.seek(0, Deno.SeekMode.End)
setInterval(() => {
    const currentTime = (new Date()).getTime()
    Deno.stdout.write(new TextEncoder().encode(`nodeCount: ${numberOfNodes}, _binaryHeap: ${_binaryHeap.length}, spending ${Math.round((currentTime-startTime)/numberOfNodes)}ms per node                                     \r`))
    file.write(new TextEncoder().encode(buffer))
    buffer = ""
}, stdoutLogRate)

for await (const eachNode of attrTreeIterator(workers)) {
    numberOfNodes ++ 
    buffer += `- ${JSON.stringify(eachNode)}\n`
}
await file.close()