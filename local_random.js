import { serve } from "https://deno.land/std@0.143.0/http/server.ts"
import { binaryify, bytesToString } from "https://deno.land/x/binaryify@2.2.0.2/tools.js"
import { FileSystem } from ' https://deno.land/x/quickr@0.3.24/main/file_system.js'
import { allKeys, ownKeyDescriptions, allKeyDescriptions, } from "https://deno.land/x/good@0.5.14/value.js"

const file = await Deno.open("/dev/urandom")
const buffer = new Uint8Array(256)
while (1) {
    file.readSync(buffer)
    const myFile = Deno.openSync("./random.ignore", { write: true, truncate:true })
    await myFile.write(new TextEncoder().encode(buffer))
    myFile.close()
}