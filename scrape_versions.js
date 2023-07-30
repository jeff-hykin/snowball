import { Console, clearAnsiStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, strikethrough, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.6.36/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString, regex, escapeRegexMatch, escapeRegexReplace, extractFirst, isValidIdentifier } from "https://deno.land/x/good@1.4.4.1/string.js"

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
            const fullMessagePatternStderr = regex`${/[\w\W]*/}${bigRandomStartInt}${/\n([\w\W]*)\n/}${commonStderrStartString}{0,2}trace: ${bigRandomEndInt}${/[\w\W]*/}`
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
            console.debug(`var stdoutText =`,toRepresentation(stdoutText))
            console.debug(`var fullMessagePatternStdout =`,toRepresentation(fullMessagePatternStdout))
            console.debug(`var stderrText =`,toRepresentation(stderrText))
            console.debug(`var fullMessagePatternStderr =`,toRepresentation(fullMessagePatternStderr))
            return {
                stdout: stdoutText.replace(fullMessagePatternStdout, "$1"),
                stderr: stderrText.replace(fullMessagePatternStderr, "$1"),
            }
        }
    

    
    async function practicalRunNixCommand(command) {
        const { stdout, stderr } = await runNixCommand(command)
        return {
            stdout: clearAnsiStylesFrom(stdout).replace(/\n*$/,""),
            stderr: stderr.startsWith(commonStderrStartString) ? stderr.slice(commonStderrStartString.length,) : stderr,
        }
    }

    return { runNixCommand, practicalRunNixCommand }
}

var { runNixCommand, practicalRunNixCommand } = createNixCommandRunner(`aa0e8072a57e879073cee969a780e586dbe57997`)
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