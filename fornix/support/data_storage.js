import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { debounceFinish, sha256, makeSafeFileName } from "../support/utils.js"

const defaultSaveRate = 10000 
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
    setInterval(writeQueToStorage, defaultSaveRate)
    
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


// FIXME: each of these needs a contributor mapping, and can be deleted when that mapping level equals zero

const makeNameStorage = async (folder) => {
    const path = `${folder}/names.json`
    const names = new Set(JSON.parse((await FileSystem.read(path)) || '[]'))
    return {
        path,
        names,
        save: ()=>{
            await FileSystem.write({ path, data:JSON.stringify([...names])})
        }
    }
}

const makeBlurbStorage = async (folder) => {
    const path = `${folder}/blurbs.json`
    const blurbs = JSON.parse((await FileSystem.read(path)) || '{}')
    return {
        path,
        blurbs,
        save: ()=>{
            await FileSystem.write({ path, data:JSON.stringify(blurbs)})
        }
    }
}

const makeFlavorStorage = async (folder) => {
    const path = `${folder}/flavors.json`
    const flavors = JSON.parse((await FileSystem.read(path)) || '{}')
    return {
        path,
        flavors,
        save: ()=>{
            await FileSystem.write({ path, data:JSON.stringify(flavors)})
        }
    }
}

const makeSourceStorage = async (folder) => {
    const path = `${folder}/sources.json`
    const sources = JSON.parse((await FileSystem.read(path)) || '{}')
    return {
        path,
        sources,
        save: ()=>{
            await FileSystem.write({ path, data:JSON.stringify(sources)})
        }
    }
}

const makeIdStorage = async (folder) => {
    const path = `${folder}/ids.json`
    const ids = JSON.parse((await FileSystem.read(path)) || '{}')
    return {
        path,
        ids,
        save: ()=>{
            await FileSystem.write({ path, data:JSON.stringify(ids)})
        }
    }
}

export async function load({folder, saveRate=defaultSaveRate}) {
    await FileSystem.ensureIsFolder(folder)

    const [ nameStorage, blurbStorage, flavorStorage, sourceStorage, idStorage ] = await Promise.all([
        createStorageIfNeeded(folder, "names"),
        createStorageIfNeeded(folder, "names"),
        makeBlurbStorage(folder),
        makeFlavorStorage(folder),
        makeSourceStorage(folder),
        makeIdStorage(folder),
    ])
    
    // wait 1 second between each save attempt
    setInterval(
        debounceFinish({ cooldownTime: saveRate }, async ()=>{
            await nameStorage.save()
            await blurbStorage.save()
            await flavorStorage.save()
            await sourceStorage.save()
            await idStorage.save()
        }),
        saveRate,
    )

    return {
        names: nameStorage.names,
        blurbs: blurbStorage.blurbs,
        flavors: flavorStorage.flavors,
        sources: sourceStorage.sources,
        ids: idStorage.ids,
    }
}