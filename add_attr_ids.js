import { Parser, parserFromWasm, flatNodeList, addWhitespaceNodes } from "https://deno.land/x/deno_tree_sitter@0.0.8/main.js"
import { FileSystem } from "https://deno.land/x/quickr@0.6.38/main/file_system.js"
import { run } from "https://deno.land/x/quickr@0.6.38/main/run.js"
import nix from "https://github.com/jeff-hykin/common_tree_sitter_languages/raw/4d8a6d34d7f6263ff570f333cdcf5ded6be89e3d/main/nix.js"


const { path: randomizerPath } = await startRandomizer("./random.ignore")
for (const eachFilePath of Deno.args) {
    FileSystem.read(eachFilePath).then((fileString)=>{
        FileSystem.write({ path: eachFilePath, data: addAttrIds(fileString, randomizerPath) })
    })
}


// 
// creates a file with constantly random values (subprocess)
// 
async function startRandomizer(targetPath) {
    const absPath = FileSystem.makeAbsolutePath(targetPath)
    await FileSystem.remove(absPath)
    const process = run(
        "deno",
        "eval",
        `
            const file = await Deno.open("/dev/urandom")
            const buffer = new Uint8Array(256)
            while (1) {
                file.readSync(buffer)
                const myFile = Deno.openSync(${JSON.stringify(absPath)}, { write: true, truncate:true })
                await myFile.write(new TextEncoder().encode(buffer))
                myFile.close()
            }
        `
    )
    // wait on process to create the file
    await new Promise((resolve, reject)=>{
        while (1) {
            try {
                const info = await FileSystem.info(absPath)
            } catch (error) {
                
            }
            if (info.isFile) {
                resolve()
            }
            // sleep
            await new Promise((resolve, reject)=>setTimeout(resolve, 100))
        }
    })
    return { process, path:absPath }
}


const parser = await parserFromWasm(nix)

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
    const whitespaceId = -1
    const modifiedNodes = []
    for (const each of allNodes) {
        if (each.typeId == attrsetExpressionId && each.children.filter(each=>each.typeId!=whitespaceId).length != 2) {
            each.children[1].children.unshift({
                text: `__id_static="${Math.random()}";__id_dynamic=builtins.hashFile "sha256" ${randomOutputFilePath});\n`,
            })
            modifiedNodes.push(each)
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