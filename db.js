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
await db.use(nixpkgsHash, `macOS_m1`)


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