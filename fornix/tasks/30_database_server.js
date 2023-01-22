import { serve } from "https://deno.land/std@0.148.0/http/server.ts"
import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { allKeys, ownKeyDescriptions, allKeyDescriptions, } from "https://deno.land/x/good@0.5.14/value.js"
import * as Encryption from "https://deno.land/x/good@0.7.8/encryption.js"
import { sha256, maxVersionSorter, stableStringify, hashJsonPrimitive } from "../support/utils.js"
import { Index } from "../support/index.js"
import { createStorageObject } from "../support/data_storage.js"
import { deepCopy, allKeyDescriptions, deepSortObject, shallowSortObject } from "https://deno.land/x/good@0.7.8/value.js"

const dataPath = `${FileSystem.thisFolder}/default_data.ignore/`
const primarySearchIndex = new Index("smoke_test.ignore.json")
const entitesStorage = await createStorageObject(dataPath, "entites")
const toolStorage = await createStorageObject(dataPath, "tools")

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
    const respondWith = (data)=>new Response(JSON.stringify({value:data}), {
        status: 200,
    })
    const respondWithError = (error)=>new Response(JSON.stringify({error}), {
        status: 200,
    })
    
    const generateResponse = (async ()=>{
        // 
        // API/publish
        // 
        if (location == 'publisher/entityExists') {
            const { entityUuid } = args[0]
            if (entitesStorage.data[entityUuid]) {
                return respondWith(true)
            } else {
                return respondWith(false)
            }
        } else if (location == 'publisher/createEntity') {
            const { identification, createEntity } = args[0]
            const { publicVerificationKey, actionSignatures } = identification
            const { normalKeys, overthrowKeys, humanReadableName, email } = createEntity
            
            // 
            // check signature
            // 
                const error = validateSignature("createEntity", args[0])
                if (error instanceof Response) {
                    return error
                }

            // 
            // ensure entity doesn't already exist
            // 
                const entityUuid = hashJsonPrimitive(publicVerificationKey)
                if (entitesStorage.data[entityUuid]) {
                    // TODO: check if they're already/still in control of the entity
                    return respondWithError(Error(`
                        Sorry an entity with this id already exists, please create a new identity then try again
                    `))
                }
            
            // 
            // validate normalKeys
            // 
                if ((normalKeys instanceof Array) || !(normalKeys instanceof Object)) {
                    return respondWithError(Error(`normalKeys should be an Object that looks something like:
                        "createEntity": {
                            "normalKeys": {
                                "YOUR_ASYMMETRIC_KEY_HERE": {
                                    "hasAllPermissions": true,
                                }
                            }
                        }
                    but instead I got:\n${JSON.stringify({"createEntity": {normalKeys}},0,4)}
                    `))
                }
                if (!normalKeys[publicVerificationKey]) {
                    return respondWithError(Error(`normalKeys should be an Object that looks something like:
                        "createEntity": {
                            "normalKeys": {
                                ${JSON.stringify(publicVerificationKey)}: {
                                    "hasAllPermissions": true,
                                }
                            }
                        }
                    but instead I got:\n${JSON.stringify({"createEntity": {normalKeys}},0,4)}
                    `))
                }
                // make sure that every permission is possible, even if only by one person
                // (NOTE: right now the "hasAllPermissions" is the only permission)
                if (!Object.values(normalKeys).some(each=>each.hasAllPermissions)) {
                    return respondWithError(Error(`normalKeys should be an Object that looks something like:
                        "createEntity": {
                            "normalKeys": {
                                ${JSON.stringify(publicVerificationKey)}: {
                                    "hasAllPermissions": true,
                                }
                            }
                        }
                    
                    but there is not one single person with permission to publish
                    so um, yeah you probably want to give at least someone permission
                    
                    what I got is:\n${JSON.stringify({"createEntity": {normalKeys}},0,4)}
                    `))
                }
            
            // 
            // overthrowKeys checks
            // 
                if (!(overthrowKeys instanceof Array)) {
                    return respondWithError(Error(`OverthrowKeys was not an array. I expected something like:
                        "createEntity": {
                            "overthrowKeys": [
                                "aldkjflkasdjflajsdlfjasdlkjfaldksjf",
                                "sdlfjasdlkjfaldksjfaldkjflkasdjflaj",
                            ]
                        }
                    but instead I got:\n${JSON.stringify({"createEntity":{overthrowKeys}},0,4)}
                    `))
                }
                if (overthrowKeys.length < 2) {
                    return respondWithError(Error(`overthrowKeys needs to contain at least two keys`))
                }
                // TODO: add a signature challenge check to make sure the overthrowKeys are valid
            
            // 
            // save data!
            // 
                entitesStorage.data[entityUuid] = {
                    entityUuid,
                    email,
                    humanReadableName,
                    overthrowKeys,
                    normalKeys,
                    createdAt: (new Date()).getTime(),
                    lastEdited: (new Date()).getTime(),
                    tools: {
                        
                    },
                }
                return respondWith(entityUuid)
        } else if (location == 'publisher/updateToolInfo') {
            // 
            // check action signature
            // 
                const error = validateSignature("updateToolInfo", args[0])
                if (error instanceof Response) {
                    return error
                }
            
            
            // 
            // check owner of tool
            // 
                const { identification, updateToolInfo } = args[0]
                const error = validatePermission({ identification, action })
                if (error instanceof Response) {
                    return error
                }
                
                const { toolName, data } = updateToolInfo
                const entityUuid = identification.entityUuid || hashJsonPrimitive(identification.publicVerificationKey)
                let { blurb, description, keywords, maintainers, links, adjectives } = data
                
            // 
            // get tool data
            // 
                const toolId = `${toolName}@${entityUuid}`
                const toolData = {
                    blurb: "",
                    keywords: [],
                    maintainers: [],
                    description: null,
                    links: {},
                    adjectives: {},
                    ...toolStorage.data[toolId],
                }
            
            // 
            // create data update
            // 
                // 
                // blurb
                // 
                    if (blurb && typeof blurb == 'string') {
                        toolData.blurb = blurb
                    }
                    if (blurb == null) {
                        toolData.blurb = ""
                    }
                // 
                // description
                // 
                    if (description && typeof description == 'string') {
                        toolData.description = description
                    }
                    if (description == null) {
                        toolData.description = ""
                    }
                // 
                // keywords
                // 
                    if (keywords instanceof Array) {
                        keywords = keywords.filter(each=>typeof each == "string")
                        if (keywords) {
                            toolData.keywords = keywords
                        }
                    }
                    if (keywords == null) {
                        toolData.keywords = []
                    }
                // 
                // maintainers
                // 
                    if (maintainers instanceof Array) {
                        if (maintainers) {
                            toolData.maintainers = maintainers
                        }
                    }
                    if (maintainers == null) {
                        toolData.maintainers = []
                    }
                // 
                // links
                // 
                    if (links instanceof Object) {
                        if (links) {
                            toolData.links = links
                        }
                    }
                    if (links == null) {
                        toolData.links = {}
                    }
                // 
                // adjectives
                // 
                    if (adjectives instanceof Object) {
                        if (adjectives) {
                            toolData.adjectives = adjectives
                        }
                    }
                    if (adjectives == null) {
                        toolData.adjectives = {}
                    }
                    // FIXME: validate the adjectives, camel case
            
            // 
            // save/update data
            // 
                // update tool data
                const lastEdited = (new Date()).getTime()
                toolStorage.data[toolId] = {...toolData, lastEdited}
                
                // update entity data
                const entityData = entitesStorage.data[entityUuid]
                entitesStorage.data[entityUuid] = {
                    ...entityData,
                    tools: {
                        ...entityData.tools,
                        [toolName]: {
                            ...entityData.tools[toolName],
                            lastEdited,
                        },
                    }
                }
                
                // update search information
                await primarySearchIndex.addEntriesToIndex([
                    {
                        toolName,
                        entityUuid,
                        blurb: toolData.blurb,
                        description: toolData.description,
                        keywords: toolData.keywords,
                    },
                ])
                
                // FIXME: document update
                // FIXME: entity update (ensure tool exists on entity)
                
        } else if (location == 'publisher/newReleaseInfo') {
        
        
        
        
        
        
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




function validateSignature(action, payload) {
    const { identification } = payload
    const { publicVerificationKey, actionSignatures } = identification
    if (!publicVerificationKey || !actionSignatures[action]) {
        return respondWithError(Error(`

        You're calling the ${action} endpoint. However, I don't see a verification signature.
        For example:

            "identification": {
                "publicVerificationKey": ${JSON.stringify(publicVerificationKey)},
                "actionSignatures": {
                    "${action}": "THIS IS WHAT IS MISSING"
                }
            },
            "${action}": ${JSON.stringify(payload[action],0,4)}
        `))
    }

    const signatureIsValid = await Encryption.verify({
        signedMessage: actionSignatures[action],
        whatMessageShouldBe: JSON.stringify(payload[action]),
        publicKey: publicVerificationKey,
    })
    if (!signatureIsValid) {
        return respondWithError(Error(`
            (all values are json-stringified here to make whitespace visible)
            I was given this message: ${JSON.stringify(actionSignatures[action])}
            Supposedly signed with this key: ${JSON.stringify(publicVerificationKey)}
            Which should generate this message: ${JSON.stringify(createEntity)}
            However, it fails the signature check.
            Signatures are expected to be done with the following format:
                name: "RSASSA-PKCS1-v1_5",
                modulusLength: 4096, //can be 1024, 2048, or 4096
                publicExponent: new Uint8Array([0x01, 0x00, 0x01]),
                hash: { name: "SHA-256" },
        `))
    }
}

function validatePermission({ identification, action }) {
    let { publicVerificationKey, entityUuid } = identification
    // if not given, use the default of the available key
    entityUuid = entityUuid || hashJsonPrimitive(publicVerificationKey)
    // make sure the entity exists
    if (!entitesStorage.data[entityUuid]) {
        if (identification.entityUuid) {
            return respondWithError(Error(`
                You're performing ${JSON.stringify(action)} as entity ${JSON.stringify(entityUuid)}
                However, it would appear that ${JSON.stringify(entityUuid)} doesn't exist
            `))
        } else {
            return respondWithError(Error(`
                You're performing ${JSON.stringify(action)} as entity ${JSON.stringify(entityUuid)}
                (which is the default entity for your idenity/publicVerificationKey)
                (FYI entities can be groups/transferable, identities are just one person)
                However, it would appear that ${JSON.stringify(entityUuid)} doesn't exist
            `))
        }
    } else {
        const { normalKeys } = entitesStorage.data[entityUuid]
        if (!normalKeys[publicVerificationKey]?.hasAllPermissions) {
            return respondWithError(Error(`
                You're performing ${JSON.stringify(action)} as entity ${JSON.stringify(entityUuid)}
                However, that entity doesn't seem to give you permission to do this.
                
                Hopefully, this is a malicious attack and you're being correctly blocked
                More likely though is one of the following cases:
                1.Somehow the entityUuid got messed up. It is normally auto-generated from your
                    identity/publicVerificationKey, so I bet its being passed manually for 
                    some reason
                2.This identity/publicVerificationKey used to have permissions for this entity
                    but someone (maybe you) used the overthrowKeys and changed the permissions.
                    This would be good if someone stole this identity, but not your overthrowKeys
                    meaning maybe you're using the wrong/outdated identity/publicVerificationKey.
                    However, on the flip side it could be quite bad, as it means someone could've
                    stolen your overthrowKeys, and kicked you out of your own entity.
            `))
        }
    }
}