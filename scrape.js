#!/usr/bin/env -S deno run --allow-all

const { run, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo, zipInto, mergeInto, returnAsString, } = await import(`https://deno.land/x/quickr@0.3.24/main/run.js`)
const { FileSystem } = await import(`https://deno.land/x/quickr@0.3.24/main/file_system.js`)
const { Console, yellow } = await import(`https://deno.land/x/quickr@0.3.24/main/console.js`)
const { scanFolder, hashJsonPrimitive } = await import(`./tools.js`)

const scanExists = (await FileSystem.info(scanFolder)).isFolder
if (!scanExists) {
    await FileSystem.remove(scanFolder)
    await run`git clone https://github.com/jeff-hykin/nix-version.git ./${scanFolder}/..`
}

Console.env.NIXPKGS_ALLOW_BROKEN = "1"
Console.env.NIXPKGS_ALLOW_UNFREE = "1"
Console.env.NIX_PATH = ""
Console.env.HOME = FileSystem.thisFolder

async function jsonRead(path) {
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

// TODO: prioritize searching tagged commits first
    // list all tags with hashes and dates
    // split by the tags, creating buckets
    // then do binary list order in the buckets inbetween the tags

// increases resolution over time
function* binaryListOrder(aList, ) {
    const length = aList.length
    const middle = Math.floor(length/2)
    yield aList[middle]
    if (length > 1) {
        const upperItems = binaryListOrder(aList.slice(0,middle))
        const lowerItems = binaryListOrder(aList.slice(middle+1))
        // all the sub-elements
        for (const eachUpper of upperItems) {
            yield eachUpper
            const eachLower = lowerItems.next()
            if (!eachLower.done) {
                yield eachLower.value
            }
        }
    }
}

const allPackgeInfoPath = `${scanFolder}/allPackageInfo/`
async function getAllPackageInfo(hash) {
    const path = `${allPackgeInfoPath}/${hash}.json`
    let output = await jsonRead(path)
    if (output == null) {
        // pretend to be linux since it has the most wide support
        await run`nix-env -qa --json --arg system \"x86_64-linux\" --file ${`https://github.com/NixOS/nixpkgs/archive/${hash}.tar.gz`} ${Stdout(Overwrite(path))}`
        output = await jsonRead(path)
    }
    // if still null
    if (output == null) {
        console.log(`path is:`,path)
        throw Error(error)
    }

    return output
}

// for single package
async function getPackageJsonFor(packageAttrPath, hash) {
    // nix-env -qaA nixpkgs.python --json --file https://github.com/NixOS/nixpkgs/archive/6c36c4ca061f0c85eed3c96c0b3ecc7901f57bb3.tar.gz
    const jsonString = await run`nix-env -qaA ${packageAttrPath} --json --file ${`https://github.com/NixOS/nixpkgs/archive/${hash}.tar.gz`} ${Stdout(returnAsString)}`
    return JSON.parse(jsonString)[packageAttrPath]
}

async function convertPackageInfo(attrName, packageInfo, commitHash) {
    const output = {
        frozen: {
            name: "",
            shortDescription: "",
            longDescription: "",
            versionString: "",
            homepage: "",
            license: "",
            versionNumberList: [],
            // would like:
            //     available inputs
            //     executable outputs
            //     file outputs
            //     dependencies
        },
        flexible: {
            unfree: false,
            insecure: false,
            broken: false,
            sources: [],
            platforms: [],
        }
    }
    
    if (packageInfo.pname) {
        output.frozen.name = packageInfo.pname
    } else if (packageInfo.name && packageInfo.version) {
        output.frozen.name = packageInfo.name.slice(0,packageInfo.version.length+1)
    } else if (packageInfo.name) {
        output.frozen.name = packageInfo.name.replace(/-.*/, "")
    } else {
        return null
    }
    
    if (packageInfo.version) {
        output.frozen.versionString = packageInfo.version
    } else if (packageInfo.name && packageInfo.pname) {
        output.frozen.versionString = packageInfo.name.slice(packageInfo.pname+1)
    } else if (packageInfo.name) {
        output.frozen.versionString = packageInfo.name.replace(/.+?-/, "")
    } else {
        return null
    }

    const versionNumberListMatch = output.frozen.versionString.match(/((?:\d+)\.(?:\d+)(?:\.(?:\d+))*)(.+)?/)
    if (versionNumberListMatch) {
        output.frozen.versionNumberList = versionNumberListMatch[1].split(".").map(each=>each-0)
        const tagIfAny = versionNumberListMatch[2]
        if (tagIfAny) {
            output.frozen.versionNumberList.push(tagIfAny)
        }
    }
    
    // for some reason, some packages just don't include meta in their query
    // make no mistake: they still have a meta, its just nix-env -qa doesn't return it for whatever reason
    if (packageInfo.meta == null) {
        packageInfo.meta = await manuallyGetMeta(attrName, commitHash)
    }

    output.frozen.license          = packageInfo.meta.license
    output.frozen.shortDescription = packageInfo.meta.description
    output.frozen.longDescription  = packageInfo.meta.longDescription
    output.frozen.homepage         = packageInfo.meta.homepage
    output.flexible.unfree           = packageInfo.meta.unfree
    output.flexible.insecure         = packageInfo.meta.insecure
    output.flexible.broken           = packageInfo.meta.broken
    output.flexible.platforms        = packageInfo.meta.platforms
    
    return output
    // "nixpkgs.python310": {
    //     "name": "python3-3.10.2",
    //     "pname": "python3",
    //     "version": "3.10.2",
    //     "system": "x86_64-darwin",
    //     "meta": {
        //     "available": true,
        //     "broken": false,
        //     "description": "A high-level dynamically-typed programming language",
        //     "homepage": "http://python.org",
        //     "insecure": false,
        //     "license": {
        //         "deprecated": false,
        //         "free": true,
        //         "fullName": "Python Software Foundation License version 2",
        //         "redistributable": true,
        //         "shortName": "psfl",
        //         "spdxId": "Python-2.0",
        //         "url": "https://spdx.org/licenses/Python-2.0.html"
        //     },
        //     "longDescription": "Python is a remarkably powerful dynamic programming language that\nis used in a wide variety of application domains. Some of its key\ndistinguishing features include: clear, readable syntax; strong\nintrospection capabilities; intuitive object orientation; natural\nexpression of procedural code; full modularity, supporting\nhierarchical packages; exception-based error handling; and very\nhigh level dynamic data types.\n",
        //     "maintainers": [
        //         {
        //         "email": "fridh@fridh.nl",
        //         "github": "fridh",
        //         "githubId": 2129135,
        //         "name": "Frederik Rietdijk"
        //         }
        //     ],
        //     "name": "python3-3.10.2",
        //     "outputsToInstall": [
        //         "out"
        //     ],
        //     "platforms": [
        //         "aarch64-linux",
        //         "armv5tel-linux",
        //         "armv6l-linux",
        //         "armv7a-linux",
        //         "armv7l-linux",
        //         "i686-linux",
        //         "m68k-linux",
        //         "mipsel-linux",
        //         "powerpc64-linux",
        //         "powerpc64le-linux",
        //         "riscv32-linux",
        //         "riscv64-linux",
        //         "s390-linux",
        //         "s390x-linux",
        //         "x86_64-linux",
        //         "x86_64-darwin",
        //         "i686-darwin",
        //         "aarch64-darwin",
        //         "armv7a-darwin"
        //     ],
        //     "position": "/nix/store/wkbdshg9bqx62x1pjpmhk6kb9pfrymcw-nixpkgs-22.05pre360843.3eb07eeafb5/nixpkgs/pkgs/development/interpreters/python/cpython/default.nix:494",
        //     "unfree": false,
        //     "unsupported": false
    //     }
    // }
}

const allPackages = {}
async function asyncAddPackageInfo(newPackageInfo, source) {
    const packageName = newPackageInfo.frozen.name
    const hashValue = hashJsonPrimitive(newPackageInfo.frozen)
    const filePath = `${scanFolder}/packages/${packageName}/${hashValue}.json`
    let stringOutput = await FileSystem.read(filePath)
    
    // create package if doesn't exist
    if (allPackages[packageName] == null) {
        allPackages[packageName] = {}
    }

    // if it doesnt exist, try to get it from a file
    if (allPackages[packageName][hashValue] == null) {
        if (stringOutput) {
            try {
                allPackages[packageName][hashValue] = JSON.parse(stringOutput)
            } catch (error) {
                console.debug(`    problem with ${filePath}`,)
                console.debug(`    stringOutput is:`,stringOutput)
                console.warn(error)
            }
        }
        if (allPackages[packageName][hashValue] == null) {
            allPackages[packageName][hashValue] = {...newPackageInfo}
        }
    }
    
    // add source
    const sources = allPackages[packageName][hashValue].flexible.sources
    const sourceHashes = new Set(sources.map(each=>hashJsonPrimitive(each)))
    const thisHash = hashJsonPrimitive(source)
    if (!sourceHashes.has(thisHash)) {
        allPackages[packageName][hashValue].flexible.sources.push(source)
    }

    await FileSystem.write({
        path: filePath,
        data: JSON.stringify(allPackages[packageName][hashValue]),
    })
}

const pathToAllCommits = `${scanFolder}/allCommits.txt`
async function getPathToAllCommitHashes() {
    const fileInfo = await FileSystem.info(pathToAllCommits)
    if (fileInfo.isFile) {
        return pathToAllCommits
    } else {
        console.log(`writing commits to:`, pathToAllCommits)
        const path = Deno.makeTempDir()
        await run`git clone https://github.com/NixOS/nixpkgs.git ./nixpkgs ${Cwd(path)}`
        await run`git log --first-parent --date=short --pretty=format:%H#%ad ${Cwd(`${path}/nixpkgs`)} ${Stdout(Overwrite(pathToAllCommits))}`
        // clean up
        await FileSystem.remove(path)
    }
    return pathToAllCommits
}

const progressFile = `${scanFolder}/progress.json`
const commitsFile = `${scanFolder}/allCommits.json`
let progress
let commitToDate = {}
async function* iterateAllCommitHashes() {
    console.log(`reading in progress file`)
    progress = await jsonRead(progressFile)
    if (progress == null) {
        progress = {
            completedHashes: [],
        }
    }
    let allCommitsAndDates = (await FileSystem.read(await getPathToAllCommitHashes())).split("\n")
    commitToDate = Object.fromEntries(allCommitsAndDates.map(each=>each.split(/#/)))
    

    for (const each of binaryListOrder(Object.keys(commitToDate))) {
        // Skip! (to resume progress)
        if (progress.completedHashes.includes(each)) {
            console.log(`    skipping ${each}`)
            continue
        }
        // otherwise do it
        yield each
        // save that it was done
        await FileSystem.write({ path: progressFile, data: JSON.stringify(progress,0,4), })
    }
}

async function manuallyGetMeta(packageAttrPath, commitHash) {
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


// 
// main algo
// 
const concurrentSize = 30
for await (const commitHash of iterateAllCommitHashes()) {
    console.log(`commitHash is: ${commitHash}, created on: ${commitToDate[commitHash]}`,)
    try {
        console.log(`    getting all package info`)
        const allPackages = await getAllPackageInfo(commitHash)
        console.log(`    package info retrieved`)
        const waitingGroup = []
        const entries = Object.entries(allPackages)
        const numberOfAttributes = entries.length
        const attributesNumberLength = `${numberOfAttributes}`.length
        let loopNumber = 0
        for (const [attrName, packageInfo] of entries) {
            loopNumber += 1
            try {
                if (loopNumber % 500 == 0) {
                    console.log(`    ${`${loopNumber}`.padStart(attributesNumberLength)}/${entries.length}: ${  `${ Math.round((loopNumber/entries.length)*100)}`  }%`)
                }
                const packageFixedInfo = await convertPackageInfo(attrName, packageInfo, commitHash)

                waitingGroup.push(
                    asyncAddPackageInfo(
                        packageFixedInfo,
                        {
                            git: `https://github.com/NixOS/nixpkgs.git`,
                            commit: commitHash,
                            attributePath: attrName.split("."),
                            position: typeof packageInfo.meta.position == 'string' ? packageInfo.meta.position.replace(/\/nix\/store.+\/nixpkgs\//,"") : null,
                            date: commitToDate[commitHash],
                            // path: packageInfo.meta.position.replace(/\/nix\/store.+\/nixpkgs\/(.+)(:\d+)?$/,"$1"),
                        }
                    )
                )
                if (waitingGroup.length > concurrentSize) {
                    await Promise.all(waitingGroup)
                    waitingGroup.splice(0,Infinity)
                }
            } catch (error) {
                console.warn(`    error with package: ${attrName}`, error)
            }
        }
        progress.completedHashes.push(commitHash)
    } catch (error) {
        console.warn(`issue on commit: ${commitHash}, `, error)
    }
}
