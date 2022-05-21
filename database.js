#!/usr/bin/env -S deno run --allow-all

import { run, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo, zipInto, mergeInto, returnAsString, } from' https://deno.land/x/quickr@0.3.24/main/run.js'
import { FileSystem } from' https://deno.land/x/quickr@0.3.24/main/file_system.js'
import { Console, yellow } from' https://deno.land/x/quickr@0.3.24/main/console.js'
// import { MeiliSearch } from "./node_modules/meilisearch/dist/bundles/meilisearch.esm.min.js"
import { MeiliSearch } from "./meilisearch.js"
import { hashJsonPrimitive, scanFolder } from "./tools.js"

const client = new MeiliSearch({ host: 'http://127.0.0.1:7700' })


function sendBatch(batch) {
    return client.index('packages').updateDocuments(batch)
}

const batchSize = 5000

const allPackageJsonPaths = await FileSystem.recursivelyListPathsIn(`${scanFolder}/packages`)
console.debug(`allPackageJsonPaths.length is:`,allPackageJsonPaths.length)
let batch = []
let loopNumber = 0
for (const eachPath of allPackageJsonPaths) {
    loopNumber += 1
    if (eachPath.slice(-5) !== '.json') {
        continue
    }
    const jsonString = await FileSystem.read(eachPath)
    if (jsonString) {
        const packageObject = JSON.parse(jsonString)
        if (packageObject && packageObject.frozen instanceof Object) {
            const id = hashJsonPrimitive(packageObject.frozen)
            batch.push({
                ...packageObject,
                id,
            })
        }
        if (batch.length > batchSize) {
            const result = await sendBatch(batch)
            console.log(`    ${loopNumber}/${allPackageJsonPaths.length}: `, result)
            batch = []
        }
    }
}
// send whatever is left
await sendBatch(batch)