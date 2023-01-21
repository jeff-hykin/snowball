import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { run, throwIfFails, zipInto, mergeInto, returnAsString, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo } from "https://deno.land/x/quickr@0.5.0/main/run.js"
import { Console, clearStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, hidden, strikethrough, visible, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.3.44/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.8/string.js"
import * as Encryption from "https://deno.land/x/good@0.7.8/encryption.js"
import { deepCopy, allKeyDescriptions, deepSortObject, shallowSortObject } from "https://deno.land/x/good@0.7.8/value.js"
import { IdentityManager } from "../support/identity_manager.js"
import { parse } from "https://deno.land/std@0.173.0/flags/mod.ts"

import {
  Checkbox,
  Confirm,
  Input,
  Number,
  prompt,
} from "https://deno.land/x/cliffy@v0.25.7/prompt/mod.ts"


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
    let idenities = await IdentityManager.loadIdentities(namedArgs.advancedIdentitiesFilepath)
    const hasNoIdentites = Object.keys(idenities).length == 0
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
        idenities = await IdentityManager.loadIdentities(namedArgs.advancedIdentitiesFilepath)
    }
    
    // 
    // select identity
    // 
    var selectedIdentity
    const identityNames = Object.keys(idenities)
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
            while (!selectedIdentity) {
                const name = await Console.askFor.line(`please enter one of those names or cancel`)
                if (identityNames.includes(searchElement)) {
                    selectedIdentity = name
                    break
                }
            }
        }
    }
    if (namedArgs.identity) {
        if (!idenities[namedArgs.identity]) {
        }
        signatureKey = idenities[namedArgs.identity]?.mainKeyset?.signatureKey
        verificationKey = idenities[namedArgs.identity]?.mainKeyset?.verificationKey
    }

    // Object.keys(idenities).identity == 0
    
    // if (!namedArgs.identity && ) {
    //     console.log(`I see you didn't include an --identity argument`)
    //     await Console.askFor.line(``)
    //     throw Error(`Please include a '--identity WHICH_identity' argument. If you don't have an identity, create one with the 'publisher createIdentity' command`)
    // }
    
    // TODO: add a lot more structure checks/warnings/errors

    // 
    // extract info
    // 
    const signatureKey = idenities[namedArgs.identity].mainKeyset.signatureKey
    const verificationKey = idenities[namedArgs.identity].mainKeyset.verificationKey
    const overthrowKeys = overthrowKeysets.map(each=>each.verificationKey)
    const sourceHash = jsonDataToPublish?.instance?.sourceHash

    // 
    // modify object being published
    // 
    jsonDataToPublish.flavor.advertiser.verificationKey = verificationKey
    jsonDataToPublish.flavor.advertiser.overthrowKeys = overthrowKeys
    jsonDataToPublish.instance = {...jsonDataToPublish.instance}
    jsonDataToPublish.instance.sourceHashSignature = null

    // the order of keys matters when converting to a JSON string
    jsonDataToPublish = deepSortObject(jsonDataToPublish)
    
    if (sourceHash) {
        jsonDataToPublish.instance.sourceHashSignature = await Encryption.sign({ text: JSON.stringify(jsonDataToPublish.instance), privateKey: signatureKey })
    }
    jsonDataToPublish.instance.sourceHashSignature = await Encryption.sign({ text: JSON.stringify(jsonDataToPublish), privateKey: signatureKey })
    
    // FIXME: post request using jsonDataToPublish
    // TODO: should ask for target URL
}