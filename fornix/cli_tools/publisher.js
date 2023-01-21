import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { run, throwIfFails, zipInto, mergeInto, returnAsString, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo } from "https://deno.land/x/quickr@0.5.0/main/run.js"
import { Console, clearStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, hidden, strikethrough, visible, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.3.44/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.2/string.js"
import * as Encryption from "https://deno.land/x/good@0.7.2/encryption.js"
import { deepCopy, allKeyDescriptions, deepSortObject, shallowSortObject } from "https://deno.land/x/good@0.7.2/value.js"
import { IdentityManager } from "../support/idenity_manager.js"


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
}
let index = -1
for (const each of args) {
    index += 1
    if (each.startsWith("--")) {
        let key = each.slice(2,)
        // kebab case to camel case
        key = toCamelCase(key)
        namedArgs[key] = args[index+1]
    }
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
    // handle args (could use improving)
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
            await createIdentity(namedArgs)
        }
        // reload the file, now that an identity has been created
        idenities = await readIdentityFile(namedArgs.advancedIdentitiesFilepath)
    }
    
    if (namedArgs.identity) {
        const signatureKey = idenities[namedArgs.identity]?.mainKeyset?.signatureKey
        const verificationKey = idenities[namedArgs.identity]?.mainKeyset?.verificationKey
    }
    if (idenities[namedArgs.identity])

    Object.keys(idenities).identity == 0
    
    if (!namedArgs.identity && ) {
        console.log(`I see you didn't include an --identity argument`)
        await Console.askFor.line(``)
        throw Error(`Please include a '--identity WHICH_IDENITY' argument. If you don't have an identity, create one with the 'publisher createIdentity' command`)
    }
    
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