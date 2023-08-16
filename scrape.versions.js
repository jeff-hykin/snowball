import { FileSystem } from "https://deno.land/x/quickr@0.6.36/main/file_system.js"
import { Console, clearAnsiStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, strikethrough, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.6.36/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString, regex, escapeRegexMatch, escapeRegexReplace, extractFirst, isValidIdentifier } from "https://deno.land/x/good@1.4.4.1/string.js"
import { BinaryHeap, ascend, descend } from "https://deno.land/x/good@1.4.4.1/binary_heap.js"
import { deferredPromise } from "https://deno.land/x/good@1.4.4.1/async.js"
import { enumerate, count, zip, iter, next } from "https://deno.land/x/good@1.4.4.1/iterable.js"
import * as yaml from "https://deno.land/std@0.168.0/encoding/yaml.ts"
import { generateKeys, encrypt, decrypt, hashers } from "https://deno.land/x/good@1.4.4.3/encryption.js"

const waitTime = 100 // miliections
const nodeListOutputPath = "attr_tree.yaml"
const nameFrequencyPath = "./attr_name_count.ignore.yaml"
let nameFrequency = {} // yaml.parse(await FileSystem.read(nameFrequencyPath)||"{}")
const shouldUpdateNameFrequencies = true
const numberOfParallelNixProcesses = 40
var nixpkgsHash = `aa0e8072a57e879073cee969a780e586dbe57997`
const maxDepth = 8
const textEncoder = new TextEncoder()

const childrenToIgnore = [
    "__darwinAllowLocalNetworking",
    "__ignoreNulls",
    "__impureHostDeps",
    "__propagatedImpureHostDeps",
    "__propagatedSandboxProfile",
    "__sandboxProfile",
    "addErrorContext",
    "addMetaAttrs",
    "all",
    "allowSubstitutes",
    "applicationName",
    "args",
    "AUTOMATED_TESTING",
    "baseName",
    "basicEnv",
    "bin",
    "buildAndTestSubdir",
    "buildCommand",
    "buildDepends",
    "builder",
    "buildFlags",
    "buildInputs",
    "buildPhase",
    "buildTools",
    "bypassCache",
    "callPackage",
    "cargoBuildFlags",
    "cargoBuildType",
    "cargoCheckType",
    "cargoDepsName",
    "cargoSha256",
    "CFLAGS",
    "CGO_ENABLED",
    "checkFlags",
    "checkPhase",
    "checkTarget",
    "cmakeFlags",
    "compileBuildDriverPhase",
    "compositionScript",
    "configureFlags",
    "configurePhase",
    "configurePlatforms",
    "configureScript",
    "CSC_OPTIONS",
    "curlOpts",
    "CXXFLAGS",
    "darwinMinVersion",
    "darwinMinVersionVariable",
    "depsBuildBuild",
    "depsBuildBuildPropagated",
    "depsBuildTarget",
    "depsBuildTargetPropagated",
    "depsHostHost",
    "depsHostHostPropagated",
    "depsTargetTarget",
    "depsTargetTargetPropagated",
    "dev",
    "disabledTests",
    "disallowedReferences",
    "distPhase",
    "doCheck",
    "doInstallCheck",
    "dontAddStaticConfigureFlags",
    "dontAutoPatchelf",
    "dontBuild",
    "dontConfigure",
    "dontDisableStatic",
    "dontFixLibtool",
    "dontFixup",
    "dontInstall",
    "dontNpmInstall",
    "dontPatchELF",
    "dontPatchShebangs",
    "dontStrip",
    "dontUnpack",
    "dontUpdateAutotoolsGnuConfigScripts",
    "dontUseCmakeConfigure",
    "dontUseImakeConfigure",
    "dontUseMesonConfigure",
    "dontWrapGApps",
    "dontWrapQtApps",
    "downloadToTemp",
    "drvAttrs",
    "drvPath",
    "emacsBufferSetup",
    "enableParallelBuilding",
    "enableParallelChecking",
    "executable",
    "executableFrameworkDepends",
    "executableHaskellDepends",
    "executablePkgconfigDepends",
    "executableSystemDepends",
    "executableToolDepends",
    "expand-response-params",
    "expandResponseParams",
    "extraLibraries",
    "extraNativeBuildInputs",
    "fixupPhase",
    "getBuildInputs",
    "getCabalDeps",
    "go-modules",
    "GO111MODULE",
    "GO386",
    "GOARCH",
    "GOARM",
    "GOFLAGS",
    "GOHOSTARCH",
    "GOHOSTOS",
    "GOOS",
    "goPackagePath",
    "haddockDir",
    "haddockPhase",
    "hardeningDisable",
    "hasCC",
    "hash",
    "ignoreCollisions",
    "impureEnvVars",
    "includeDirs",
    "inputDerivation",
    "installCheckPhase",
    "installCheckTarget",
    "installFlags",
    "installPhase",
    "installTargets",
    "is32bit",
    "is64bit",
    "isAarch32",
    "isAarch64",
    "isBigEndian",
    "isBSD",
    "isClang",
    "isCygwin",
    "isDarwin",
    "isFreeBSD",
    "isGNU",
    "isHardened",
    "isHaskellLibrary",
    "isLinux",
    "isMips",
    "isOpenBSD",
    "isx86_64",
    "LANG",
    "LC_ALL",
    "ldflags",
    "LDFLAGS",
    "libPath",
    "libPrefix",
    "libraryFrameworkDepends",
    "libraryHaskellDepends",
    "libraryPkgconfigDepends",
    "librarySystemDepends",
    "libraryToolDepends",
    "MACH_USE_SYSTEM_PYTHON",
    "makeFlags",
    "makeWrapperArgs",
    "mesonFlags",
    "meta",
    "mirrorsFile",
    "mkDerivation",
    "name",
    "nativeBuildInputs",
    "nativePrefix",
    "newScope",
    "NIX_CFLAGS_COMPILE",
    "NIX_HARDENING_ENABLE",
    "NIX_LDFLAGS",
    "nixpkgsVersion",
    "openglSupport",
    "out",
    "outPath",
    "outputBin",
    "outputHash",
    "outputHashAlgo",
    "outputHashMode",
    "outputName",
    "outputs",
    "outputSpecified",
    "override",
    "overrideAttrs",
    "overrideDerivation",
    "overridePythonAttrs",
    "overrideScope",
    "packageName",
    "passAsFile",
    "passthru",
    "patches",
    "patchFlags",
    "patchPhase",
    "patchRegistryDeps",
    "pathsToLink",
    "PERL_AUTOINSTALL",
    "PERL_USE_UNSAFE_INC",
    "pinpointDependenciesScript",
    "PKG_CONFIG_ALLOW_CROSS",
    "pkg-configDepends",
    "platform",
    "postBuild",
    "postConfigure",
    "postFetch",
    "postFixup",
    "postHook",
    "postInstall",
    "postInstallCheck",
    "postPatch",
    "postUnpack",
    "preAutoreconf",
    "preBuild",
    "preCheck",
    "preConfigure",
    "preConfigurePhases",
    "preferHashedMirrors",
    "preferLocalBuild",
    "preFixup",
    "preHook",
    "preInstall",
    "preInstallPhases",
    "prePatch",
    "prePhases",
    "preRebuild",
    "production",
    "propagatedBuildInputs",
    "propagatedNativeBuildInputs",
    "pythonImportsCheck",
    "pythonModule",
    "pythonPath",
    "pythonVersion",
    "qmakeFlags",
    "QTDIR",
    "qtInputs",
    "reconstructLock",
    "recurseForDerivations",
    "removeLocal",
    "renameImports",
    "requiredPythonModules",
    "requiredSystemFeatures",
    "setOutputFlags",
    "setupCompilerEnvironmentPhase",
    "setupHaskellDepends",
    "setupHook",
    "setupHooks",
    "shellHook",
    "shellPath",
    "showOption",
    "showURLs",
    "sourceRoot",
    "src",
    "SSL_CERT_FILE",
    "stdenv",
    "strictDeps",
    "suffixSalt",
    "system",
    "targetPrefix",
    "tests",
    "type",
    "unpackPhase",
    "updateScript",
    "urls",
    "userHook",
    "vendorSha256",
    "withPackages",
    "wrapperName",
    // "pname",
    // "version",
]

const shallowSortObject = (obj) => {
    return Object.entries(obj).sort(([_,a],[__, b])=>(a||0)-(b||0)).reduce(
        (newObj, [key, value]) => { 
            newObj[key] = value; 
            return newObj
        }, 
        {}
    )
}


// TOOD:
    // allow any partition to use any available worker

// 
// helpers
// 
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
    const seed = 10
    const hash = (str) => {
        if (str == null) {
            return null
        }
        let h1 = 0xdeadbeef ^ seed, h2 = 0x41c6ce57 ^ seed;
        for(let i = 0, ch; i < str.length; i++) {
            ch = str.charCodeAt(i);
            h1 = Math.imul(h1 ^ ch, 2654435761);
            h2 = Math.imul(h2 ^ ch, 1597334677);
        }
        h1  = Math.imul(h1 ^ (h1 >>> 16), 2246822507);
        h1 ^= Math.imul(h2 ^ (h2 >>> 13), 3266489909);
        h2  = Math.imul(h2 ^ (h2 >>> 16), 2246822507);
        h2 ^= Math.imul(h1 ^ (h1 >>> 13), 3266489909);
    
        return 4294967296 * (2097151 & h2) + (h1 >>> 0);
    }
    var escapeNixString = (string)=>{
        return `"${string.replace(/\$\{|[\\"]/g, '\\$&').replace(/\u0000/g, '\\0')}"`
    }
    var attrListToNix = (attrList)=>{
        if (typeof attrList == 'string') {
            attrList = [attrList]
        }
        let attrString
        if (attrList.length == 1) {
            attrString = attrList[0]
        } else {
            attrString = attrList[0]+"."+(attrList.slice(1,).map(escapeNixString).join("."))
        }
        return attrString
    }

    /**
     * @example
     *     await getAttrNamesAndId(["builtins", "nixVersion"], practicalRunNixCommand)
     *     // [] 
     *     // non-attrset values return empty lists
     * 
     *     await getAttrNamesAndId("builtins", practicalRunNixCommand)
     *     // [ "abort", "add", "addErrorContext", ... ]
     *
     *     await getAttrNamesAndId(["builtins"], practicalRunNixCommand)
     *     // [ "abort", "add", "addErrorContext", ... ]
     *
     */
    async function getAttrNamesAndId(attrList, practicalRunNixCommand) {
        const fullAttrList = attrListToNix(attrList)
        const lastAttr = escapeNixString(attrList.pop())
        const parentAttrList = attrList.length == 0 ? "{}" : attrListToNix(attrList)
        const command = `
            (builtins.trace
                (builtins.toJSON
                    [
                        (
                            if
                                (builtins.isAttrs (${fullAttrList}))
                            then 
                                (builtins.attrNames
                                    (${fullAttrList})
                                )
                            else
                                ([])
                        )
                        (builtins.unsafeGetAttrPos ${lastAttr} ${parentAttrList})
                    ]
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
    async function getDeepAttrNames(attrList, practicalRunNixCommand) {
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
                                                value = (builtins.getAttr eachAttr ${attrString});
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
        // console.debug(`command is:`,command)
        const { stdout, stderr } = await practicalRunNixCommand(command)
        // console.debug(`stderr is:`, toRepresentation(stderr))
        try {
            // console.debug()
            // console.debug(`stderr.replace(/^trace: /,"") is:`,stderr.replace(/^trace: /,""))
            return JSON.parse(stderr.replace(/^trace: /,""))
        } catch (error) {
            try {
                // console.debug(`caught error is:`,error)
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
                // console.debug(`command is:`,command)
                const { stdout, stderr } = await practicalRunNixCommand(command)
                // console.debug(`stderr is:`, toRepresentation(stderr))
                // const parsedOutput = JSON.parse(stderr.replace(/^trace: /,""))
                // console.debug(`parsedOutput is:`,parsedOutput)
                return [
                    JSON.parse(stderr.replace(/^trace: /,"")),
                    null
                ]
            } catch (error) {
                throw Error(stderr)
            }
        }
    }

// 
// node setup
// 
    let childrenHaveBeenExplored = {}
    let numberOfNodes = 0
    const Parent = 0
    const Name = 1
    const createNode = (parent, name)=>{
        return [parent, name]
    }
    const getDepth = (node)=>{
        let depth = 1
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
            this.initFinished = this.send(`pkgs = import <nixpkgs> {}`)
            console.log(`worker${this.index} created`)
        }
        async getAttrNamesAndId(attrList) {
            // console.log(`worker ${this.index} is working on a job`)
            const attrPath = ["pkgs", ...attrList]
            // // console.debug(`attrPath is:`,attrPath)
            const output = await getAttrNamesAndId(attrPath, this.practicalRunNixCommand)
            // console.log(`worker ${this.index} is finished job`)
            return output
        }
    }

// 
// save system
// 
    const saveNameFrequency = ()=>{
        nameFrequency = shallowSortObject(nameFrequency)
        function* generateLines() {
            for (const [key, value] of Object.entries(nameFrequency)) {
                yield `${yaml.stringify(key).replace(/\n$/,"")}: ${yaml.stringify(value)}`
            }
        }
        return FileSystem.write({
            data:generateLines(),
            path: nameFrequencyPath,
        })
    }
    
    await FileSystem.remove(nodeListOutputPath)
    let numberOfNodesProcessed = 0
    const individualIterCounts = {}
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
                    await savingSystem.mainLoggingFile.write(new TextEncoder().encode(bufferChunk.join("\n")+"\n"))
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
    await Promise.all(workers.map(each=>each.initFinished))
    const rootAttrNames = (await workers[0].getAttrNamesAndId([]))[0]
    const frontierInitNodes = [...Array(numberOfParallelNixProcesses)].map(each=>[])
    for (const [index, eachAttrName] of enumerate(rootAttrNames)) {
        frontierInitNodes[index%numberOfParallelNixProcesses].push(
            createNode(null, eachAttrName)
        )
    }
    const workerPromises = workers.map(each=>deferredPromise())
    let prevMinCommonDepth = 0
    const minCommonDepth = ()=>Math.min(...workers.map(each=>each.nextMaxDepth))
    const sourcePrefixLength = "/nix/store/mwyfaz3406rhdi91ynv93qhj0smyi0kh-source/".length // note: hash shouldn't change length
    for (const [worker, initialFrontier] of zip(workers, frontierInitNodes)) {
        const workerId = `worker${worker.index}`
        const exclusiveNames = initialFrontier.map(eachNode=>eachNode[Name])
        ;((async ()=>{
            worker.nextMaxDepth = 0
            while (worker.nextMaxDepth+1 <= maxDepth) {
                worker.nextMaxDepth += 1
                if (!childrenHaveBeenExplored[worker.nextMaxDepth]) {
                    childrenHaveBeenExplored[worker.nextMaxDepth] = new Set()
                }
                // helping the garbage collector out
                if (workers.every(each=>each.nextMaxDepth > worker.nextMaxDepth)) {
                    delete childrenHaveBeenExplored[worker.nextMaxDepth-1]
                }
                const childrenHaveBeenExploredAtThisLevel = childrenHaveBeenExplored[worker.nextMaxDepth]
                individualIterCounts[workerId] = worker.nextMaxDepth
                console.debug(`worker${worker.index}.nextMaxDepth is:`,worker.nextMaxDepth)
                const effectiveDepth = (node)=>{
                    let depth = getDepth(node)
                    const nodeName = node[Name]
                    if (nodeName.startsWith("__")) {
                        depth += 2
                    }
                    return depth
                }
                const frontier = new BinaryHeap(
                    (nodeA,nodeB)=>ascend(
                        effectiveDepth(nodeA),
                        effectiveDepth(nodeB)
                    )
                )
                for (const each of initialFrontier) {
                    frontier.push(each)
                }
                while (frontier.length > 0) {
                    const currentNode = frontier.pop()
                    const nodeDepth = getDepth(currentNode)
                    const effectiveNodeDepth = effectiveDepth(currentNode)
                    const attrPath = getAttrPath(currentNode)
                    const childDepth = nodeDepth+1
                    const childrenAreTooDeep = childDepth > worker.nextMaxDepth
                    let attrErr
                    var childNames
                    var nodePositionInfo
                    try {
                        var [childNames, nodePositionInfo] = await worker.getAttrNamesAndId(attrPath)
                        childNames = childNames.filter(each=>!childrenToIgnore.includes(each))
                        const nodeName = currentNode[Name]
                        if (childNames.length != 0) {
                            nameFrequency[nodeName] = NaN
                        }
                        if (childNames.length == 0 && (nameFrequency[nodeName]===nameFrequency[nodeName])) {
                            nameFrequency[nodeName] = (nameFrequency[nodeName]||0)+1
                        }
                        // short string to save space
                        if (nodePositionInfo?.file) {
                            nodePositionInfo.file = nodePositionInfo.file.slice(sourcePrefixLength,)
                        }
                    } catch (error) {
                        attrErr = error.message
                    }
                    if (!childrenAreTooDeep) {
                        // the nextMaxDepth is very important, because these nodes must be
                        // re-explored every time it increases, and (thankfully) it 
                        // doesn't matter which worker is exploring them 
                        // const nodeName = currentNode[Name]
                        const nodeId = hash(JSON.stringify(nodePositionInfo))
                        // const alreadyExploredAtThisDepth = childrenHaveBeenExploredAtThisLevel.has(nodeId)
                        // console.debug(`    node: ${nodeName}: depth: ${worker.nextMaxDepth}: nodeId:${nodeId} alreadyExplored? ${alreadyExploredAtThisDepth}: ${JSON.stringify(nodePositionInfo)}`,)
                        childrenHaveBeenExploredAtThisLevel.add(nodeId)
                        if (childNames) {
                            for (const eachChildName of childNames) {
                                // DEBUGGING: remove this and add them back to the childrenToIgnore list
                                if (eachChildName == "version" || eachChildName == "pname") {
                                    continue
                                }
                                const childNode = [currentNode, eachChildName]
                                // skip anything effectively too deep
                                if (effectiveDepth(childNode) > worker.nextMaxDepth) {
                                    continue
                                }
                                frontier.push(
                                    createNode(currentNode, eachChildName)
                                )
                            }
                        }
                    }
                    
                    // only record at the depth that hasnt been seen before
                    if (nodeDepth == worker.nextMaxDepth) {
                        const nodeName = currentNode[Name]
                        numberOfNodesProcessed += 1
                        if (numberOfNodesProcessed % 1500 == 0) {
                            await logLine(`numberOfNodesProcessed:${numberOfNodesProcessed}, spending ${(((new Date()).getTime()-startTime)/numberOfNodesProcessed).toFixed(2)}ms per node, currentDepths:\n${JSON.stringify(individualIterCounts)}`)
                            saveNameFrequency()
                            // if (shouldUpdateNameFrequencies) {
                            //     if (minCommonDepth() != prevMinCommonDepth) {
                            //         prevMinCommonDepth = minCommonDepth()
                            //     }
                            // }
                        }
                        // save data about this node
                        outputBuffer.push(
                            "- "+JSON.stringify([
                                // attrPath, nodeDepth, effectiveNodeDepth, nameFrequency[attrPath.slice(-1)[0]], childNames, attrErr,
                                attrPath, nodeDepth, effectiveNodeDepth, `${nodePositionInfo?.file}:${nodePositionInfo?.line}:${nodePositionInfo?.column}`, childNames, attrErr&&`${attrErr}`.slice(0, 80),
                            ])
                        )
                        if (outputBuffer.length > 1000) {
                            await savingSystem.flushBuffer()
                        }
                    }
                }
            }
            await workerPromises[worker.index].resolve()
            console.log(`\n${workerId} finished!:${workerPromises.filter(each=>each.state=="pending").length} remaining`)
            await logLine(`numberOfNodesProcessed:${numberOfNodesProcessed}, spending ${Math.round(((new Date()).getTime()-startTime)/numberOfNodesProcessed)}ms per node, currentDepths:\n${JSON.stringify(individualIterCounts,0,4)}`)
        })())
    }
    const startTime = (new Date()).getTime()
    await Promise.all(workerPromises).then(()=>Deno.exit(0))