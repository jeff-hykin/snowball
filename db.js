import { hashers } from "https://deno.land/x/good@1.4.4.3/encryption.js"
import Surreal from "https://deno.land/x/surrealdb/mod.ts"

// surreal start --user root --pass root
const db = new Surreal('http://0.0.0.0:8000/rpc')

// Signin as a namespace, database, or root user
await db.signin({
    user: 'root',
    pass: 'root',
})

// Select a specific namespace / database
var nixpkgsHash = `aa0e8072a57e879073cee969a780e586dbe57997`
await db.use("nixDb", `nixDb`)


// - [["onestepback","srcs"],2,2,{"column":3,"file":"pkgs/data/themes/onestepback/default.nix","line":7},[],null]
async function attrInfo({ path, positionInfo, childNames, nixpkgsHash, unixEpochOfCommit, os, errMessage,}) {
    const id = await hashers.sha256(JSON.stringify(path))
    Promise.all([
        await db.create("attrEntry", {
            identifier: id,
            positionInfo,
            childNames,
        }),
        await db.create("hashExistanceEntry", {
            attrEntryId: id,
            nixpkgsHash,
        })
    ])
}


// // Create a new person with a random id
// let created = await db.create("person", {
//     title: 'Founder & CEO',
//     name: {
//         first: 'Tobie',
//         last: 'Morgan Hitchcock',
//     },
//     marketing: true,
//     identifier: Math.random().toString(36).substr(2, 10),
// })

// // Update a person record with a specific id
// let updated = await db.change("person:jaime", {
//     marketing: true,
// })

// // Select all people records
// let people = await db.select("person")

// // Perform a custom advanced query
// let groups = await db.query('SELECT marketing, count() FROM type::table($tb) GROUP BY marketing', {
//     tb: 'person',
// })