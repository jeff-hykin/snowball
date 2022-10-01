import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { Console, clearStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, hidden, strikethrough, visible, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.3.44/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.2/string.js"
import * as Encryption from "https://deno.land/x/good@0.7.2/encryption.js"
import { deepCopy, allKeyDescriptions, deepSortObject, shallowSortObject } from "https://deno.land/x/good@0.7.2/value.js"
import { readIdenityFile } from "../support/utils.js"

// 
// parse args
// 
const [ action, ...args ] = Deno.args
const namedArgs = {
    identitiesFilepath: `${FileSystem.home}/.idenities.json`,
    identity: null,
}
let index = -1
for (const each of args) {
    index += 1
    if (each.startsWith("--")) {
        namedArgs[each.slice(2,)] = args[index+1]
    }
}

// 
// pick operation
// 
if (action == "createIdentity") { 
    // 
    // load identity file
    // 
    const idenities = await readIdenityFile(namedArgs.identitiesFilepath)
    
    // 
    // get identity name
    // 
    let identityName = namedArgs.identity
    if (!identityName) {
        createIdentity: while (1) {
            identityName = await Console.askFor.line(`What should I call the new identity?`)
            if (!identityName.length) {
                console.error("The name can't be empty")
                continue createIdentity
            } else if (idenities[identityName]) {
                console.log(``)
                console.warn("It looks like there's already an identity with that name")
                const shouldDelete = await Console.askFor.yesNo(`Should I DELETE that identity and overwrite it with new keys? (irreversable)`)
                if (!shouldDelete) {
                    continue createIdentity
                }
                break
            }
            break
        }
    }

    // 
    // make keys
    // 
    const numberOfKeys = 4
    const keySets = []
    for (const each in [...Array(numberOfKeys)]) {
        console.log(`Generating keys, set ${1+each} of ${numberOfKeys}`)
        keySets.push(await Encryption.generateKeys())
    }
    
    // 
    // save keys
    // 
    idenities[identityName] = {
        mainKeyset: keySets[0],
        overthrowKeysets: keySets.slice(1).map(
            each=>({
                encryptionKey: each.encryptionKey,
                verificationKey: each.verificationKey,
            })
        ),
    }
    
    await FileSystem.write({
        data: JSON.stringify(idenities,0,4),
        path: identitiesPath,
    })
    console.log(`Main keys saved under "${identityName}" in ${identitiesPath}\n\n`)
    console.log("I'm about to print out your OVERTHROW keys\n    Store each of these in different physical locations\n    (on your phone, on paper, in a draft email, etc)\n    If your main key gets compromised\n    two of these keys can be combined to 'overthrow' your main key.\n\n    THERE IS NO OTHER BACKUP/RECOVERY SYSTEM\n")
    await Console.askFor.yesNo("Understand?")
    let number = 0
    for (let eachKeySet of keySets.slice(1)) {
        number += 1
        console.log(`\noverthrow key ${number}:`)
        console.log(`    decryptionKey: ${eachKeySet.decryptionKey}`)
        console.log(`    signatureKey: ${eachKeySet.signatureKey}`)
    }
} else if (action == "publish") {
    // 
    // handle args (could use improving)
    // 
    const jsonDataToPublish = await FileSystem.read(args[0])
    if (!namedArgs.identity) {
        throw Error(`Please include a '--idenity WHICH_IDENITY' argument. If you don't have an idenity, create one with the 'publisher createIdentity' command`)
    }
    const idenities = await readIdenityFile(namedArgs.identitiesFilepath)
    
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