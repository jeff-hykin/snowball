#!/usr/bin/env -S deno run --allow-all

import { run, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo, zipInto, mergeInto, returnAsString, } from' https://deno.land/x/quickr@0.3.24/main/run.js'
import { FileSystem } from' https://deno.land/x/quickr@0.3.24/main/file_system.js'
import { Console, yellow } from' https://deno.land/x/quickr@0.3.24/main/console.js'
// import { MeiliSearch } from "./node_modules/meilisearch/dist/bundles/meilisearch.esm.min.js"
import { MeiliSearch } from "./meilisearch.js"
import { hashJsonPrimitive, scanFolder } from "./tools.js"

const client = new MeiliSearch({ host: 'http://127.0.0.1:7700' })


function addToDatabase(packageObject) {
    const id = hashJsonPrimitive(packageObject.frozen)
    // dont need to wait on this
    return client.index('packages').updateDocuments([
        {
            ...packageObject,
            id,
        }
    ])
}

const allPackageJsonPaths = await FileSystem.recursivelyListPathsIn(`${scanFolder}/packages`)
console.debug(`allPackageJsonPaths.length is:`,allPackageJsonPaths.length)
for (const eachPath of allPackageJsonPaths) {
    if (eachPath.slice(-5) !== '.json') {
        continue
    }
    const jsonString = await FileSystem.read(eachPath)
    if (jsonString) {
        const value = JSON.parse(jsonString)
        if (value && value.frozen instanceof Object) {
            console.debug(`adding:`,value.frozen.name)
            let result = await addToDatabase(value)
            console.debug(`result is:`,result)
        }
    }
}