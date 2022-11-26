import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.2/string.js"
import * as Encryption from "https://deno.land/x/good@0.7.2/encryption.js"
import { deepCopy, allKeyDescriptions, deepSortObject, shallowSortObject } from "https://deno.land/x/good@0.7.2/value.js"
import { commonInterface } from "./common_interface.js"

/**
 * Interface connection
 *
 * @note
 *     implementation expects
 *         async FileSystem.info(path)
 *         async FileSystem.read(path)
 *         async FileSystem.home
 *         async Console.askFor.line(message)
 *         async Console.askFor.yesNo(message)
 *         async Custom.getDefaultIdenityName()
 *         async Custom.userAborted()
 *         Console.log(...args)
 *         Console.error(...args)
 *         Console.warn(...args)
 */
const connectInterface = ({ FileSystem, Console, Custom })=>({
    nameRules: [
        {
            message: "Name cannot be an empty string",
            passesCheck: (name)=>`${name}`.length > 0,
        },
        {
            message: "Name cannot start with a #",
            passesCheck: (name)=>(`${name} `[0] != "#"),
        },
        {
            message: "Name cannot contain space/tab/newlines/etc (whitespace)",
            passesCheck: (name)=>!!(`${name}`.match(/\s/)),
        },
        {
            message: "Name can't be more than 256 chars",
            passesCheck: (name)=>`${name}`.length <= 256,
        }
    ],
    reasonForInvalidName(name) {
        for (const eachRule of IdentityManager.nameRules) {
            if (!eachRule.passesCheck(name)) {
                return eachRule.message
            }
        }
        // name is valid
        return null
    },
    defaultPath: `${FileSystem.home}/.idenities.json`,
    
    async createIdentity(namedArgs) {
        namedArgs = {
            advancedIdentitiesFilepath: `${await FileSystem.home}/.idenities.json`,
            identity: null,
            ...namedArgs,
        }

        // 
        // load identity file
        // 
        const identitiesPath = namedArgs.advancedIdentitiesFilepath
        const idenities = await this.loadIdentities(namedArgs.advancedIdentitiesFilepath)
        
        // 
        // get identity name
        // 
        let identityName = namedArgs.identity
        if (!identityName) {
            createIdentity: while (1) {
                let defaultName = await Custom.getDefaultIdenityName()
                identityName = await Console.askFor.line(`What should I call the new identity?`) || defaultName
                const isInvalidReason = this.reasonForInvalidName(identityName)
                if (isInvalidReason) {
                    Console.error(isInvalidReason)
                    Console.error("Here's all the rules")
                    for (const each of this.nameRules) {
                        Console.error(`    ${each.message}`)
                    }
                    continue createIdentity
                } else if (idenities[identityName]) {
                    Console.log(``)
                    Console.warn("It looks like there's already an identity with that name")
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
            Console.log(`Generating keys, set ${1+each} of ${numberOfKeys}`)
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
        Console.log(`Main keys saved under "${identityName}" in ${identitiesPath}\n\n`)
        Console.log("I'm about to print out your OVERTHROW keys\n    Store each of these in different physical locations\n    (on your phone, on paper, in a draft email, etc)\n    If your main key gets compromised\n    two of these keys can be combined to 'overthrow' your main key.\n\n    THERE IS NO OTHER BACKUP/RECOVERY SYSTEM\n")
        await Console.askFor.yesNo("Understand?")
        let number = 0
        for (let eachKeySet of keySets.slice(1)) {
            number += 1
            Console.log(`\noverthrow key ${number}:`)
            Console.log(`    decryptionKey: ${eachKeySet.decryptionKey}`)
            Console.log(`    signatureKey: ${eachKeySet.signatureKey}`)
        }
    },
    
    async loadIdentities(identitiesPath) {
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
                Console.error(`It appears the idenities file: ${identitiesPath} is corrupted (not a JSON object)\n\nNOTE: this file might contain important information so you may want to salvage it.`)
                Console.log(`Here are the current contents (indented for visual help):\n${indent(contents)}`)
                while (1) {
                    let shouldDelete = false
                    const isImportant = await Console.askFor.yesNo(`Do the contents look important?`)
                    if (!isImportant) {
                        shouldDelete = await Console.askFor.yesNo(`Should I DELETE this and overwrite it with new keys? (irreversable)`)
                    }
                    if (isImportant || !shouldDelete) {
                        Console.log("Okay, this program will quit. Please fix the contents by making them into a valid JSON object.")
                        await Custom.userAborted()
                    }
                }
            }
        }
        return idenities
    },
})

export const IdentityManager = connectInterface(commonInterface)