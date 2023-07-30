#!/usr/bin/env sh
"\"",`$(echo --% ' |out-null)" >$null;function :{};function dv{<#${/*'>/dev/null )` 2>/dev/null;dv() { #>
echo "1.33.1"; : --% ' |out-null <#'; }; version="$(dv)"; deno="$HOME/.deno/$version/bin/deno"; if [ -x "$deno" ]; then  exec "$deno" run -q -A --v8-flags=--max-old-space-size=32000 "$0" "$@";  elif [ -f "$deno" ]; then  chmod +x "$deno" && exec "$deno" run -q --v8-flags=--max-old-space-size=32000 -A "$0" "$@";  fi; bin_dir="$HOME/.deno/$version/bin"; exe="$bin_dir/deno"; has () { command -v "$1" >/dev/null; } ;  if ! has unzip; then if ! has apt-get; then  has brew && brew install unzip; else  if [ "$(whoami)" = "root" ]; then  apt-get install unzip -y; elif has sudo; then  echo "Can I install unzip for you? (its required for this command to work) ";read ANSWER;echo;  if [ "$ANSWER" =~ ^[Yy] ]; then  sudo apt-get install unzip -y; fi; elif has doas; then  echo "Can I install unzip for you? (its required for this command to work) ";read ANSWER;echo;  if [ "$ANSWER" =~ ^[Yy] ]; then  doas apt-get install unzip -y; fi; fi;  fi;  fi;  if ! has unzip; then  echo ""; echo "So I couldn't find an 'unzip' command"; echo "And I tried to auto install it, but it seems that failed"; echo "(This script needs unzip and either curl or wget)"; echo "Please install the unzip command manually then re-run this script"; exit 1;  fi;  repo="denoland/deno"; if [ "$OS" = "Windows_NT" ]; then target="x86_64-pc-windows-msvc"; else :;  case $(uname -sm) in "Darwin x86_64") target="x86_64-apple-darwin" ;; "Darwin arm64") target="aarch64-apple-darwin" ;; "Linux aarch64") repo="LukeChannings/deno-arm64" target="linux-arm64" ;; "Linux armhf") echo "deno sadly doesn't support 32-bit ARM. Please check your hardware and possibly install a 64-bit operating system." exit 1 ;; *) target="x86_64-unknown-linux-gnu" ;; esac; fi; deno_uri="https://github.com/$repo/releases/download/v$version/deno-$target.zip"; exe="$bin_dir/deno"; if [ ! -d "$bin_dir" ]; then mkdir -p "$bin_dir"; fi;  if ! curl --fail --location --progress-bar --output "$exe.zip" "$deno_uri"; then if ! wget --output-document="$exe.zip" "$deno_uri"; then echo "Howdy! I looked for the 'curl' and for 'wget' commands but I didn't see either of them. Please install one of them, otherwise I have no way to install the missing deno version needed to run this code"; exit 1; fi; fi; unzip -d "$bin_dir" -o "$exe.zip"; chmod +x "$exe"; rm "$exe.zip"; exec "$deno" run -q --v8-flags=--max-old-space-size=32000 -A "$0" "$@"; #>}; $DenoInstall = "${HOME}/.deno/$(dv)"; $BinDir = "$DenoInstall/bin"; $DenoExe = "$BinDir/deno.exe"; if (-not(Test-Path -Path "$DenoExe" -PathType Leaf)) { $DenoZip = "$BinDir/deno.zip"; $DenoUri = "https://github.com/denoland/deno/releases/download/v$(dv)/deno-x86_64-pc-windows-msvc.zip";  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;  if (!(Test-Path $BinDir)) { New-Item $BinDir -ItemType Directory | Out-Null; };  Function Test-CommandExists { Param ($command); $oldPreference = $ErrorActionPreference; $ErrorActionPreference = "stop"; try {if(Get-Command "$command"){RETURN $true}} Catch {Write-Host "$command does not exist"; RETURN $false}; Finally {$ErrorActionPreference=$oldPreference}; };  if (Test-CommandExists curl) { curl -Lo $DenoZip $DenoUri; } else { curl.exe -Lo $DenoZip $DenoUri; };  if (Test-CommandExists curl) { tar xf $DenoZip -C $BinDir; } else { tar -Lo $DenoZip $DenoUri; };  Remove-Item $DenoZip;  $User = [EnvironmentVariableTarget]::User; $Path = [Environment]::GetEnvironmentVariable('Path', $User); if (!(";$Path;".ToLower() -like "*;$BinDir;*".ToLower())) { [Environment]::SetEnvironmentVariable('Path', "$Path;$BinDir", $User); $Env:Path += ";$BinDir"; } }; & "$DenoExe" run -q --v8-flags=--max-old-space-size=32000 -A "$PSCommandPath" @args; Exit $LastExitCode; <# 
# */0}`;
import { FileSystem } from "https://deno.land/x/quickr@0.6.36/main/file_system.js"
import { Console, clearAnsiStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, strikethrough, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.6.36/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString, regex, escapeRegexMatch, escapeRegexReplace, extractFirst, isValidIdentifier } from "https://deno.land/x/good@1.4.4.1/string.js"
import { BinaryHeap, ascend, descend } from "https://deno.land/x/good@1.4.4.1/binary_heap.js"
import { zip } from "https://deno.land/x/good@1.4.4.1/array.js"
import { debounce } from "https://deno.land/std@0.196.0/async/debounce.ts";

// todo:
    // attempt to switch to iterative deepening instead of uniform-cost-search (difficult to do DFS with parallelization)
    // create a parallel process for grabbing node-info (version+name)
    // create a static analysis task for listing all packages with literal names and versions, then try to cross reference

// idea:
    // pull nixpkgs commit
    // use static analysis to find the quantity of packages (look for attrsets with version and name attribute)
    // then iterate till at least all static-analysis packages have been found

const waitTime = 100 // miliections
const attributesThatIndicateLeafPackage = ["outPath"] // "has any of these attributes" => children wont be searched
let stdoutLogRate = 2000 // every __ miliseconds
const nodeListOutputPath = "attr_tree.yaml"
const numberOfParallelNixProcesses = 40
var nixpkgsHash = `aa0e8072a57e879073cee969a780e586dbe57997`
const startTime = (new Date()).getTime()
let numberOfNodes = 0


// logging
    setInterval(() => {
        const currentTime = (new Date()).getTime()
        Deno.stdout.write(new TextEncoder().encode(`nodeCount: ${numberOfNodes}, _binaryHeap: ${_binaryHeap.length}, spending ${Math.round((currentTime-startTime)/numberOfNodes)}ms per node                                     \r`.replace(/(\d+)(\d\d\d)\b/g,"$1,$2")))
    }, stdoutLogRate)

// file writing
    let buffer = ""
    await FileSystem.ensureIsFolder(FileSystem.parentPath(nodeListOutputPath))
    const file = await Deno.open(nodeListOutputPath, {read:true, write: true, create: true})
    await file.seek(0, Deno.SeekMode.End)
    setInterval(() => {
        file.write(new TextEncoder().encode(buffer))
        buffer = ""
    }, stdoutLogRate)

// dumping stdoutLogRate
    setInterval(async () => {
        const fileWriteStartTime = (new Date()).getTime()
        await FileSystem.write({
            data: JSON.stringify(attrNameCount, 0, 4),
            path: "attr_name_count.json",
        }).then(()=>{
            stdoutLogRate = 2*((new Date()).getTime()-fileWriteStartTime)
            console.debug(`stdoutLogRate is now:`,stdoutLogRate)
        })
    }, 120_000)


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
 *     // [ [], null ] 
 *     // non-attrset values return empty lists
 * 
 *     await getAttrNames("builtins", practicalRunNixCommand)
 *     // got attrs but couldn't get 1-deeper attrs
 *     // [ [ "abort", "add", "addErrorContext", ... ], null  ]
 *
 *     await getAttrNames(["builtins"], practicalRunNixCommand)
 *     // [ [ "abort", "add", "addErrorContext", ... ], null ]
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
    // try to get 2 levels of attribute names
    const command = `
        (builtins.trace
            (builtins.toJSON
                (
                    if
                        (builtins.isAttrs (${attrString}))
                    then 
                        [
                            (builtins.attrNames
                                (${attrString})
                            )
                            (builtins.map
                                (eachAttr:
                                    (
                                        let
                                            value = (builtins.getAttr ${attrString} eachAttr);
                                        in
                                            if
                                                (builtins.isAttrs value)
                                            then 
                                                (builtins.attrNames
                                                    value
                                                )
                                            else
                                                []
                                    )
                                )
                                (builtins.attrNames
                                    (${attrString})
                                )
                            )
                        ]
                    else
                        [ [] null ]
                )
            )
            null
        )
    `
    const { stdout, stderr } = await practicalRunNixCommand(command)
    try {
        return JSON.parse(stderr.replace(/^trace: /,""))
    } catch (error) {
        try {
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
            return [
                JSON.parse(stderr.replace(/^trace: /,"")),
                null
            ]
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
}

const attrNameCount = {}
class Node {
    packageId = undefined
    attrName = ""
    depth = 0
    parent = null
    hitError = false
    isLeaf = null
    hasVersionAttribute = null
    hasNameAttribute = null
    constructor(values) {
        Object.assign(this, values)
        attrNameCount[this.attrName] = attrNameCount[this.attrName]+1 || 1
        attrNameCount.pkgs = 1 // hardcoded edgecase
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
            isLeaf: this.isLeaf,
            hasVersionAttribute: this.hasVersionAttribute,
            hasNameAttribute: this.hasNameAttribute,
        }
    }
}

var rootNode
var _binaryHeap
async function attrTreeIterator(workers) {
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
                    ([names, subNames])=>{
                        const subNamesWasComputed = subNames != null
                        subNames = !subNamesWasComputed ? [] : subNames
                        currentNode.isLeaf = names.length == 0
                        currentNode.hasVersionAttribute = names.includes("version")
                        currentNode.hasNameAttribute = names.includes("name")
                        for (let [attrName, eachSubNames] of zip(names, subNames)) {
                            eachSubNames = eachSubNames||[]

                            // if we don't have access to the data, then wait for a later iteration
                            if (!subNamesWasComputed) {
                                branchesToExplore.push(
                                    new Node({
                                        attrName,
                                        depth: currentNode.depth + 1,
                                        parent: currentNode,
                                        isLeaf: null,
                                        hasVersionAttribute: eachSubNames.includes("version"),
                                        hasNameAttribute: eachSubNames.includes("name"),
                                    })
                                )
                            // if we were able to grab two levels, go ahead and process it
                            } else {
                                buffer += `- { attrName: ${attrName},  depth: ${currentNode.depth + 1}, isLeaf: ${eachSubNames.length == 0}, hasVersionAttribute: ${eachSubNames.includes("version")}, hasNameAttribute: ${eachSubNames.includes("name")}, }\n`
                                numberOfNodes+=1
                                // only add to the heap if its not a leaf
                                if (!eachSubNames.length == 0 && !attributesThatIndicateLeafPackage.some(each=>eachSubNames.includes(each))) {
                                    branchesToExplore.push(
                                        new Node({
                                            attrName,
                                            depth: currentNode.depth + 1,
                                            parent: currentNode,
                                            isLeaf: eachSubNames.length == 0,
                                            hasVersionAttribute: eachSubNames.includes("version"),
                                            hasNameAttribute: eachSubNames.includes("name"),
                                        })
                                    )
                                }
                            }
                        }
                    }
                ).catch(
                    error=>{
                        currentNode.hitError = `${error}`
                    }
                ).finally(
                    ()=>{
                        buffer += `- ${JSON.stringify(currentNode)}\n`
                        numberOfNodes++
                    }
                )
                // only need one worker
                break
            }
        }
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


const workers = [...Array(numberOfParallelNixProcesses)].map(each=>new Worker(nixpkgsHash))
await attrTreeIterator(workers)
await file.close()
// (this comment is part of deno-guillotine, dont remove) #>