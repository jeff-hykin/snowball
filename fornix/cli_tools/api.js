import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { run, throwIfFails, zipInto, mergeInto, returnAsString, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo } from "https://deno.land/x/quickr@0.5.0/main/run.js"
import { Console, clearStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, hidden, strikethrough, visible, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.3.44/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.8/string.js"
import * as Encryption from "https://deno.land/x/good@0.7.8/encryption.js"
import { deepCopy, allKeyDescriptions, deepSortObject, shallowSortObject } from "https://deno.land/x/good@0.7.8/value.js"
import { IdentityManager } from "../support/identity_manager.js"
import { parse } from "https://deno.land/std@0.173.0/flags/mod.ts"

const serverTarget = "localhost:3000" // TODO
const contactSever = ({route, data})=>{
    return fetch(`${serverTarget}/${route}`, 
        {
            method: 'POST',
            headers: {
                'Accept': 'application/json, text/plain, */*',
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        }
    ).then(res => res.json())
}

class UserPickedExit extends Error {}

// overview
    // every publication needs a package name and an identity
    // the publisher

// 
// parse args
// 
const [ action, ...args ] = Deno.args
const namedArgs = {
    advancedIdentitiesFilepath: IdentityManager.defaultPath,
    identity: null,
    ...Object.fromEntries(Object.entries(parse(args)).map(
        // change kebab-case to camel case
        ([key, value])=>[toCamelCase(key), value],
    )),
}

// 
// pick operation
// 
try {
    if (action == "create-identity") {
        await IdentityManager.createIdentity(namedArgs)
    } else if (action == "publish") {
        await publish({ entryPath: args[0],  ...namedArgs})
    } else if (action == 'unpublish') {
        // FIXME
    } else {
        console.log(`Sorry I didn't recognize that command (${action})`)
        console.log(`The available commands are:`)
        console.log(`    create-identity`)
        console.log(`    publish`)
        console.log(`    unpublish`)
    }
} catch (error) {
    if (error instanceof UserPickedCancel) {
        Deno.exit(1)
    }
}

async function publish(namedArgs) {
    // 
    // generate identity if needed
    // 
    const jsonDataToPublish = await FileSystem.read(namedArgs.entryPath)
    const { signatureKey, verificationKey, entityUuid, overthrowKeysets } = getIdentityData(namedArgs)
    const overthrowKeys = overthrowKeysets.map(each=>each.verificationKey)

    // 
    // step1 check if identity exists
    // 
    var { value: entityExists } = await contactSever({route: "entityExists", data: { entityUuid }})
    if (!entityExists) {
        const action = "createEntity"
        const actionData = {
            entityUuid,
            normalKeys: {
                [verificationKey]: {
                    hasAllPermissions: true,
                },
            },
            overthrowKeys: overthrowKeys,
            humanReadableName: null,
            email: null,
        }
        const actionSignature = await Encryption.sign({ text: JSON.stringify(actionData), privateKey: signatureKey })
         
        var { error, value: success } = await contactSever({
            route: [action],
            data: {
                identification: {
                    publicVerificationKey: verificationKey,
                    entityUuid,
                    actionSignatures: {
                        [action]: actionSignature,
                    }
                },
                [action]: actionData
            }
        })
        if (error) {
            throw error
        } else {
            console.log("Success!")
        }
    }

    // 
    // step2 handle any update tool info
    //
    // TODO: validate the structure of jsonDataToPublish
    if (jsonDataToPublish.toolInfo) {
        const action = "updateToolInfo"
        const actionData = {
            // FIXME: restrict the tool name
            toolName: jsonDataToPublish.toolInfo.toolName,
            data: {
                blurb: "",
                keywords: [],
                maintainers: [],
                description: null,
                ...jsonDataToPublish.toolInfo.data,
                links: {
                    homepage: null,
                    icon: null,
                    iframeSrc: null,
                    ...jsonDataToPublish.toolInfo.data?.links,
                },
                // FIXME: validate the adjectives, camel case
                adjectives: {
                    ...jsonDataToPublish.toolInfo.data?.adjectives,
                },
            },
        }
        const actionSignature = await Encryption.sign({ text: JSON.stringify(actionData), privateKey: signatureKey })
         
        var { value } = await contactSever({
            route: [action],
            data: {
                identification: {
                    publicVerificationKey: verificationKey,
                    entityUuid,
                    actionSignatures: {
                        [action]: actionSignature,
                    }
                },
                [action]: actionData,
            }
        })
    }
    
    // 
    // step3 handle new release
    //
    // TODO: validate the structure of jsonDataToPublish
    if (jsonDataToPublish.currentRelease) {
        const action = "newReleaseInfo"
        const sourceHashSignature = await Encryption.sign({ text: jsonDataToPublish.currentRelease.recursiveSha256SourceHash, privateKey: signatureKey })
        const actionData = {
            // FIXME: restrict the tool name
            toolName: jsonDataToPublish.currentRelease.toolName,
            data: {
                // TODO: make a helper for performing a recursiveSha256SourceHash
                // FIXME: validate that the source hash exists
                recursiveSha256SourceHash: jsonDataToPublish.currentRelease.recursiveSha256SourceHash,
                sourceHashSignature: sourceHashSignature,
                numericVersion: jsonDataToPublish.currentRelease.numericVersion, // FIXME: validate list of ints
                versionName: jsonDataToPublish.currentRelease.versionName, // optional
                adjectives: {
                    // FIXME: limit to predefined things or "custom."
                    ...jsonDataToPublish.currentRelease.adjectives,
                },
                takesAndGives: [
                    // FIXME: force the takingAnyOf:[] and gives:
                    ...jsonDataToPublish.currentRelease.takesAndGives,
                ],
                possiblyGives: jsonDataToPublish.currentRelease.takesAndGives.reduce((a, b)=>{...a?.gives, ...b?.gives}),
                sources: [
                    // FIXME: validate the structure
                    ...jsonDataToPublish.currentRelease.sources,
                    // {
                    //     "url": "https://github.com/NixOS/nixpkgs/archive/e696cfa9eae0d973126399f90d2e1fd87b980ced.zip", # when URL is downloaded
                    //     "format": {
                    //         commonName: "zip",
                    //         ipfsUrlOfSpecification: "QmWJ8m5QRG3SZqioiDy59JUXhzsQp7ZKQpu4Vcud4RLebK",
                    //     },
                    //     "internalTargets": {
                    //         "nixRootFolder": ".",
                    //         "nixAttributePath": [],
                    //     },
                    //     "customInfo": {
                    //         "date": "2021-02-24",
                    //         "position": "/nix/store/hqc8hlzsl1qyzdyam91kvj1ww22yw538-6c36c4ca061f0c85eed3c96c0b3ecc7901f57bb3.tar.gz/pkgs/development/interpreters/python/cpython/2.7/default.nix:291",
                    //     },
                    // },
                    // {
                    //     "url": "https://github.com/NixOS/nixpkgs.git",
                    //     "format": "git",
                    //     "internalTargets": {
                    //         "gitCommit": "e696cfa9eae0d973126399f90d2e1fd87b980ced",
                    //         "nixRootFolder": ".",
                    //         "nixAttributePath": [],
                    //     },
                    //     "customInfo": {
                    //         "date": "2021-02-24",
                    //         "position": "/nix/store/hqc8hlzsl1qyzdyam91kvj1ww22yw538-6c36c4ca061f0c85eed3c96c0b3ecc7901f57bb3.tar.gz/pkgs/development/interpreters/python/cpython/2.7/default.nix:291",
                    //     },
                    // }
                ],
            },
        }
        const actionSignature = await Encryption.sign({ text: JSON.stringify(actionData), privateKey: signatureKey })
         
        var { value } = await contactSever({
            route: [action],
            data: {
                identification: {
                    publicVerificationKey: verificationKey,
                    entityUuid,
                    actionSignatures: {
                        [action]: actionSignature,
                    }
                },
                [action]: actionData,
            }
        })
        
    }
}

async function getIdentityData(namedArgs) {
    let identities = await IdentityManager.loadIdentities(namedArgs.advancedIdentitiesFilepath)
    const hasNoIdentites = Object.keys(identities).length == 0
    if (hasNoIdentites) {
        console.log("")
        console.log("")
        console.log("So to publish a package, you need an identity")
        console.log(`I see you don't have any (I checked ${namedArgs.advancedIdentitiesFilepath})`)
        console.log("so lets take 5sec and set one up")
        if (!await Console.askFor.yesNo("Sound good?")) {
            console.log(`Okay. And hey, just FYI if this is the wrong path: ${namedArgs.advancedIdentitiesFilepath}`)
            console.log(`You can change it using the --advanced-identities-filepath argument`)
            console.log(``)
            console.log(`Feel free to re-run this when the identity issue is worked out`)
            throw UserPickedExit()
        } else {
            await IdentityManager.createIdentity(namedArgs)
        }
        // reload the file, now that an identity has been created
        identities = await IdentityManager.loadIdentities(namedArgs.advancedIdentitiesFilepath)
    }
    
    // 
    // select identity
    // 
    var selectedIdentity
    const identityNames = Object.keys(identities)
    // if mentioned an identity
    if (namedArgs.identity) {
        // if it exists, move on
        if (identityNames.includes(namedArgs.identity)) {
            selectedIdentity = namedArgs.identity
        // if it doesnt, get one that exists
        } else {
            console.log(`I didn't see ${namedArgs.identity} as one of the options.`)
            if (identityNames.length == 1) {
                if (await Console.askFor.yesNo(`${identityNames[0]} is the only identity I see\nShould I use that one?`)) {
                    selectedIdentity = identityNames[0]
                } else {
                    console.log(`Okay. This command does need an identity so please create one and then rerun this command`)
                    throw UserPickedExit()
                }
            } else {
                console.log(`These are the options I saw:${identityNames.map((each,index)=>`\n${index+1}. ${each}`)}`)
                while (!selectedIdentity) {
                    const name = await Console.askFor.line(`please enter one of those names or cancel`)
                    if (identityNames.includes(searchElement)) {
                        selectedIdentity = name
                        break
                    }
                }
            }
        }
    // if did not mention an identity
    } else {
        // if there's only one identity, just use it
        if (identityNames.length == 1) {
            selectedIdentity = identityNames[0]
        } else {
            console.log(`Please pick an identity to publish with:${identityNames.map((each,index)=>`\n${index+1}. ${each}`)}`)
            console.log(`Note: you can skip being asked this if you use the --identity=IDENTITY_NAME argument`)
            while (!selectedIdentity) {
                const name = await Console.askFor.line(`please enter one of those names or cancel`)
                if (identityNames.includes(searchElement)) {
                    selectedIdentity = name
                    break
                }
            }
        }
    }
    
    const identity = identities[selectedIdentity]
    let signatureKey     = identity?.mainKeyset?.signatureKey
    let verificationKey  = identity?.mainKeyset?.verificationKey
    let entityUuid       = identity?.entityUuid
    let overthrowKeysets = identity?.overthrowKeysets

    if (!signatureKey || !verificationKey || !entityUuid || !(overthrowKeysets instanceof Array) || overthrowKeysets.length < 2) {
        throw Error(`\n\n\nSo I loaded the ${selectedIdentity} identity from ${namedArgs.advancedIdentitiesFilepath}\nHowever, when I tried to get some of the necessary values I wasn't able to.\nI expected something like the following:
            ${JSON.stringify(selectedIdentity)}: {
                "entityUuid": "aldkjflkasdjflajsdlfjasdlkjfaldksjf",
                "mainKeyset": {
                    "signatureKey": "aldkjflkasdjflajsdlfjasdlkjfaldksjf",
                    "verificationKey": "aldkjflkasdjflajsdlfjasdlkjfaldksjf"
                },
                "overthrowKeysets": [
                    {
                        "encryptionKey": "aldkjflkasdjflajsdlfjasdlkjfaldksjf",
                        "verificationKey": "aldkjflkasdjflajsdlfjasdlkjfaldksjf"
                    },
                    {
                        "encryptionKey": "aldkjflkasdjflajsdlfjasdlkjfaldksjf",
                        "verificationKey": "aldkjflkasdjflajsdlfjasdlkjfaldksjf"
                    },
                    {
                        "encryptionKey": "aldkjflkasdjflajsdlfjasdlkjfaldksjf",
                        "verificationKey": "aldkjflkasdjflajsdlfjasdlkjfaldksjf"
                    }
                ]
            }\nWhat I got instead was something like: ${indent({ string: JSON.stringify(identity, 0, 4), indent: "                " })}\n\nPlease fix the file, or use this tool to generate a new identity
        `)
    }

    return { signatureKey, verificationKey, entityUuid, overthrowKeysets }
}