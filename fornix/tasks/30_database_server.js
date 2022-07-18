import { serve } from "https://deno.land/std@0.148.0/http/server.ts"


import { serve } from "https://deno.land/std@0.143.0/http/server.ts"
import { FileSystem } from ' https://deno.land/x/quickr@0.3.24/main/file_system.js'
import { allKeys, ownKeyDescriptions, allKeyDescriptions, } from "https://deno.land/x/good@0.5.14/value.js"

const homepage = await FileSystem.read(`${FileSystem.thisFolder}/../website/index.html`)

serve(async (request, connectionInfo)=>{
    const location = request.url.replace(/.+?\/\//, "").replace(/.+?\//,"")
    const method          = request.method
    const urlObject       = new URL(request.url)
    const path            = url.pathname
    const queryParameters = url.searchParams
    
    // 
    // API/publish
    // 
    if (location == 'publish') {
        if (request.body) {
            const data = JSON.parse(await request.text())
            // FIXME: handle updating all the indexes with new information
                // verify the auth signature
                // add a date
                // remove a document from the index if needed (TODO: add that functionality to the index)
                // add to the overall index if needed
                // add to the user+flavor index
            return new Response('"got it"', {
                status: 200,
            })
        }
    // 
    // API/search
    // 
    } else if (location == 'search') {
        // FIXME: perform ranking with multiple searches using the index
    // 
    // Unknown
    // 
    } else {
        return new Response('"Sorry :/"', {
            status: 404,
        })
    }
}, { port: 3000 })