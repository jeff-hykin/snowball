// run`nix repl -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/aa0e8072a57e879073cee969a780e586dbe57997.tar.gz ${Stdin()} ${Stdout()} ${Stderr()}` 
// new Deno.Command(`nix`, { args: [`repl`, `-I`, `nixpkgs=https://github.com/NixOS/nixpkgs/archive/aa0e8072a57e879073cee969a780e586dbe57997.tar.gz`], stdin: 'piped', stdout: 'piped', stderr: 'piped' })


import { Console, clearAnsiStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, strikethrough, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.6.36/main/console.js"
var command = new Deno.Command(`nix`, { args: [`repl`, `-I`, `nixpkgs=https://github.com/NixOS/nixpkgs/archive/aa0e8072a57e879073cee969a780e586dbe57997.tar.gz`], stdin: 'piped', stdout: 'piped', stderr: 'piped' })
var child = command.spawn()
var stdin = child.stdin.getWriter()
var write = (text)=>stdin.write( new TextEncoder().encode(text) )
var send = (text)=>stdin.write( new TextEncoder().encode(text+"\n") )



// 
// stdout
// 
    var stdout = child.stdout.getReader()
    var stdoutRead = ()=>stdout.read().then(({value, done})=>new TextDecoder().decode(value))
    var stdoutTextSoFar = ""
    ;((async ()=>{
        while (true) {
            stdoutTextSoFar += await stdoutRead()
        }
    })())
    let prevStdoutIndex = 0
    // returns all text since last grab
    var grabStdout = ()=>{
        const output = stdoutTextSoFar.slice(prevStdoutIndex,)
        prevStdoutIndex = stdoutTextSoFar.length
        return output
    }

// 
// stderr
// 
    var stderr = child.stderr.getReader()
    var stderrRead = ()=>stderr.read().then(({value, done})=>new TextDecoder().decode(value))
    var stderrTextSoFar = ""
    ;((async ()=>{
        while (true) {
            stderrTextSoFar += await stderrRead()
        }
    })())
    let prevStderrIndex = 0
    // returns all text since last grab
    var grabStderr = ()=>{
        const output = stderrTextSoFar.slice(prevStderrIndex,)
        prevStderrIndex = stderrTextSoFar.length
        return output
    }

// 
// test
// 
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


