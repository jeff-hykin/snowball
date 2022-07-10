import { serve } from "https://deno.land/std@0.143.0/http/server.ts"
import { FileSystem } from ' https://deno.land/x/quickr@0.3.24/main/file_system.js'
import { allKeys, ownKeyDescriptions, allKeyDescriptions, } from "https://deno.land/x/good@0.5.14/value.js"

const homepage = await FileSystem.read(`${FileSystem.thisFolder}/../website/index.html`)

serve(async (request, connectionInfo)=>{
    const location = request.url.replace(/.+?\/\//, "").replace(/.+?\//,"")
    
    // 
    // Home
    // 
    if (location == '') {
        return new Response(homepage,  {
            status: 200,
        })
    // 
    // API/publish
    // 
    } else if (location == 'publish') {
        return new Response('"got it"', {
            status: 200,
        })
    // 
    // Unknown
    // 
    } else {
        return new Response('"Sorry :/"', {
            status: 404,
        })
    }
}, { port: 3000 })