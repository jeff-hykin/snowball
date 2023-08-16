import { Parser, parserFromWasm, flatNodeList, addWhitespaceNodes } from "https://deno.land/x/deno_tree_sitter@0.0.8/main.js"
import { zip, concurrentlyTransform, filter } from "https://deno.land/x/good@1.4.4.2/iterable.js"
import { FileSystem, glob } from "https://deno.land/x/quickr@0.6.38/main/file_system.js"
import { run } from "https://deno.land/x/quickr@0.6.38/main/run.js"
import nix from "https://github.com/jeff-hykin/common_tree_sitter_languages/raw/4d8a6d34d7f6263ff570f333cdcf5ded6be89e3d/main/nix.js"
const parser = await parserFromWasm(nix)

const { path: randomizerPath, process } = await startRandomizer("./random.ignore")

const path = Deno.args[0]
const pathInfo = await FileSystem.info(path)

const total = (await FileSystem.recursivelyListPathsIn(path)).length
let allItems = [ pathInfo ]
if (pathInfo.isFolder) {
    allItems = FileSystem.recursivelyIterateItemsIn(path)
}

// const balacncedConcurrency = ({ iterator, poolLimit, awaitAll, })
let count = 0
for await (const each of concurrentlyTransform({
        iterator: filter(allItems, (each)=>each.isFile&&each.path.endsWith(".nix")),
        poolLimit: 20,
        transformFunction: (eachItem)=>FileSystem.read(eachItem.path).then(
            (fileString)=>{
                count += 1
                console.log(`transforming: ${count}/${total} ${eachItem.path}`)
                return FileSystem.write({
                    path: eachItem.path,
                    data: addAttrIds(fileString, randomizerPath) 
                })
            }
        ),
    })
) {
    // do nothing, just need to iterate them
}

console.log(`killing randomizer process`)
console.debug(`process.pid is:`, await process.pid)
await process.kill()
await process.kill("SIGKILL")
await process.kill("SIGTERM")
Deno.exit(0)

// 
// creates a file with constantly random values (subprocess)
// 
async function startRandomizer(targetPath) {
    const absPath = FileSystem.makeAbsolutePath(targetPath)
    await FileSystem.ensureIsFolder(FileSystem.parentPath(absPath))
    await FileSystem.remove(absPath)
    const process = run(
        "deno",
        "eval",
        `
            const file = await Deno.open("/dev/urandom")
            const buffer = new Uint8Array(256)
            while (1) {
                file.readSync(buffer)
                const myFile = Deno.openSync(${JSON.stringify(absPath)}, { write: true, truncate:true, create: true })
                await myFile.write(new TextEncoder().encode(buffer))
                myFile.close()
            }
        `
    )
    // wait on process to create the file
    await new Promise(async (resolve, reject)=>{
        while (1) {
            try {
                const info = await FileSystem.info(absPath)
                if (info.isFile) {
                    resolve()
                }
            } catch (error) {
                
            }
            // sleep
            await new Promise((resolve, reject)=>setTimeout(resolve, 100))
        }
    })
    return { process, path:absPath }
}




/**
 * make attr_sets identifiable
 *
 * @note
 *    the randomOutputFilePath is something that needs extra work
 *    basically setup a while loop using a performant language
 *    that constantly overwrites randomOutputFilePath with a fixed-length
 *    random/pseudo-random value. This is the only way I know to 
 *    efficently-ish inject random values into nix
 * @example
 *     const string = `
 *         self: super: with self; {
 *             numpy = callPackage ../development/python-modules/numpy { };
 *             numpy_Args = callPackage ../development/python-modules/numpy/args.nix { };
 *             gitsrht = self.callPackage ./git.nix { };
 *         }
 *     `
 *     console.log(
 *         [
 *             ...addAttrIds(string, "/Users/jeffhykin/repos/snowball/random.ignore")
 *         ].join("")
 *     )
 *     // outputs:
 *     //    self: super: with self; {
 *     //        __id_static="0.677710252711198";__id_dynamic=builtins.hashFile "sha256" /Users/jeffhykin/repos/snowball/random.ignore);
 *     //        numpy = callPackage ../development/python-modules/numpy { };
 *     //        numpy_Args = callPackage ../development/python-modules/numpy/args.nix { };
 *     //        gitsrht = self.callPackage ./git.nix { };
 *     //    }
 */
function* addAttrIds(string, randomOutputFilePath) {
    const bufferFlushRate = 500 // characters
    var tree = parser.parse(string)
    tree = addWhitespaceNodes({ tree, string })
    var root = tree.rootNode
    var allNodes = flatNodeList(root)
    const attrsetExpressionId = 86
    // const openBracketId = 10
    const whitespaceId = -1
    const bindingSetId = 91
    for (const eachNode of allNodes) {
        if (eachNode.typeId == attrsetExpressionId && eachNode.children.filter(each=>each.typeId!=whitespaceId).length != 2) {
            const text = `__id_static="${Math.random()}";__id_dynamic=builtins.hashFile "sha256" ${randomOutputFilePath};\n`
            const bracketNode = eachNode.children.shift()
            eachNode.children.unshift({text})
            eachNode.children.unshift(bracketNode)
        }
    }
    let stringBuffer = ""
    for (const each of flatNodeList(root)) {
        stringBuffer += each.hasChildren ? "" : (each.text||"")
        if (stringBuffer.length > bufferFlushRate) {
            yield stringBuffer
            stringBuffer = ""
        }
    }
    yield stringBuffer
}