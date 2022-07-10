import { sha256 } from "https://denopkg.com/chiefbiiko/sha256@v1.0.0/mod.ts"
import { DOMParser, Element, } from "https://deno.land/x/deno_dom/deno-dom-wasm.ts"
import { tokenizeWords, tokenizeChunksAndWords, Bm25Index } from "./bm25.js"

function hash(string) {
    return parseInt(sha256(string, 'utf-8', 'hex'), 16) 
}

function getInnerTextOfHtml(htmlText) {
    const doc = new DOMParser().parseFromString(htmlText,
        "text/html",
    )
    return doc.body.innerText
}

var curl = async url=> new Promise(resolve => { 
    fetch(url).then(res=>res.text()).then(body=>resolve(body))
})

// TODO:
    // make index save to files
    // load index from files if not given as argumetn


const packages = new Map()
const directPackageIndex      = new Bm25Index({ tokenizer: tokenizeChunksAndWords })
const packageDescriptionIndex = new Bm25Index({ tokenizer: tokenizeChunksAndWords })
const packageReadmeIndex      = new Bm25Index({ tokenizer: tokenizeWords })

async function addEntryToIndex(entries) {
    for (const each of entries) {
        if (
            typeof each.name == 'string' && each.name
            typeof each.description == 'string' && each.description
        ) {
            const key = JSON.stringify({name: each.name, description: each.description})
            // figure out if its part of an existing name+description
            // if yes, then dont give any pre-existing words any weight
            if (key in packages) {
                // only add new words
                // TODO: lowish priority
            } else {
                const id = hash(key)
                // 
                // update indicies
                // 
                directPackageIndex.addDocument({
                    id,
                    body: each.name,
                    shouldUpdateIdf: false,
                })
                packageDescriptionIndex.addDocument({
                    id,
                    body: each.description,
                    shouldUpdateIdf: false,
                })
                
                let fullReadmeDocument = ""
                // add keywords if given
                if (each.keywords instanceof Array) {
                    fullReadmeDocument += each.keywords.join(" ")
                }
                
                if (typeof each.readmeUrl == 'string' && each.readmeUrl) {
                    fullReadmeDocument += getInnerTextOfHtml(await curl(each.readmeUrl))
                }
                
                if (fullReadmeDocument) {
                    packageReadmeIndex.addDocument({
                        id,
                        body: fullReadmeDocument,
                        shouldUpdateIdf: false,
                    })
                }
            }
        }
    }
    directPackageIndex.updateIdf()
    packageDescriptionIndex.updateIdf()
    packageReadmeIndex.updateIdf()
}