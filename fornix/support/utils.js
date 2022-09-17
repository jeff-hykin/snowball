import { FileSystem } from "https://deno.land/x/quickr@0.3.34/main/file_system.js"
import { DOMParser, Element, } from "https://deno.land/x/deno_dom/deno-dom-wasm.ts"
import { createHash } from "https://deno.land/std@0.139.0/hash/mod.ts"

export const tempFolder = `${FileSystem.thisFolder}/../cache.ignore/`
await FileSystem.ensureIsFolder(tempFolder)

export async function sha256(message) {
    const msgBuffer = new TextEncoder().encode(message)
    const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
    return hashHex
}

export async function hash(string) {
    return parseInt(sha256(string, 'utf-8', 'hex'), 16) 
}

export const deepSortObject = (obj, seen=new Map()) => {
    if (!(obj instanceof Object)) {
        return obj
    } else if (seen.has(obj)) {
        // return the being-sorted object
        return seen.get(obj)
    } else {
        if (obj instanceof Array) {
            const sortedChildren = []
            seen.set(obj, sorted)
            for (const each of obj) {
                sortedChildren.push(deepSortObject(each, seen))
            }
            return sortedChildren
        } else {
            const sorted = {}
            seen.set(obj, sorted)
            for (const eachKey of Object.keys(obj).sort()) {
                sorted[eachKey] = deepSortObject(obj[eachKey], seen)
            }
            return sorted
        }
    }
}

export const stableStringify = (value, ...args) => {
    return JSON.stringify(deepSortObject(value), ...args)
}

export const hashJsonPrimitive = (value) => createHash("md5").update(stableStringify(value)).toString()

export function getInnerTextOfHtml(htmlText) {
    const doc = new DOMParser().parseFromString(htmlText,
        "text/html",
    )
    return doc.body.innerText
}

export const curl = async url=> new Promise(resolve => { 
    fetch(url).then(res=>res.text()).then(body=>resolve(body))
})

export async function jsonRead(path) {
    let jsonString = await FileSystem.read(path)
    let output
    try {
        output = JSON.parse(jsonString)
    } catch (error) {
        // if corrupt, delete it
        if (typeof jsonString == 'string') {
            await FileSystem.remove(path)
        }
    }
    return output
}

// increases resolution over time
function* binaryListOrder(aList) {
    const length = aList.length
    if (length > 0) {
        const middle = Math.floor(length/2)
        yield aList[middle]
        if (length > 1) {
            const upperItems = binaryListOrder(aList.slice(0,middle))
            const lowerItems = binaryListOrder(aList.slice(middle+1))
            // all the sub-elements (alternate between upper and lower)
            for (const eachUpper of upperItems) {
                yield eachUpper
                const eachLower = lowerItems.next()
                if (!eachLower.done) {
                    yield eachLower.value
                }
            }
        }
    }
}

export const debounceFinish = ({cooldownTime=200}, func) => {
    const previousOne = { endTime: 0, promise: null }
    let listenerForCompletion = false
    let running
    const onCall = ()=>{
        console.debug(`onCall`)
        console.debug(`    running is:`,running)
        const timeIsUp = previousOne.endTime+cooldownTime < (new Date()).getTime()
        if (!running) {
            console.debug(`    timeIsUp is:`,timeIsUp)
        }
        if (!(!running && timeIsUp)) {
            console.debug(`    listenerForCompletion is:`,listenerForCompletion)
        }
        // can it be executed right now?
        if (!running && timeIsUp) {
            running = true
            console.debug(`        func()`,)
            previousOne.promise = func().then(value=>{
                previousOne.endTime = (new Date()).getTime()
                running = false
                return value
            })
            listenerForCompletion = false
        // does the next one need to be scheduled?
        } else if (!listenerForCompletion) {
            console.debug(`    scheduling`,)
            listenerForCompletion = true
            previousOne.promise.then(()=>{
                // previousOne.endTime is guareenteed to be correct because the promise has been awaited
                const targetTime = previousOne.endTime+cooldownTime
                const remainingMiliseconds = targetTime - (new Date()).getTime()
                if (remainingMiliseconds <= 0) {
                    // we are able to execute now
                    console.debug(`scheduled--onCall--instant`)
                    onCall()
                } else {
                    // try again later
                    setTimeout(()=>{
                        listenerForCompletion = false // this is the listener, and it just finished
                        console.debug(`scheduled--onCall--delayed`)
                        onCall()
                    }, remainingMiliseconds)
                }
            })
        }
        return previousOne.promise
    }
    return onCall
}

export const maxVersionSorter = (createVersionList)=> {
    const compareLists = (listsA, listsB)=> {
        // b-a => bigger goes to element 0
        const comparisonLevels = listsB.map((each, index)=>{
            let b = each || 0
            let a = listsA[index] || 0
            const aIsArray = a instanceof Array
            const bIsArray = b instanceof Array
            if (!aIsArray && !bIsArray) {
                return b - a
            }
            a = aIsArray ? a : [ a ]
            b = bIsArray ? b : [ b ]
            // recursion for nested lists
            return compareLists(a, b)
        })
        for (const eachLevel of comparisonLevels) {
            // first difference indicates a winner
            if (eachLevel !== 0) {
                return eachLevel
            }
        }
        return 0
    }
    return (a,b)=>compareLists(createVersionList(a), createVersionList(b))
}