#!/usr/bin/env -S deno run --allow-all

import { FileSystem } from "https://deno.land/x/quickr@0.3.34/main/file_system.js"
import { run, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo, zipInto, mergeInto, returnAsString, } from "https://deno.land/x/quickr@0.3.34/main/run.js"
import { Console, yellow } from "https://deno.land/x/quickr@0.3.34/main/console.js"
const { recursivelyAllKeysOf, get, set, remove, merge, compare } = await import(`https://deno.land/x/good@0.5.8/object.js`)
const { tempFolder, jsonRead } = await import(`../support/utils.js`)

const realHome = Console.env.HOME
const fakeHome = await FileSystem.ensureIsFolder(`${tempFolder}/fake_home`) 
const cacheFolder = await FileSystem.ensureIsFolder(`${tempFolder}/nixpkgs/jsons`) 
const nixpkgsFolder = `${tempFolder}/nixpkgs/repo`
const allCommitsPath = `${tempFolder}/nixpkgs/all_commits.txt`

// Setup env for nix
Console.env.NIXPKGS_ALLOW_BROKEN = "1"
Console.env.NIXPKGS_ALLOW_UNFREE = "1"
Console.env.NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM = "1"
Console.env.NIX_PATH = ""
Console.env.HOME = fakeHome
Console.env.TEMPDIR = await FileSystem.ensureIsFolder(`${tempFolder}/temp`)
// TODO: nix path to cert files

// 
// create config to broaden search results (especially on really old commits)
// 
await FileSystem.ensureIsFile(`${realHome}/.gitconfig`)
await FileSystem.copy({from: `${realHome}/.gitconfig`, to: `${fakeHome}/.gitconfig`})
await FileSystem.absoluteLink({
    existingItem: `${realHome}/Library/`,
    newItem: `${fakeHome}/Library/`,
})
await FileSystem.write({
    path: `${fakeHome}/config.nix`,
    data: `
        let 
            permittedInsecurePackages = [
                "linux-4.13.16"
                "openssl-1.0.2u"
            ];
        in
            {
                allowUnfree = true;
                nixpkgs.config.permittedInsecurePackages = permittedInsecurePackages;
                permittedInsecurePackages = permittedInsecurePackages;
            }
    `
})

// 
// clone nixpkgs to the correct place
// 
const folderInfo = await FileSystem.info(`${nixpkgsFolder}/.git`)
if (!folderInfo.isFolder) {
    await run`git clone https://github.com/NixOS/nixpkgs.git ${nixpkgsFolder}`
}
const latestCommitHash = await run`git rev-parse HEAD ${Stdout(returnAsString)} ${Cwd(nixpkgsFolder)}`


// 
// 
// API
// 
// 

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
    if (paths.length == 0) {
        return {}
    }
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
    for (const [key, each] of Object.entries(packages)) {
        if (each.meta instanceof Object && typeof each.meta.path == 'string') {
            relativePaths.add(each.meta.path)
        }
    }

    // 
    // get commits
    // 
    return await allCommitsFor({paths:[...relativePaths]})
}

export async function getPackageInfo({hash, packageName}) {
    hash = hash || latestCommitHash
    const path = `${cacheFolder}/${hash}.json`
    let output = await jsonRead(path)
    if (output == null) {
        await run`nix-env -qa --json --file ${`https://github.com/NixOS/nixpkgs/archive/${hash.trim()}.tar.gz`} ${Stdout(Overwrite(path))}`
        // await run`nix-env -qa --json --arg system \"x86_64-linux\" --file ${`https://github.com/NixOS/nixpkgs/archive/${hash.trim()}.tar.gz`} ${Stdout(Overwrite(path))}`
        output = await jsonRead(path)
    }
    // if still null
    if (output == null) {
        throw Error(`failed to run nix-env -qa for hash:${hash}`)
    }
    
    
    let packages = output
    // filter for package name (sadly this is basically as fast as querying directly for the name)
    let pnames = []
    if (packageName) {
        output = {}
        for (const [key, value] of Object.entries(packages)) {
            if (typeof value.pname != 'string') {
                throw Error(`${value}`)
            }
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

export async function manuallyGetMeta({packageAttrPath, commitHash}) {
    const parseTwiceJson = await run`nix eval ${`(
            let 
                pkgs = (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/${commitHash}.tar.gz";}) ) ({}));
            in
                (builtins.toJSON
                    pkgs.${packageAttrPath}.meta
                )
        )`} ${Stdout(returnAsString)}
    `
    return JSON.parse(JSON.parse(parseTwiceJson))
}