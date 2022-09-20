import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { Console, clearStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, hidden, strikethrough, visible, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.3.44/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.2/string.js"
import * as Encryption from "https://deno.land/x/good@0.7.2/encryption.js"

const [ action, ...args ] = Deno.args


if (action == "create_identity") { 
    while (1) {
        const identitiesPath = Console.env.IDENTITIES_FILEPATH || `${FileSystem.home}/.idenities.json`
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

        create_identity: while (1) {
            const name = await Console.askFor.line(`What should I call the new idenity?`)
            if (!name.length) {
                console.error("The name can't be empty")
                continue create_identity
            } else if (idenities[name]) {
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
        const numberOfKeys = 5
        const keySets = []
        for (const each in [...Array(numberOfKeys)]) {
            console.log(`Generating keys, set ${each} of ${numberOfKeys}`)
            keySets.push(await Encryption.generateKeys())
        }
        
        // FIXME: include the main public&private, and all the public backup keys, but ask the user where to store all the private backup keys
        break
    }
}

if (action == "publish") {
    // Needs JSON package data being published
    // Needs main key
    // should ask for backup public keys
    // should ask for target URL
    Encryption.sign({ text: JSON.stringify(publication), privateKey: keys.signatureKey })
}