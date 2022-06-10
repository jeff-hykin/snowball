#!/usr/bin/env -S deno run --allow-all

const { run, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo, zipInto, mergeInto, returnAsString, } = await import(`https://deno.land/x/quickr@0.3.24/main/run.js`)
const { FileSystem } = await import(`https://deno.land/x/quickr@0.3.24/main/file_system.js`)
const { Console, yellow } = await import(`https://deno.land/x/quickr@0.3.24/main/console.js`)
const { recursivelyAllKeysOf, get, set, remove, merge, compare } = await import(`https://deno.land/x/good@0.5.8/object.js`)
const { jsonRead } = await import(`../support/basics.js`)

const cacheFolder = `${FileSystem.thisFolder}/../cache.ignore/nixpkgs/jsons`; await FileSystem.ensureIsFolder(cacheFolder)
const nixpkgsFolder = `${FileSystem.thisFolder}/../cache.ignore/nixpkgs/repo`
const allCommitsPath = `${FileSystem.thisFolder}/../cache.ignore/nixpkgs/all_commits.txt`

Console.env.NIXPKGS_ALLOW_BROKEN = "1"
Console.env.NIXPKGS_ALLOW_UNFREE = "1"
Console.env.NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM = "1"
Console.env.NIX_PATH = ""
Console.env.HOME = `${cacheFolder}/nixpkgs/`

// 
// clone nixpkgs to the correct place
// 
const folderInfo = await FileSystem.info(`${nixpkgsFolder}/.git`)
if (!folderInfo.isFolder) {
    await run`git clone https://github.com/NixOS/nixpkgs.git ${nixpkgsFolder}`
}
const latestCommitHash = await run`git rev-parse HEAD ${Stdout(returnAsString)} ${Cwd(nixpkgsFolder)}`



let allCommitsCache = null
export async function allCommitsAndDates() {
    if (allCommitsCache) {
        return allCommitsCache
    }

    const fileInfo = await FileSystem.info(allCommitsPath)
    if (fileInfo.isFile) {
        return allCommitsPath
    } else {
        console.log(`writing commits to:`, allCommitsPath)
        await run`git log --first-parent --date=short --pretty=format:%H#%ad ${Cwd(nixpkgsFolder)} ${Stdout(Overwrite(allCommitsPath))}`
    }
    const allCommitsAndDatesString = (await FileSystem.read(allCommitsPath)).split("\n")
    allCommitsCache = Object.fromEntries(allCommitsAndDatesString.map(each=>each.split(/#/)))
    return allCommitsCache
}

export async function allCommitsFor({paths}) {
    const result = await run(`git`, `log`, `--first-parent`, `--date=short`, `--pretty=format:%H#%ad`, ...paths, Cwd(nixpkgsFolder), Stdout(returnAsString))
    return Object.fromEntries(result.split("\n").map(each=>each.split(/#/)))
}

export async function getReleventCommitsFor({packageName, startCommit}) {
    startCommit = startCommit || latestCommitHash
    const packages = await getPackageInfo({
        hash: startCommit,
        packageName
    })
    
    // 
    // get paths
    // 
    const relativePaths = new Set()
    for (const each of packages) {
        if (each.meta instanceof Object && typeof each.meta.path == 'string') {
            relativePaths.add(each.meta.path)
        }
    }

    // 
    // get commits
    // 
    return await allCommitsFor(relativePaths)
}


export async function getPackageInfo({hash, packageName}) {
    const path = `${cacheFolder}/${hash}.json`
    let output = await jsonRead(path)
    if (output == null) {
        // pretend to be linux since it has the most wide support
        await run`nix-env -qa --json --arg system \"x86_64-linux\" --file ${`https://github.com/NixOS/nixpkgs/archive/${hash.trim()}.tar.gz`} ${Stdout(Overwrite(path))}`
        output = await jsonRead(path)
    }
    // if still null
    if (output == null) {
        throw Error(`failed to run nix-env -qa for hash:${hash}`)
    }
    
    // filter for package name (sadly this is basically as fast as querying directly for the name)
    if (packageName) {
        output = {}
        for (const [key, value] of Object.entries(output)) {
            if (value.pname == packageName) {
                output[key] = value
            }

            // 
            // attach package info
            // 
            if (value.meta instanceof Object && typeof value.meta.position == 'string') {
                let relativePath = value.meta.position
                relativePath = relativePath.replace(/^\/nix\/store\/.+?\//, "")
                relativePath = relativePath.replace(/^nixpkgs\//, "")
                relativePath = relativePath.replace(/:\d+$/, "")
                value.meta.path = relativePath
            }
        }
    }

    return output
}