import { FileSystem } from "https://deno.land/x/quickr@0.3.34/main/file_system.js"
import { sha256, maxVersionSorter, getInnerTextOfHtml, curl } from "./utils.js"

function tokenizeWords(text) {
    return text.toLowerCase()
        .replace(/'(s|t|nt)\b/g, '$1')
        .replace(/[^a-z0-9]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim()
        .split(' ')
}

function tokenizeChunks(text) {
    const chunkSize = 3
    let currentChunk = ""
    let outputs = []
    for (const eachChar of [...text]) {
        currentChunk += eachChar
        if (currentChunk.length > chunkSize) {
            currentChunk = currentChunk.slice(-chunkSize)
        }
        if (currentChunk.length == chunkSize) {
            outputs.push(currentChunk)
        }
    }
    return outputs
}

function tokenizeChunksAndWords(text) {
    return tokenizeWords(text).concat(tokenizeChunks(text))
}

const specialChar = "🔣"
function tokenizeChunksAndSpecialSplits(text) {
    return text.split(specialChar).concat(tokenizeChunksAndWords(text))
}

class Bm25Index {
    constructor({tokenizer=null, b=0.75, k1=1.2, }) {
        this.documents = {}
        this.totalDocumentTermLength = 0
        this.averageDocumentLength = 0
        this.terms = {}
        this.b = b // See: https://www.elastic.co/blog/practical-bm25-part-3-considerations-for-picking-b-and-k1-in-elasticsearch
        this.k1 = k1
        this.tokenizer = tokenizer || ((string)=>string.split(/ +|\b/))
    }
    get totalDocuments() {
        return Object.keys(this.documents).length
    }
    addDocument({id, body, shouldUpdateIdf=true}) {
        if (id === undefined) { throw new Error(1000, 'ID is a required property of documents.'); }
        if (body === undefined) { throw new Error(1001, 'Body is a required property of documents.'); }
        
        // end if weve already seen the document
        if (id in this.documents) {
            return
        }

        const tokens = this.tokenizer(body)
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
        const resultsById = {}
        // main results
        const resultsFromWords  = this.innerSearch(query, numberOfResults, tokenizeWords)
        // sparse results
        const newNumberOfResults = resultsFromWords.length + (numberOfResults-resultsFromWords.length) // larger because of possible duplicates
        const resultsFromChunks = this.innerSearch(query, newNumberOfResults, tokenizeChunks)

        for (const each of resultsFromWords) {
            resultsById[each.id] = {
                id: each.id,
                wordScore: each.score,
            }
        }
        for (const each of resultsFromChunks) {
            resultsById[each.id] = {
                ...resultsById[each.id],
                id: each.id,
                chunkScore: each.score,
            }
        }
        const values = Object.values(resultsById).map(
            each=>({
                id: each.id,
                score: [ each.wordScore||0, each.chunkScore||0 ],
            })
        )
        values.sort(maxVersionSorter(each=>each.score))
        return values
    }

    innerSearch(query, numberOfResults=50, tokenizer=tokenizeChunks) {
        const queryTerms = tokenizer(query)
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
        this.tools = new Map()
        this.directToolIndex           = new Bm25Index({ tokenizer: tokenizeChunksAndWords })
        this.toolBlurbIndex            = new Bm25Index({ tokenizer: tokenizeChunksAndWords })
        this.toolKeywordIndex          = new Bm25Index({ tokenizer: tokenizeChunksAndSpecialSplits })
        this.toolDescriptionIndex      = new Bm25Index({ tokenizer: tokenizeWords })
        this.path = path
        if (path) {
            // FIXME: add loading from file
        }
    }

    updateIdf() {
        this.directToolIndex.updateIdf()
        this.toolKeywordIndex.updateIdf()
        this.toolBlurbIndex.updateIdf()
        this.toolDescriptionIndex.updateIdf()
    }

    async query(string, numberOfResults) {
        const wordsAndChunks = tokenizeChunksAndWords(string)
        const directToolIndexResults      = this.directToolIndex.search(string, numberOfResults).map(       each=>({...each,  toolNameScore:        each.score}))
        const toolKeywordIndexResults     = this.toolKeywordIndex.search(string, numberOfResults).map(      each=>({...each,  toolKeywordScore:     each.score}))
        const toolBlurbIndexResults       = this.toolBlurbIndex.search(string, numberOfResults).map(        each=>({...each,  toolBlurbScore:       each.score}))
        const toolDescriptionIndexResults = this.toolDescriptionIndex.search(string, numberOfResults).map(  each=>({...each,  toolDescriptionScore: each.score}))
        
        const allResults = directToolIndexResults.concat(toolKeywordIndexResults, toolBlurbIndexResults, toolDescriptionIndexResults)

        const resultsById = {}
        for (let each of allResults) {
            resultsById[each.id] = {...resultsById[each.id], ...each}
        }
        
        const unsortedCombinedResults = Object.values(resultsById)
        unsortedCombinedResults.sort(maxVersionSorter(each=>[ each.toolNameScore, each.toolKeywordScore, each.toolBlurbScore, each.toolDescriptionScore ]))
        
        const outputList = []
        for (let each of unsortedCombinedResults) {
            outputList.push({
                package: this.tools.get(each.id), // TODO: consider making this read from disk so that not all packages remain in memory)
                score: [
                    each.toolNameScore || 0,
                    each.toolKeywordScore || 0,
                    each.toolBlurbScore || 0,
                    each.toolDescriptionScore || 0,
                ],
            })
        }
        return outputList
    }
    
    async addEntriesToIndex(entries) {
        for (const each of entries) {
            // {
            //     toolName: 
            //     entityUuid: 
            //     blurb:
            //     keywords:
            //     description:
            // }
            if (
                typeof each.toolName == 'string' && each.toolName &&
                typeof each.entityUuid == 'string' && each.entityUuid
            ) {
                const key = JSON.stringify({name: each.toolName, entityUuid: each.entityUuid})
                const id = await sha256(key)
                // figure out if its part of an existing name+entityUuid
                // if yes, then dont give any pre-existing words any weight
                if (this.tools.has(id)) {
                    // only add new words
                    // TODO: lowish priority
                } else {
                    this.tools.set(id, each)
                    // 
                    // update indicies
                    // 
                    this.directToolIndex.addDocument({
                        id,
                        body: each.toolName,
                        shouldUpdateIdf: false,
                    })

                    if (each.keywords instanceof Array) {
                        const keywordsString = each.keywords.filter(each=>typeof each == 'string').join(specialChar)
                        this.toolKeywordIndex.addDocument({
                            id,
                            body: keywordsString,
                            shouldUpdateIdf: false,
                        })
                    }

                    this.toolBlurbIndex.addDocument({
                        id,
                        body: each.blurb,
                        shouldUpdateIdf: false,
                    })

                    
                    if (each.description) {
                        this.toolDescriptionIndex.addDocument({
                            id,
                            body: each.description,
                            shouldUpdateIdf: false,
                        })
                    }
                }
            } else {
                console.warn(`${each} didn't have a string for toolName and/or entityUuid`)
            }
        }
        this.updateIdf()
    }

    async removeEntriesFromIndex(entries) {
        // FIXME
    }

    async save(path) {
        // FIXME: add saving to file (will not work this way)
        // probably need to save to and load from mutliple files to be practical
        return FileSystem.write({
            path: this.path,
            data: JSON.stringify(this),
        })
    }
}

async function smokeTest() {
    const index = new Index("smoke_test.ignore.json")
    await index.addEntriesToIndex([
        {
            toolName: "howdy",
            entityUuid: "rlkjalskjf049935",
            blurb: "a demo package used for smoke testing the bm25 based index",
        },
        {
            toolName: "python3",
            entityUuid: "rlkjalskjf049935",
            keywords: ["python", "python3", "pip"],
            blurb: "a demo package used for smoke testing the bm25 based index",
        },
    ])
    const results = await index.query("python", 10)
    console.debug(`index is:`,index)
    console.debug(`results is:`,results)
}
smokeTest()