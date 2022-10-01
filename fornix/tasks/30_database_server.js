import { serve } from "https://deno.land/std@0.148.0/http/server.ts"
import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { allKeys, ownKeyDescriptions, allKeyDescriptions, } from "https://deno.land/x/good@0.5.14/value.js"
import * as Encryption from "https://deno.land/x/good@0.7.2/encryption.js"
import { sha256, maxVersionSorter, stableStringify } from "../support/utils.js"
import { Index } from "../support/index.js"
import { load } from "../support/data_storage.js"
import { deepCopy, allKeyDescriptions, deepSortObject, shallowSortObject } from "https://deno.land/x/good@0.7.2/value.js"

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
    const args = []
    if (request.body) {
        try {
            args = JSON.parse(await request.text()).args
        } catch (error) {}
    }
    
    const generateResponse = (async ()=>{
        // 
        // API/publish
        // 
        if (location == 'publisher/publish/flavor') {
            // FIXME: validate a flavor:
                // mainIdentity: "example_identity",
                // flavorSignature: "",
                // flavor: {
                //     frozenData: {
                //         toolName: "exampleTool",
                //         flavorName: "stable",
                //         blurb: "An example tool for demonstrating how publishing packages work",
                //         licenses: [],
                //     },
                //     dynamicData: {
                //         homepage: "",
                //         icon: null,
                //         iframeSrc: null,
                //         maintainers: [],
                //         adjectives: {
                //             openSource: true,
                //             FOSS: true,
                //         },
                //     },
                // }
            
            // 
            // validate structure
            // 
                // FIXME:
                    // toolName
                    // flavorName
                    // licenses
                    // blurb
            
            // 
            // validate signature
            // 
                // FIXME
            
            // 
            // add to user-info
            // 
                // flavorId = hash(data.frozenData)
                // oldFlavor = users[data.mainIdentity].flavors[flavorId]
                // if overwriting old flavor
                    // update the storage lists
                
        if (location == 'publisher/publish/package') {
            const data = args[0]
            // FIXME: new format
                // mainIdentity: "example_identity",
                // flavorSignature: "",
                // package: {
                //     toolName: "exampleTool",
                //     flavorReference: "example_identity@exampleTool@stable",
                //     version: [ 1,3,5,6 ],
                //     source: {
                //         "url": "https://github.com/NixOS/nixpkgs/archive/e696cfa9eae0d973126399f90d2e1fd87b980ced.zip", # when URL is downloaded
                //         "format": "zip",
                //         "downloadHashSha256": "aldksfj0io34j3408t3o59t",
                //         "internalTargets": {
                //             "nixRootFolder": ".",
                //             "nixAttributePath": [],
                //         },
                //         "customInfo": {
                //             "date": "2021-02-24",
                //             "position": "/nix/store/hqc8hlzsl1qyzdyam91kvj1ww22yw538-6c36c4ca061f0c85eed3c96c0b3ecc7901f57bb3.tar.gz/pkgs/development/interpreters/python/cpython/2.7/default.nix:291",
                //             links: {
                //                 homepage: null,
                //                 icon: null,
                //                 iframeSrc: null,
                //             },
                //             description: null,
                //             maintainers: [],
                //             adjectives: {
                //                 custom: {},
                //                 nixpkgs: {
                //                     automatedCreation: true,
                //                     unfree: null,
                //                     insecure: null,
                //                     broken: null,
                //                 },
                //                 generallySupports: {},
                //                 exactlySupports: {
                //                     "nix": null,
                //                     "arm64Linux": null,
                //                     "armv5telLinux": null,
                //                     "armv6lLinux": null,
                //                     "armv7aLinux": null,
                //                     "armv7lLinux": null,
                //                     "mipselLinux": null,
                //                     "32bitX86Cygwin": null,
                //                     "32bitX86Freebsd": null,
                //                     "32bitX86Linux": null,
                //                     "32bitX86Netbsd": null,
                //                     "32bitX86Openbsd": null,
                //                     "64bitX86Cygwin": null,
                //                     "64bitX86Freebsd": null,
                //                     "64bitX86Linux": null,
                //                     "64bitX86Netbsd": null,
                //                     "64bitX86Openbsd": null,
                //                     "64bitX86Solaris": null,
                //                     "64bitX86Mac": null,
                //                     "32bitX86Mac": null,
                //                     "arm64Mac": null,
                //                     "armv7aMac": null,
                //                     "64bitX86Windows": null,
                //                     "32bitX86Windows": null,
                //                     "wasm64Wasi": null,
                //                     "wasm32Wasi": null,
                //                     "64bitX86Redox": null,
                //                     "powerpc64Linux": null,
                //                     "powerpc64leLinux": null,
                //                     "riscv32Linux": null,
                //                     "riscv64Linux": null,
                //                     "armNone": null,
                //                     "armv6lNone": null,
                //                     "arm64None": null,
                //                     "avrNone": null,
                //                     "32bitX86None": null,
                //                     "64bitX86None": null,
                //                     "powerpcNone": null,
                //                     "msp430None": null,
                //                     "riscv64None": null,
                //                     "riscv32None": null,
                //                     "vc4None": null,
                //                     "or1kNone": null,
                //                     "mmixMmixware": null,
                //                     "jsGhcjs": null,
                //                     "arm64Genode": null,
                //                     "32bitX86Genode": null,
                //                     "64bitX86Genode": null,
                //                 },
                //             },
                //         },
                //     }
                //         # {
                //         #     "url": "https://github.com/NixOS/nixpkgs.git",
                //         #     "format": "git",
                //         #     "internalTargets": {
                //         #         "gitCommit": "e696cfa9eae0d973126399f90d2e1fd87b980ced",
                //         #         "nixRootFolder": ".",
                //         #         "nixAttributePath": [],
                //         #     },
                //         #     "customInfo": {
                //         #         "date": "2021-02-24",
                //         #         "position": "/nix/store/hqc8hlzsl1qyzdyam91kvj1ww22yw538-6c36c4ca061f0c85eed3c96c0b3ecc7901f57bb3.tar.gz/pkgs/development/interpreters/python/cpython/2.7/default.nix:291",
                //         #     },
                //         # }
                // }
            
            // 
            // validate signature
            // 
                // FIXME
            
            // 
            // validate flavorReference
            // 
                // FIXME
            
            // 
            // update storages
            // 
                // FIXME
            
            // 
            // update user support info
            // 
                // packageHash = hash(data.package)
                // users[data.mainIdentity].packages.add(packageHash)
        // 
        // old
        // 

            // 
            // validate
            // 
            // TODO: validate that the given public key can unlock the lock, and that the result is the hash of the published data
            if (!(data.name && data.blurb && data.flavor && data.sources && data.publicationSignatures)) { // FIXME: make this a more rigourous check
                throw {
                    error: "name, blurb, flavor, sources, or publicationSignatures was empty/null/missing from the following object",
                    data,
                }
            }
            const dataCopy = {...data}
            delete dataCopy.publicationSignatures
            const text = JSON.stringify(dataCopy)
            for (const [key, value] of Object.entries(data.publicationSignatures)) {
                const {signature} = value
                const isValid = await Encryption.verify({
                    signedMessage: signed,
                    whatMessageShouldBe: text,
                    publicKey: key, 
                })
                if (!isValid) {
                    throw {
                        "error": "it appears one of the signatures failed the validation check for its respective public key",
                        data: {
                            failedKey: key,
                            failedSignature: signedMessage,
                            messageWithoutSignature: text,
                            allSignatures: data.publicationSignatures,
                        }
                    }
                }
                const dataCopy = {...data}
                delete dataCopy.publicationSignatures
                const text = JSON.stringify(dataCopy)
                for (const [key, value] of Object.entries(data.publicationSignatures)) {
                    const {signature} = value
                    const isValid = await Encryption.verify({
                        signedMessage: signed,
                        whatMessageShouldBe: text,
                        publicKey: key, 
                    })
                    if (!isValid) {
                        throw {
                            "error": "it appears one of the signatures failed the validation check for its respective public key",
                            "data": {
                                failedKey: key,
                                failedSignature: signedMessage,
                                messageWithoutSignature: text,
                                allSignatures: data.publicationSignatures, 
                            },
                        }
                    }
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
                
                // FIXME: handle updating all the indexes with new information
                    // verify the auth signature
                    // add a date
                    // remove a document from the index if needed (TODO: add that functionality to the index)
                    // add to the overall index if needed
                    // add to the user+flavor index
                return { "value": "got it" }
        // 
        // getters
        // 
        } else if (location == 'get/names') {
            return [...names]
        } else if (location == 'get/blurbs') {
            const data = args[0]
            return blurbs[data.name] || []
        } else if (location == 'get/flavors') {
            const data = args[0]
            const id = await sha256(JSON.stringify({blurb: data.blurb, name: data.name}))
            const flavors = Object.values(flavors[id])
            flavors.sort(maxVersionSorter(each=>each.versionAsList))
            return flavors
        } else if (location == 'get/sources') {
            const data = args[0]
            const flavoredId = await sha256(JSON.stringify({blurb: data.blurb, flavor: data.flavor, name: data.name, }))
            return sources[flavoredId]
        // 
        // search
        // 
        } else if (location == 'search/name') {
            // FIXME
        } else if (location == 'search/id') {
            // FIXME
        } else if (location == 'search/version') {
            // FIXME: perform ranking with multiple searches using the index
        // 
        // Unknown
        // 
        } else {
            throw Error(`I'm not sure what part of the API you're trying to use (I don't recognize ${location}): AKA Error 404`)
        }
    })
    
    // 
    // wrap output in a response
    // 
    try {
        const object = await generateResponse()
        return new Response(JSON.stringify({value:object}), {
            status: 200,
        })
    } catch (error) {
        if (error instanceof Error) {
            return new Response(JSON.stringify({error:error.message, args}), {
                status: 400,
            })
        } else {
            return new Response(JSON.stringify(error), {
                status: 400,
            })
        }
    }
    
    
}, { port: 3000 })