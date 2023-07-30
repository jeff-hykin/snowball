import { Console, clearAnsiStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, strikethrough, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.6.36/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString, regex, escapeRegexMatch, escapeRegexReplace, extractFirst, isValidIdentifier } from "https://deno.land/x/good@1.4.4.1/string.js"

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
                // sleep for debugging
                await new Promise((resolve, reject)=>setTimeout(resolve, 1000))
                if (stdoutIsDone && stderrIsDone) {
                    break
                }
                if (!stdoutIsDone) {
                    stdoutText += grabStdout()
                }
                if (!stderrIsDone) {
                    stderrText += grabStderr()
                }
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

async function getAttrNames(attrList, practicalRunNixCommand) {
    if (typeof attrList == 'string') {
        attrList = [attrList]
    }
    let attrString
    if (attrList.length == 1) {
        attrString = attrList[0]
    } else {
        attrString = attrList[0]+"."+attrList.map(escapeNixString)
    }
    const { stdout, stderr } = await practicalRunNixCommand(`
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
    `.replace(/[\n ]+/, " "))
    return JSON.parse(stderr.replace(/^trace: /,""))
}


async function buildAttrTree(nixpkgsHash, treePath) {
    var { runNixCommand, practicalRunNixCommand, send, write } = createNixCommandRunner(nixpkgsHash)
    // intentionally dont await
    send(`pkgs = import <nixpkgs> {}`)
    
    
}

var nixpkgsHash = `aa0e8072a57e879073cee969a780e586dbe57997`
var { runNixCommand, practicalRunNixCommand, send, write } = createNixCommandRunner(nixpkgsHash)
getAttrNames("builtins", practicalRunNixCommand)


var a = await practicalRunNixCommand(`builtins.trace "im in stderr" 10`)




await write("10\n")
    clearAnsiStylesFrom(grabStdout())

    await send`pkgs = import <nixpkgs> {}`
    clearAnsiStylesFrom(grabStdout())
    grabStderr()


    var bigRandomInt = `${Math.random()}`.replace(".","").replace(/^0*/,"")
    await send(`builtins.trace "" ${bigRandomInt}`)
    await send(`builtins.trace (builtins.toJSON (builtins.attrNames (pkgs))) ${bigRandomInt}`)
    clearAnsiStylesFrom(grabStdout())
    var data = grabStderr()
    var probablyJsonData = data.replace(/^[\w\W]*?trace: /,"")
    var packageData = JSON.parse(probablyJsonData)


buildAttrTree()