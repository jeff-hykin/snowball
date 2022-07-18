import { FileSystem } from "https://deno.land/x/quickr@0.3.34/main/file_system.js"
import { hash, getInnerTextOfHtml, curl } from "./utils.js"

function tokenizeWords(text) {
    return text.toLowerCase()
        .replace(/'(s|t|nt)\b/g, '$1')
        .replace(/[^a-z0-9]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim()
        .split(' ')
}

function tokenizeChunks(text) {
    let currentChunk = ""
    let outputs = []
    for (const each of [...text]) {
        currentChunk += each
        if (currentChunk.length > 2) {
            outputs.push(currentChunk)
        }
        currentChunk = currentChunk.slice(0,3)
    }
    return outputs
}

function tokenizeChunksAndWords(text) {
    return tokenizeChunks(string).concat(tokenizeWords(string))
}

class Bm25Index {
    constructor({tokenizer=null, b=0.75, k1=1.2, }) {
        this.documents = {}
        this.totalDocumentTermLength = 0
        this.averageDocumentLength = 0
        this.terms = {}
        this.b = b // See: https://www.elastic.co/blog/practical-bm25-part-3-considerations-for-picking-b-and-k1-in-elasticsearch
        this.k1 = k1
        this.tokenizer = tokenizer || (string)=>string.split(/ +|\b/)
    }
    get totalDocuments() {
        return Object.keys(this.documents).length
    }
    addDocument({id, body, shouldUpdateIdf=true}) {
        // TODO: generate an ID automatically based on hashing the body

        if (id === undefined) { throw new Error(1000, 'ID is a required property of documents.'); }
        if (body === undefined) { throw new Error(1001, 'Body is a required property of documents.'); }
        
        // end if weve already seen the document
        if (id in this.documents) {
            return
        }

        const tokens = tokenizeWords(body)
        const documentTerms = {} // Will hold unique terms and their counts and frequencies
        const indexForDoc = { // indexForDoc will eventually be added to the documents database
            id,
            terms: documentTerms,
            termCount: tokens.length,
        }
        

        // Readjust averageDocumentLength
        this.totalDocumentTermLength += indexForDoc.termCount
        this.averageDocumentLength = this.totalDocumentTermLength / this.totalDocuments

        // Calculate term frequency
        // First get terms count
        for (const term of tokens) {
            if (!documentTerms[term]) { 
                documentTerms[term] = {
                    count: 0,
                    freq: 0
                }
            }
            documentTerms[term].count++
        }

        // Then re-loop to calculate term frequency.
        // We'll also update inverse document frequencies here.
        for (const term of Object.keys(documentTerms)) {
            // Term Frequency for this document.
            documentTerms[term].freq = documentTerms[term].count / indexForDoc.termCount

            // Inverse Document Frequency initialization
            if (!this.terms[term]) {
                this.terms[term] = {
                    inverseCount: 0, // Number of docs this term appears in, uniquely
                    idf: 0
                }
            }

            this.terms[term].inverseCount++
        }

        // Calculate inverse document frequencies
        // This is O(N) so if you want to index a big batch of documents,
        // comment this out and run it once at the end of your addDocuments run
        // If you're only indexing a document or two at a time you can leave this in.
        if (shouldUpdateIdf) {
            this.updateIdf()
        }

        // Add indexForDoc to docs db
        this.documents[indexForDoc.id] = indexForDoc
    }
    updateIdf() {
        for (const term of Object.keys(this.terms)) {
            const num = this.totalDocuments - this.terms[term].inverseCount + 0.5
            const denom = this.terms[term].inverseCount + 0.5
            this.terms[term].idf = Math.max(Math.log10(num / denom), 0.01)
        }
    }
    search(query, numberOfResults=50) {
        const queryTerms = tokenizeWords(query)
        const results = []
        
        let worstAcceptableScore = 0
        
        // Look at each document in turn. There are better ways to do this with inverted indices.
        for (const [id, doc] of Object.entries(this.documents)) {
            // The relevance score for a document is the sum of a tf-idf-like
            // calculation for each query term.
            let score = 0

            // Calculate the score for each query term
            for (const queryTerm of queryTerms) {
                // We've never seen this term before so IDF will be 0.
                // Means we can skip the whole term, it adds nothing to the score
                // and isn't in any document.
                if (this.terms[queryTerm] === undefined) {
                    continue
                }

                // This term isn't in the document, so the TF portion is 0 and this
                // term contributes nothing to the search score.
                if (doc.terms[queryTerm] === undefined) {
                    continue
                }

                // The term is in the document, let's go.
                // The whole term is :
                // IDF * (TF * (k1 + 1)) / (TF + k1 * (1 - b + b * docLength / avgDocLength))

                // IDF is pre-calculated for the whole docset.
                const idf = this.terms[queryTerm].idf
                // Numerator of the TF portion.
                const num = doc.terms[queryTerm].count * (this.k1 + 1)
                // Denomerator of the TF portion.
                const denom = doc.terms[queryTerm].count + (this.k1 * (1 - this.b + (this.b * doc.termCount / this.averageDocumentLength)))

                // Add this query term to the score
                score += idf * num / denom
            }
            
            if (score > 0) {
                if (results.length < numberOfResults) {
                    results.push({id: doc.id, score})
                } else if (score > worstAcceptableScore) {
                    // first time here?=>calculate worst score
                    if (worstAcceptableScore == 0) {
                        worstAcceptableScore = Math.min(...results.map(each=>each.score))
                    }
                    results.push({id: doc.id, score})
                    worstAcceptableScore = score
                    results = results.filter(({score})=>score>=worstAcceptableScore) // technically doesn't guarentee that the size will stay at numberOfResults
                }
            }
        }

        results.sort((a, b)=>b.score-a.score)
        return results.slice(0, numberOfResults)
    }
}


class Index {
    constructor(path) {
        this.packages = new Map()
        this.directPackageIndex      = new Bm25Index({ tokenizer: tokenizeChunksAndWords })
        this.packageDescriptionIndex = new Bm25Index({ tokenizer: tokenizeChunksAndWords })
        this.packageReadmeIndex      = new Bm25Index({ tokenizer: tokenizeWords })
        this.path = path
        if (path) {
            const itemInfo = FileSystem.info()
            // load all data if file exists
            if (itemInfo.exists) {
                const fileAsString = Deno.readTextFileSync(path)
                const obj = JSON.parse(fileAsString)
                Object.assign(this, obj)
            }
        }
    }

    async updateIdf() {
        this.directPackageIndex.updateIdf()
        this.packageDescriptionIndex.updateIdf()
        this.packageReadmeIndex.updateIdf()
    }

    async query(string, numberOfResults) {
        const wordsAndChunks = tokenizeChunksAndWords(string)
        const directPackageIndexResults      = this.directPackageIndex.search(query, numberOfResults).map(     each=>({...each,  directPackageScore:      each.score}))
        const packageDescriptionIndexResults = this.packageDescriptionIndex.search(query, numberOfResults).map(each=>({...each,  packageDescriptionScore: each.score}))
        const packageReadmeIndexResults      = this.packageReadmeIndex.search(query, numberOfResults).map(     each=>({...each,  packageReadmeScore:      each.score}))
        
        const allResults = directPackageIndexResults.concat(packageDescriptionIndexResults, packageReadmeIndexResults)

        const resultsById = {}
        for (let each of allResults) {
            resultsById[each.id] = {...resultsById[each.id], ...each}
        }
        
        const unsortedCombinedResults = Object.values(resultsById)
        unsortedCombinedResults.sort((a,b)=>{
            // b-a => bigger goes to element 0
            const firstLevel  = b.directPackageScore      - a.directPackageScore
            const secondLevel = b.packageDescriptionScore - a.packageDescriptionScore 
            const thirdLevel  = b.packageReadmeScore      - a.packageReadmeScore 
            if (firstLevel !== 0) {
                return firstLevel
            } else if (secondLevel !== 0) {
                return secondLevel
            } else {
                return thirdLevel
            }
        })
        
        const outputList = []
        for (let each of unsortedCombinedResults) {
            outputList.append({
                package: this.packages.get(each.id), // TODO: consider making this read from disk so that not all packages remain in memory)
                score: [directPackageScore,packageDescriptionScore,packageReadmeScore],
            })
        }
        return outputList
    }

    async function addEntriesToIndex(entries) {
        for (const each of entries) {
            if (
                typeof each.name == 'string' && each.name
                typeof each.description == 'string' && each.description
            ) {
                const key = JSON.stringify({name: each.name, description: each.description})
                const id = hash(key)
                // figure out if its part of an existing name+description
                // if yes, then dont give any pre-existing words any weight
                if (id in this.packages) {
                    // only add new words
                    // TODO: lowish priority
                } else {
                    // 
                    // update indicies
                    // 
                    this.directPackageIndex.addDocument({
                        id,
                        body: each.name,
                        shouldUpdateIdf: false,
                    })
                    this.packageDescriptionIndex.addDocument({
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
                        this.packageReadmeIndex.addDocument({
                            id,
                            body: fullReadmeDocument,
                            shouldUpdateIdf: false,
                        })
                    }
                }
            }
        }
        this.directPackageIndex.updateIdf()
        this.packageDescriptionIndex.updateIdf()
        this.packageReadmeIndex.updateIdf()
    }

    async function removeEntriesFromIndex(entries) {
        // FIXME
    }

    async save(path) {
        return FileSystem.write({
            path: this.path,
            data: JSON.stringify(this),
        })
    }
}