const { FileSystem } = await import(`https://deno.land/x/quickr@0.3.24/main/file_system.js`)

import { createHash } from "https://deno.land/std@0.139.0/hash/mod.ts"
export const hashJsonPrimitive = (value) => createHash("md5").update(JSON.stringify(value)).toString()

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