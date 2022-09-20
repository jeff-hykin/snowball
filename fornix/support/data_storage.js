import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { debounceFinish } from "../support/utils.js"

const defaultSaveRate = 10000 

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
        makeNameStorage(folder),
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