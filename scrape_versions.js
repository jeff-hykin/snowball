import { FileSystem } from "https://deno.land/x/quickr@0.6.36/main/file_system.js"
import { Console, clearAnsiStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, strikethrough, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.6.36/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString, regex, escapeRegexMatch, escapeRegexReplace, extractFirst, isValidIdentifier } from "https://deno.land/x/good@1.4.4.1/string.js"
import { BinaryHeap, ascend, descend } from "https://deno.land/x/good@1.4.4.1/binary_heap.js"
import { deferredPromise } from "https://deno.land/x/good@1.4.4.1/async.js"
import { enumerate, count, zip, iter, next } from "https://deno.land/x/good@1.4.4.1/iterable.js"


// idea:
    // pull nixpkgs commit
    // use static analysis to find the quantity of packages (look for attrsets with version and name attribute)
    // then iterate till at least all static-analysis packages have been found

const waitTime = 100 // miliections
const stdoutLogRate = 500 // every __ miliseconds
const nodeListOutputPath = "attr_tree.yaml"
const numberOfParallelNixProcesses = 4
var nixpkgsHash = `aa0e8072a57e879073cee969a780e586dbe57997`
const estimatedNumberOfNodes = 500_000
const maxDepth = 8



const logLine = (...args)=>Deno.stdout.write(
    new TextEncoder().encode(
        `${args.map(each=>typeof each =='string'?each:toRepresentation(each)).join("")}`.padEnd(160," ")+"\r"
    )
)
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
        throw Error(stderr)
    }
}
// 
// node setup
// 
    let numberOfNodes = 0
    const nodePreAllocatedBuffer = []
    let remainingAllocations = estimatedNumberOfNodes
    while (remainingAllocations--) {
        nodePreAllocatedBuffer.push([null, ""])
    }
    const Parent = 0
    const Name = 1
    const createNode = (parent, name)=>{
        // if (typeof name != 'string') {
        //     throw Error(`createNode(${parent}, ${name}), name (2nd arg) needs to be a string`)
        // }
        if (numberOfNodes < estimatedNumberOfNodes) {
            const node = nodePreAllocatedBuffer[numberOfNodes]
            node[Parent] = parent
            node[Name] = name
            numberOfNodes+=1
            return node
        } else {
            return [parent, name]
        }
    }
    const getDepth = (node)=>{
        let depth = 0
        // follow the parent until the parent is null
        while (node[Parent] != null) {
            node = node[Parent]
            depth += 1
        }
        return depth
    }
    const getAttrPath = (node)=>{
        // console.debug(`node is:`,node)
        const attrPath = []
        // follow the parent until the parent is null
        while (node[Parent] != null) {
            attrPath.push(node[Name])
            node = node[Parent]
        }
        // console.debug(`getAttrPath is:`,attrPath)
        return attrPath
    }

// 
// workers
// 
    class Worker {
        static totalCount = 0
        constructor(nixpkgsHash) {
            this.index = Worker.totalCount
            Worker.totalCount += 1
            Object.assign(this, createNixCommandRunner(nixpkgsHash))
            this.taskFinished = deferredPromise()
            this.send(`pkgs = import <nixpkgs> {}`).then(()=>{
                this.taskFinished.resolve()
                console.log(`worker${this.index} has initalized`)
            })
            console.log(`worker${this.index} created`)
        }
        get isBusy() {
            return this.taskFinished.state=="pending"
        }
        async getAttrNames(attrList) {
            await this.taskFinished
            this.taskFinished = deferredPromise()
            try {
                // console.log(`worker ${this.index} is working on a job`)
                const attrPath = ["pkgs", ...attrList]
                // console.debug(`attrPath is:`,attrPath)
                const output = await getAttrNames(attrPath, this.practicalRunNixCommand)
                // console.log(`worker ${this.index} is finished job`)
                return output
            } finally {
                this.taskFinished.resolve()
            }
        }
    }

// 
// save system
// 
    let numberOfNodesProcessed = 0
    const individualIterCounts = {}
    const startTime = (new Date()).getTime()
    await FileSystem.ensureIsFolder(FileSystem.parentPath(nodeListOutputPath))
    const outputBuffer = []
    const savingSystem = {
        async flushBuffer() {
            const currentTime = (new Date()).getTime()
            try {
                await logLine(`nodeCount: ${numberOfNodesProcessed}, spending ${Math.round((currentTime-startTime)/numberOfNodesProcessed)}ms per node`)
                await savingSystem.mainLoggingFile.write(new TextEncoder().encode(outputBuffer.join("")))
            } catch (error) {
                console.debug(`error is:`,error)
            }
            outputBuffer.length = 0
        }
    }
    try {
        savingSystem.mainLoggingFile = await Deno.open(nodeListOutputPath, {read:true, write: true, create: true, append: true})
    } catch (error) {
        console.debug(`error is:`,error)
    }

// 
// 
// iterative deepening
// 
// 
    
    const workers = [...Array(numberOfParallelNixProcesses)].map(each=>new Worker(nixpkgsHash))
    const rootAttrNames = await workers[0].getAttrNames([])
    const frontierInitNodes = [...Array(numberOfParallelNixProcesses)].map(each=>[])
    for (const [index, eachAttrName] of enumerate(rootAttrNames)) {
        frontierInitNodes[index%numberOfParallelNixProcesses].push(
            createNode(null, eachAttrName)
        )
    }
    const iterators = []
    for (const [worker, initialFrontier] of zip(workers, frontierInitNodes)) {
        const workerId = `worker${worker.index}`
        individualIterCounts[workerId] = 0
        async function * exploreNodes() {
            let nextMaxDepth = 0
            while (nextMaxDepth+1 <= maxDepth) {
                nextMaxDepth += 1
                const depthLevels = [
                    initialFrontier,
                ]
                const getDeepestNode = ()=>{
                    let deepestNode
                    let deepestDepth = depthLevels.length-1
                    while (deepestDepth>=0) {
                        if (depthLevels[deepestDepth].length > 0) {
                            deepestNode = depthLevels[deepestDepth].pop()
                            break
                        }
                        deepestDepth-=1
                    }
                    return [deepestNode, deepestDepth]
                }
                while (1) {
                    const [ currentNode, nodeDepth ] = getDeepestNode()
                    if (currentNode == null) {
                        break
                    }
                    const currentTime = (new Date()).getTime()
                    yield currentNode
                    // logLine(`numberOfNodesProcessed:${numberOfNodesProcessed}, worker:${worker.index}, depth:${nodeDepth}, currentNodeName:${currentNode[Name]}`)
                    individualIterCounts[workerId] += 1
                    numberOfNodesProcessed += 1
                    await logLine(`individualIterCounts: ${JSON.stringify(individualIterCounts)}, worker:${worker.index}, yielding, numberOfNodesProcessed:${numberOfNodesProcessed}, spending ${Math.round((currentTime-startTime)/numberOfNodesProcessed)}ms per node`)
                    
                    
                    const attrPath = getAttrPath(currentNode)
                    // console.debug(`1st attrPath is:`,attrPath)
                    const childDepth = nodeDepth+1
                    const childrenAreTooDeep = childDepth > nextMaxDepth
                    let attrErr
                    let childNames
                    try {
                        // const startTime = (new Date()).getTime()
                        childNames = await worker.getAttrNames(attrPath)
                        // const endTime = (new Date()).getTime()
                        // const duration = endTime - startTime
                        // console.log(`worker.getAttrNames took ${duration}ms`)
                    } catch (error) {
                        // console.debug(`error is:`,error)
                        attrErr = error.message
                    }
                    // console.debug(`childNames is:`,childNames)
                    if (!childrenAreTooDeep && childNames) {
                        if (depthLevels[childDepth] == null) {
                            depthLevels[childDepth] = []
                        }
                        for (const eachChildName of childNames) {
                            // console.debug(`eachChildName is:`,eachChildName)
                            // console.debug(`childDepth is:`,childDepth)
                            depthLevels[childDepth].push(
                                createNode(currentNode, eachChildName)
                            )
                        }
                    }
                    
                    // only record at the depth that hasnt been seen before
                    if (nodeDepth == nextMaxDepth) {
                        // save data about this node
                        outputBuffer.push(
                            "- "+JSON.stringify([
                                attrPath, nodeDepth, childNames, attrErr,
                            ])
                        )
                        if (outputBuffer.length > 100) {
                            savingSystem.flushBuffer()
                        }
                    }
                }
            }
        }
        iterators.push(
            iter(exploreNodes())
        )
    }
    const unpackASAP = (source, promise)=>promise.then((()=>unpackASAP(source, next(source))))
    while (true) {
        await logLine(`individualIterCounts: ${JSON.stringify(individualIterCounts)}, numberOfNodesProcessed:${numberOfNodesProcessed}, spending ${Math.round(((new Date()).getTime()-startTime)/numberOfNodesProcessed)}ms per node`)
        iterators.map(each=>unpackASAP(each, next(each)))
    }