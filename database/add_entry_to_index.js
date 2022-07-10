import { hash, getInnerTextOfHtml, curl } from "./utils.js"

async function addEntryToIndex({entries, index}) {
    for (const each of entries) {
        if (
            typeof each.name == 'string' && each.name
            typeof each.description == 'string' && each.description
        ) {
            const key = JSON.stringify({name: each.name, description: each.description})
            // figure out if its part of an existing name+description
            // if yes, then dont give any pre-existing words any weight
            if (key in index.packages) {
                // only add new words
                // TODO: lowish priority
            } else {
                const id = hash(key)
                // 
                // update indicies
                // 
                index.directPackageIndex.addDocument({
                    id,
                    body: each.name,
                    shouldUpdateIdf: false,
                })
                index.packageDescriptionIndex.addDocument({
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
                    index.packageReadmeIndex.addDocument({
                        id,
                        body: fullReadmeDocument,
                        shouldUpdateIdf: false,
                    })
                }
            }
        }
    }
    index.directPackageIndex.updateIdf()
    index.packageDescriptionIndex.updateIdf()
    index.packageReadmeIndex.updateIdf()
}