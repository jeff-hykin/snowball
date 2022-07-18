import { FileSystem } from "https://deno.land/x/quickr@0.3.34/main/file_system.js"
import { DOMParser, Element, } from "https://deno.land/x/deno_dom/deno-dom-wasm.ts"
import { createHash } from "https://deno.land/std@0.139.0/hash/mod.ts"

export const tempFolder = `${FileSystem.thisFolder}/../cache.ignore/`
await FileSystem.ensureIsFolder(tempFolder)

export const hashJsonPrimitive = (value) => createHash("md5").update(JSON.stringify(value)).toString()

export function hash(string) {
    return parseInt(sha256(string, 'utf-8', 'hex'), 16) 
}

export function getInnerTextOfHtml(htmlText) {
    const doc = new DOMParser().parseFromString(htmlText,
        "text/html",
    )
    return doc.body.innerText
}

export const curl = async url=> new Promise(resolve => { 
    fetch(url).then(res=>res.text()).then(body=>resolve(body))
})

export async function jsonRead(path) {
    let jsonString = await FileSystem.read(path)
    let output
    try {
        output = JSON.parse(jsonString)
    } catch (error) {
        // if corrupt, delete it
        if (typeof jsonString == 'string') {
            await FileSystem.remove(path)
        }
    }
    return output
}

