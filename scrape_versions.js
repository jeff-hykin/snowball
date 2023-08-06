import { FileSystem } from "https://deno.land/x/quickr@0.6.36/main/file_system.js"
import { Console, clearAnsiStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, strikethrough, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.6.36/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString, regex, escapeRegexMatch, escapeRegexReplace, extractFirst, isValidIdentifier } from "https://deno.land/x/good@1.4.4.1/string.js"
import { BinaryHeap, ascend, descend } from "https://deno.land/x/good@1.4.4.1/binary_heap.js"
import { deferredPromise } from "https://deno.land/x/good@1.4.4.1/async.js"
import { enumerate, count, zip, iter, next } from "https://deno.land/x/good@1.4.4.1/iterable.js"



const waitTime = 100 // miliections
const stdoutLogRate = 500 // every __ miliseconds
const nodeListOutputPath = "attr_tree.yaml"
const numberOfParallelNixProcesses = 40
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
        var stdoutTextBuffer = []
        ;((async ()=>{
            while (true) {
                const chunk = await stdoutRead()
                stdoutTextBuffer.push(chunk)
            }
        })())
        let prevStdoutIndex = 0
        // returns all text since last grab
        var grabStdout = ()=>{
            const output = stdoutTextBuffer.join("")
            stdoutTextBuffer = []
            return output
        }

    // 
    // stderr
    // 
        var stderr = child.stderr.getReader()
        var stderrRead = ()=>stderr.read().then(({value, done})=>new TextDecoder().decode(value))
        var stderrTextBuffer = []
        ;((async ()=>{
            while (true) {
                const chunk = await stderrRead()
                stderrTextBuffer.push(chunk)
            }
        })())
        let prevStderrIndex = 0
        // returns all text since last grab
        var grabStderr = ()=>{
            const output = stderrTextBuffer.join("")
            stderrTextBuffer = []
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
            const messageHasStartAndEnd = (message)=>{
                let index = 0
                for (const each of message) {
                    // console.debug(`message.slice(index, index+bigRandomStartInt.length) is:`, toRepresentation( message.slice(index, index+bigRandomStartInt.length)))
                    if (message.slice(index, index+bigRandomStartInt.length) == bigRandomStartInt) {
                        const startIndex = index+bigRandomStartInt.length
                        // console.debug(`startIndex is:`, toRepresentation( startIndex))
                        message = message.slice(startIndex,)
                        index = message.length
                        for (const each of message) {
                            // console.debug(`message.slice(index-bigRandomEndInt.length, index) is:`, toRepresentation( message.slice(index-bigRandomEndInt.length, index)))
                            if (message.slice(index-bigRandomEndInt.length, index) == bigRandomEndInt) {
                                const endIndex = startIndex+index-bigRandomEndInt.length
                                // console.debug(`endIndex is:`,endIndex)
                                return { startIndex, endIndex }
                            }
                            index--
                        }
                        // console.debug(`couldnt find ${bigRandomEndInt}`,)
                        return undefined
                    }
                    index++
                }
                // console.debug(`couldnt find ${bigRandomStartInt}`,)
            }
            // const fullMessagePattern = new RegExp(`${bigRandomStartInt}[\w\W]*${bigRandomEndInt}`)
            const fullMessagePatternStdout = regex`[\\w\\W]*"${bigRandomStartInt}"\\u001b\\[0m${/\n\n([\w\W]*)\n/}\\u001b\\[35;1m"${bigRandomEndInt}${/[\w\W]*/}`
            const fullMessagePatternStderr = regex`${/[\w\W]*/}${bigRandomStartInt}${/\n([\w\W]*)/}(?:\\n?${commonStderrStartString})?trace: ${bigRandomEndInt}${/[\w\W]*/}`
            let stdoutIsDone = false
            let stderrIsDone = false
            let stdoutText = ""
            let stderrText = ""
            // accumulate all the text for this particular command
            while (true) {
                // console.debug(`stdoutText is:`,stdoutText)
                stdoutIsDone = stdoutIsDone || messageHasStartAndEnd(stdoutText)
                // console.debug(`stderrText is:`,stderrText)
                stderrIsDone = stderrIsDone || messageHasStartAndEnd(stderrText)
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
            
            // console.debug(`stdout pre is:`, toRepresentation( stdoutText))
            let stdout = stdoutText.slice(stdoutIsDone.startIndex, stdoutIsDone.endIndex)
            var prefix = `"\u001b[0m\n\n`
            if (stdout.startsWith(prefix)) {
                stdout = stdout.slice(prefix.length,)
            }
            var postfix = `\n\u001b[35;1m"`
            if (stdout.endsWith(postfix)) {
                stdout = stdout.slice(0, -postfix.length)
            }


            // console.debug(`PRE stderrText.split("\\n") is:`,JSON.stringify(stderrText.split("\n"),0,4))
            let stderr = stderrText.slice(stderrIsDone.startIndex, stderrIsDone.endIndex)
            var prefix = `\n`
            if (stderr.startsWith(prefix)) {
                stderr = stderr.slice(prefix.length,)
            }
            var postfix = `trace: `
            if (stderr.endsWith(postfix)) {
                stderr = stderr.slice(0, -postfix.length)
            }

            // console.debug(`stdout core is:`, toRepresentation(stdout))
            // console.debug(`stderr core is:`, JSON.stringify(stderr.split("\n"),0,4))
            
            return {
                stdout,
                stderr,
            }
        }
    

    const purgeWarnings = regex`(^(?:${commonStderrStartString})+|(?:${commonStderrStartString})+$)`.g
    async function practicalRunNixCommand(command) {
        let { stdout, stderr } = await runNixCommand(command)
        stdout = clearAnsiStylesFrom(stdout).replace(/\n*$/,"")
        stderr = stderr.replace(purgeWarnings, "").replace(/\n$/,"")
        // console.debug(`stdout post is:`, toRepresentation(stdout))
        // console.debug(`stderr post is:`, toRepresentation(stderr))
        return {
            stdout,
            stderr,
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
        // // console.debug(`node is:`,node)
        const attrPath = [
            node[Name]
        ]
        // follow the parent until the parent is null
        while (node[Parent] != null) {
            node = node[Parent]
            attrPath.push(node[Name])
        }
        // // console.debug(`getAttrPath is:`,attrPath)
        return attrPath.reverse()
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
            // await this.taskFinished
            // this.taskFinished = deferredPromise()
            try {
                // console.log(`worker ${this.index} is working on a job`)
                const attrPath = ["pkgs", ...attrList]
                // // console.debug(`attrPath is:`,attrPath)
                const output = await getAttrNames(attrPath, this.practicalRunNixCommand)
                // console.log(`worker ${this.index} is finished job`)
                return output
            } finally {
                // this.taskFinished.resolve()
            }
        }
    }

// 
// save system
// 
    await FileSystem.remove(nodeListOutputPath)
    let numberOfNodesProcessed = 0
    const individualIterCounts = {}
    const startTime = (new Date()).getTime()
    await FileSystem.ensureIsFolder(FileSystem.parentPath(nodeListOutputPath))
    const outputBuffer = []
    const savingSystem = {
        flushBuffer() {
            // clear the buffer synchonously, then return a promise for the rest
            const bufferChunk = [...outputBuffer]
            outputBuffer.length = 0
            return (async ()=>{
                const currentTime = (new Date()).getTime()
                try {
                    //await logLine(`nodeCount: ${numberOfNodesProcessed}, spending ${Math.round((currentTime-startTime)/numberOfNodesProcessed)}ms per node`)
                    await savingSystem.mainLoggingFile.write(new TextEncoder().encode(bufferChunk.join("\n")))
                } catch (error) {
                    console.debug(`error is:`,error)
                }
            })()
        }
    }
    try {
        savingSystem.mainLoggingFile = await Deno.open(nodeListOutputPath, {read:true, write: true, create: true, append: true})
    } catch (error) {
        // console.debug(`error is:`,error)
    }

// 
// 
// iterative deepening
// 
// 
    
    const workers = [...Array(numberOfParallelNixProcesses)].map(each=>new Worker(nixpkgsHash))
    await Promise.all(workers.map(each=>each.taskFinished))
    const rootAttrNames = await workers[0].getAttrNames([])
    const frontierInitNodes = [...Array(numberOfParallelNixProcesses)].map(each=>[])
    for (const [index, eachAttrName] of enumerate(rootAttrNames)) {
        frontierInitNodes[index%numberOfParallelNixProcesses].push(
            createNode(null, eachAttrName)
        )
    }
    await FileSystem.write({data: JSON.stringify(frontierInitNodes.map(each=>each.map(each=>each[1])),0,4), path: "frontier_inits.ignore.json"})
    const workerPromises = workers.map(each=>deferredPromise())
    for (const [worker, initialFrontier] of zip(workers, frontierInitNodes)) {
        const workerId = `worker${worker.index}`
        const exclusiveNames = initialFrontier.map(eachNode=>eachNode[Name])
        ;((async ()=>{
            let nextMaxDepth = 0
            while (nextMaxDepth+1 <= maxDepth) {
                nextMaxDepth += 1
                individualIterCounts[workerId] = nextMaxDepth
                const depthLevels = [
                    [...initialFrontier],
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
                    return [deepestNode, deepestDepth+1]
                }
                while (1) {
                    const depthLevelsBefore = [...depthLevels.map(each=>[...each])]
                    const [ currentNode, nodeDepth ] = getDeepestNode()
                    if (currentNode == null) {
                        break
                    }
                    const currentTime = (new Date()).getTime()
                    numberOfNodesProcessed += 1
                    if (numberOfNodesProcessed % 200 == 0) {
                        await logLine(`numberOfNodesProcessed:${numberOfNodesProcessed}, spending ${Math.round((currentTime-startTime)/numberOfNodesProcessed)}ms per node, currentDepths:\n${JSON.stringify(individualIterCounts,0,4)}`)
                    }
                    
                    const attrPath = getAttrPath(currentNode)
                    // if (!exclusiveNames.some(eachName=>attrPath.includes(eachName))) {
                    //     throw Error(`
                    //         ${workerId}: found node that doesn't belong!
                    //         attrPath: ${attrPath}
                    //         currentNode: ${currentNode}
                    //         exclusiveNames: ${exclusiveNames}
                    //         depthLevelsBefore: ${JSON.stringify(depthLevelsBefore,0,4)}
                    //     `)
                    // }
                    // // console.debug(`1st attrPath is:`,attrPath)
                    const childDepth = nodeDepth+1
                    const childDepthLevel = nodeDepth
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
                        // // console.debug(`error is:`,error)
                        attrErr = error.message
                    }
                    // // console.debug(`childNames is:`,childNames)
                    if (!childrenAreTooDeep && childNames) {
                        if (depthLevels[childDepthLevel] == null) {
                            depthLevels[childDepthLevel] = []
                        }
                        for (const eachChildName of childNames) {
                            // console.log(`    here13`)
                            // // console.debug(`eachChildName is:`,eachChildName)
                            // // console.debug(`childDepthLevel is:`,childDepth)
                            depthLevels[childDepthLevel].push(
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
                        if (outputBuffer.length > 1000) {
                            await savingSystem.flushBuffer()
                        }
                    }
                }
            }
            await workerPromises[worker.index].resolve(true)
            console.log(`\n${workerId} finished!:${workerPromises.filter(each=>each.state=="pending").length} remaining`)
            await logLine(`numberOfNodesProcessed:${numberOfNodesProcessed}, spending ${Math.round(((new Date()).getTime()-startTime)/numberOfNodesProcessed)}ms per node, currentDepths:\n${JSON.stringify(individualIterCounts,0,4)}`)
        })())
    }
    await Promise.all(workerPromises).then(()=>Deno.exit(0))