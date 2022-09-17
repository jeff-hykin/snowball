import { serve } from "https://deno.land/std@0.148.0/http/server.ts"
import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { allKeys, ownKeyDescriptions, allKeyDescriptions, } from "https://deno.land/x/good@0.5.14/value.js"
import { sha256, maxVersionSorter, stableStringify } from "../support/utils.js"
import { Index } from "../support/index.js"
import { load } from "../support/data_storage.js"

const { names, blurbs, flavors, sources, ids } = await load({ folder: `${FileSystem.thisFolder}/default_data.ignore/` })
const index = new Index("smoke_test.ignore.json")
await index.addEntriesToIndex([
    {
        name: "howdy",
        description: "a demo package used for smoke testing the bm25 based index",
    },
    {
        name: "python3",
        description: "the latest python",
    },
    {
        name: "ruby",
        description: "A programming language by Matz",
    },
])

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
            // 
            // validate
            // 
            // TODO: validate that the given public key can unlock the lock, and that the result is the hash of the published data
            if (!(data.name && data.blurb && data.flavor && data.sources && data.publicationSignatures)) { // FIXME: make this a more rigourous check
                return new Response(`{ "error": [ "name, blurb, flavor, sources, or publicationSignatures was empty/null/missing from the following object", ${JSON.stringify(data)} ], }`, {
                    status: 400,
                })
            }

            // 
            // standardize the format
            // 
            data.unixDate = (new Date()).getTime()
            data.flavor = {
                inputs: {},
                outputs: {},
                versionAsList: [],
                versionAsString: "",
                ...data.flavor,
            }
            data.sources = data.sources.map(each=>({...each, provider: Object.keys(data.publicationSignatures)}))
            data = deepSortObject(data)
            
            // 
            // get hash ID's
            // 
            const id = await sha256(JSON.stringify({blurb: data.blurb, name: data.name}))
            const flavorId = await sha256(JSON.stringify(data.flavor))
            const flavoredId = await sha256(JSON.stringify({ blurb: data.blurb, flavor: data.flavor, name: data.name,}))

            // 
            // update storage
            // 
                // 
                // name
                // 
                names.add(data.name)

                // 
                // blurbs
                // 
                blurbs[data.name] = [...new Set([ ...blurbs[data.name], data.blurb ])]

                // 
                // flavors
                // 
                flavors[id] = flavors[id] || {}
                flavors[id][flavorId] = flavor

                // 
                // sources
                // 
                sources[flavoredId] = sources[flavoredId] || {}
                Object.assign(
                    sources[flavoredId],
                    Object.fromEntries(
                        newSources.map(
                            eachSource=>[ await sha256(stableStringify(eachSource)), eachSource ]
                        )
                    ),
                )
                
                // 
                // ids
                // 
                ids[id] = {
                    blurb: data.blurb,
                    name: data.name,
                }
            
            // FIXME: handle updating all the indexes with new information
                // verify the auth signature
                // add a date
                // remove a document from the index if needed (TODO: add that functionality to the index)
                // add to the overall index if needed
                // add to the user+flavor index
            return new Response('{ "value": "got it" }', {
                status: 200,
            })
        }
    // 
    // getters
    // 
    } else if (location == 'get/names') {
        return new Response(JSON.stringify([...names]), {status: 200,})
    } else if (location == 'get/blurbs') {
        const data = JSON.parse(await request.text()).args[0]
        return new Response(JSON.stringify({ data: blurbs[data.name] || []}), {status: 200,})
    } else if (location == 'get/flavors') {
        const data = JSON.parse(await request.text()).args[0]
        const id = await sha256(JSON.stringify({blurb: data.blurb, name: data.name}))
        const flavors = Object.values(flavors[id])
        flavors.sort(maxVersionSorter(each=>each.versionAsList))
        return new Response({data: JSON.stringify(flavors)}, {status: 200,})
    } else if (location == 'get/sources') {
        const data = JSON.parse(await request.text()).args[0]
        const flavoredId = await sha256(JSON.stringify({blurb: data.blurb, flavor: data.flavor, name: data.name, }))
        return new Response(JSON.stringify({data: sources[flavoredId]}), {status: 200,})
    // 
    // search
    // 
    } else if (location == 'search/name') {
        
    } else if (location == 'search/id') {
        
    } else if (location == 'search/version') {
        
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