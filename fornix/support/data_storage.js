import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { debounceFinish, sha256, makeSafeFileName } from "../support/utils.js"

const defaultSaveRate = 10000 // miliseconds
const saveOperations = []
setInterval(
    debounceFinish({ cooldownTime: saveRate }, async ()=>Promise.all(saveOperations.map(each=>each()))),
    saveRate,
)

export const createStorageObject = async (path, name)=> {
    const self = {
        dataPath: `${path}/${name}`,
        keyPath: `${path}/${name}@keys.json`,
        keys: [],
        cacheSizeLimit: 2000,
        cache: {},
        onQue: {},
        pathForKey: (key)=>`${self.dataPath}/${makeSafeFileName(key)}.json`,
    }
    
    // 
    // ensure data folder
    // 
    await FileSystem.ensureIsFolder(self.dataPath)
    // 
    // ensure keys
    // 
    try {
        self.keys = JSON.stringify(await FileSystem.read(self.keyPath))
        if (!(self.keys instanceof Array)) {
            self.keys = []
            throw Error(``)
        }
    } catch (error) {
        await FileSystem.write({
            path: self.keyPath,
            data: "[]",
        })
    }
    self.keys = new Set(self.keys)

    // 
    // helpers
    // 
    const checkCacheSize = async ()=>{
        const cacheKeys = Object.keys(self.cache)
        // delete keys to prevent this being a memory leak
        while (cacheKeys.length > self.cacheSizeLimit) {
            const firstKey = cacheKeys.splice(0,1)
            delete cache[firstKey]
        }
    }
    const writeQueToStorage = async ()=>{
        FileSystem.write({
            data:
        })
        Object.assign(self.cache, self.onQue)
        checkCacheSize() // dont await, just let it run when it can
        const entries = Object.entries(self.onQue)
        self.onQue = {} // reset the onQue data
        return Promise.all(entries.map(([key, value])=>{
            try {
                await FileSystem.write({
                    data: JSON.stringify(value),
                    path: self.pathForKey(key),
                })
            } catch (error) {
                console.warn(`Couldn't JSON.stringify ${name}, ${key}: ${error}`)
            }
        }))
    }
    saveOperations.push(writeQueToStorage)
    
    // 
    // proxy
    // 
    const originalThing = ()=>{}
    const proxySymbol = Symbol.for('Proxy')
    const thisProxySymbol = Symbol('thisProxy')
    // originalThing[Symbol.iterator]      // used by for..of loops and spread syntax.
    // originalThing[Symbol.toPrimitive]
    self.data = new Proxy(originalThing, {
        // Object.keys
        ownKeys(target, ...args) { 
            return self.keys
        },
        get(original, key, ...args) {
            if (self.onQue[key] != undefined) {
                return self.onQue[key]
            } else if (self.cache[key] != undefined) {
                const value = self.cache[key]
                // delete it so that it will behave like an LRU cache
                delete self.cache[key]
                return self.cache[key] = value
            } else {
                self.cache[key] = FileSystem.sync.read(self.pathForKey(key))
                checkCacheSize() // dont await, just check asyncly
                return self.cache[key]
            }
        },
        set(original, key, value) {
            self.onQue[key] = value
            self.keys.add(key)
        },
        has(original, key) {
            return self.keys.has(key)
        },
    })
    return self
}