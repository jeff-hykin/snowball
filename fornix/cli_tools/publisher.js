import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { Console, clearStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, hidden, strikethrough, visible, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.3.44/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.2/string.js"
import * as Encryption from "https://deno.land/x/good@0.7.2/encryption.js"

const [ action, ...args ] = Deno.args


if (action == "create_identity") { 
    // 
    // load idenity file
    // 
    let identitiesPath = `${FileSystem.home}/.idenities.json` 
    if (args[0] == '--identities_filepath' && typeof args[1] == 'string') {
        identitiesPath = args[1]
    }
    const fileInfo = await FileSystem.info(identitiesPath)
    let idenities
    if (!fileInfo.exists) {
        idenities = {}
    } else if (fileInfo.exists) {
        let contents
        try {
            contents = await FileSystem.read(identitiesPath)
            if (!contents) {
                idenities = {}
            } else {
                idenities = JSON.parse(contents)
            }
        } catch (error) {
        }
        if (!(idenities instanceof Object)) {
            console.error(`It appears the idenities file: ${identitiesPath} is corrupted (not a JSON object)\n\nNOTE: this file might contain important information so you may want to salvage it.`)
            console.log(`Here are the current contents (indented for visual help):\n${indent(contents)}`)
            while (1) {
                let shouldDelete = false
                const isImportant = await Console.askFor.yesNo(`Do the contents look important?`)
                if (!isImportant) {
                    shouldDelete = await Console.askFor.yesNo(`Should I DELETE this and overwrite it with new keys? (irreversable)`)
                }
                if (isImportant || !shouldDelete) {
                    console.log("Okay, this program will quit. Please fix the contents by making them into a valid JSON object.")
                    Deno.exit()
                }
            }
        }
    }
    
    // 
    // get idenity name
    // 
    let identityName = ""
    create_identity: while (1) {
        identityName = await Console.askFor.line(`What should I call the new idenity?`)
        if (!identityName.length) {
            console.error("The name can't be empty")
            continue create_identity
        } else if (idenities[identityName]) {
            console.log(``)
            console.warn("It looks like there's already an idenity with that name")
            const shouldDelete = await Console.askFor.yesNo(`Should I DELETE that idenity and overwrite it with new keys? (irreversable)`)
            if (!shouldDelete) {
                continue create_identity
            }
            break
        }
        break
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
}

if (action == "publish") {
    // Needs JSON package data being published
    // Needs main key
    // should ask for backup public keys
    // should ask for target URL
    Encryption.sign({ text: JSON.stringify(publication), privateKey: keys.signatureKey })
}