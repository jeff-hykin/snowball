// convert the scrape.js into this task
    // have it output in the correct publish format

import {getReleventCommitsFor, manuallyGetMeta} from "../support/nixpkgs.js"
import {binaryListOrder} from "../support/utils.js"
import { toCamelCase } from "https://deno.land/x/good@0.5.14/string.js"

async function convertPackageInfo({attrName, packageInfo, commitHash, commitDate}) {
    // 
    // extract name
    // 
        let name
        if (packageInfo.pname) {
            name = packageInfo.pname
        } else if (packageInfo.name && packageInfo.version) {
            name = packageInfo.name.slice(0,packageInfo.version.length+1)
        } else if (packageInfo.name) {
            name = packageInfo.name.replace(/-.*/, "")
        } else {
            return null
        }
    
    // 
    // extract version as string
    // 
        let versionAsString
        if (packageInfo.version) {
            versionAsString = packageInfo.version
        } else if (packageInfo.name && packageInfo.pname) {
            versionAsString = packageInfo.name.slice(packageInfo.pname+1)
        } else if (packageInfo.name) {
            versionAsString = packageInfo.name.replace(/.+?-/, "")
        } else {
            return null
        }

    // 
    // extract version as list
    // 
        let versionAsList
        const versionAsListMatch = output.frozen.versionString.match(/((?:\d+)(?:\.(?:\d+))*)(.+)?/)
        if (versionAsListMatch) {
            versionAsList = versionAsListMatch[1].split(".").map(each=>each-0)
            const tagIfAny = versionAsListMatch[2]
            if (tagIfAny) {
                versionAsList.push(tagIfAny)
            }
        }
    
    // for some reason, some packages just don't include meta in their query
    // make no mistake: they still have a meta, its just nix-env -qa doesn't return it for whatever reason
    if (!(packageInfo.meta instanceof Object)) {
        packageInfo.meta = await manuallyGetMeta({packageAttrPath: attrName, commitHash})
    }
    
    // 
    // extract blurb
    // 
        const blurb = packageInfo.meta.description

    // 
    // extract license
    // 
        let licenses = []
        if (packageInfo.meta.license != null) {
            if (packageInfo.meta.license instanceof Array) {
                licenses = packageInfo.meta.license
            } else {
                licenses.push(packageInfo.meta.license)
            }
        }

    // 
    // skip authentication (unable to extract)
    // 


    // 
    // flavor
    // 
        const flavor = {
            versionAsString,
            versionAsList,
            inputs: null, // unable to automate this value
            outputs: null, // unable to automate this value
        }

    // 
    // links
    // 
        const links = {
            homepage: packageInfo.meta.homepage,
            icon: null,
            iframeSrc: null,
        }
    
    // 
    // description
    // 
        const description = packageInfo.meta.longDescription
    
    // 
    // maintainers
    // 
        const maintainers = packageInfo.meta.maintainers

    // 
    // adjectives
    // 
        const adjectives = {
            ...generateSupportInfo(packageInfo.meta.platforms),
            nixpkgs: {
                automatedCreation: true,
                unfree: packageInfo.meta.unfree,
                insecure: packageInfo.meta.insecure,
                broken: packageInfo.meta.broken,
            },
            custom: {},
        }
    // 
    // sources
    // 
        let position
        if (typeof packageInfo.meta.position == 'string') {
            position = packageInfo.meta.position.replace(/\/nix\/store\/.+?\//, "")
        }
        let positionLink
        if (position) {
            const endingDigitMatch = position.match(/(.+):(\d+)$/)
            if (endingDigitMatch) {
                const path = endingDigitMatch[1]
                const digit = endingDigitMatch[2]
                positionLink = `https://github.com/NixOS/nixpkgs/blob/${commitHash}/${path}#L${digit}`
            }
        }
        const sources = [
            {
                "format": "git",
                "url": "https://github.com/NixOS/nixpkgs.git",
                "commit": commitHash,
                "attributePath": attrName.split("."),
                position,
                positionLink,
                availableSince: commitDate,
            },
        ]
    
    
    let output = {
        name,
        blurb,
        identifiers: {
            licenses,
            authentication: {
                sourceHashSha256: "",
                sourceHashSha256Signatures: {},  // key=public key, value=signature given the hash as a base64 string
            },
        },
        flavor,
        additionalInfo: {
            links,
            description,
            maintainers,
            adjectives,
        },
        sources,
    }

    // 
    // publicationSignatures
    // 
        // FIXME: sign this with many keys
        // output.publicationSignatures = sign(JSON.stringify(output))

    return output
    // "nixpkgs.python310": {
    //     "name": "python3-3.10.2",
    //     "pname": "python3",
    //     "version": "3.10.2",
    //     "system": "x86-darwin",
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
        //         "x86-linux",
        //         "x86-darwin",
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


function generateSupportInfo(supportList) {
    const generallySupports = {}
    const flattened = supportList.map(each=>each.split(/-|_/)).flat(Infinity).join("\n")
    const has = (substringOrRegex)=>{
        return !!flattened.match(substringOrRegex)
    }
    
    // 32Bit check
    if (has("i686") || has(/(?<=\D|^)32(?=\D|$)/)) {
        generallySupports["32Bit"] = true
    }
    
    // 64Bit check
    if (has(/x86/i) || has(/(?<=\D|^)64(?=\D|$)/)) {
        generallySupports["64Bit"] = true
    }

    // MacOS
    if (has(/darwin/i)) {
        generallySupports["MacOS"] = true
    }
    // Linux
    if (has(/linux/i)) {
        generallySupports["Linux"] = true
    }
    // Windows
    if (has(/windows/i)) {
        generallySupports["Windows"] = true
    }
    
    // x86
    if (has(/x86/i)) {
        generallySupports["x86"] = true
    }
    // arm
    if (has(/\barm|\baarch\b/i)) {
        generallySupports["arm"] = true
    }
    // riscv
    if (has(/riscv/i)) {
        generallySupports["riscv"] = true
    }
    // Wasi
    if (has(/wasi/i)) {
        generallySupports["wasi"] = true
    }

    const exactlySupports = {}
    for (const eachName of supportList) {
        let newValue = toCamelCase(
            eachName.replace(
                    "x86_64",
                    "64bit_x86"
                ).replace(
                    /i686/i,
                    "32bit_x86",
                ).replace(
                    /aarch64/i,
                    "arm64",
                ).replace(
                    /darwin/i,
                    "mac",
                ).replace(
                    /\bnone\b/i,
                    ""
                ).replace(
                    "-",
                    "_",
                )
        )
        exactlySupports[eachName] = true
    }

    return {
        generallySupports,
        exactlySupports,
    }
}