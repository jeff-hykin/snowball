import { FileSystem } from 'https://deno.land/x/quickr@0.3.44/main/file_system.js'
import { Console, clearStylesFrom, black, white, red, green, blue, yellow, cyan, magenta, lightBlack, lightWhite, lightRed, lightGreen, lightBlue, lightYellow, lightMagenta, lightCyan, blackBackground, whiteBackground, redBackground, greenBackground, blueBackground, yellowBackground, magentaBackground, cyanBackground, lightBlackBackground, lightRedBackground, lightGreenBackground, lightYellowBackground, lightBlueBackground, lightMagentaBackground, lightCyanBackground, lightWhiteBackground, bold, reset, dim, italic, underline, inverse, hidden, strikethrough, visible, gray, grey, lightGray, lightGrey, grayBackground, greyBackground, lightGrayBackground, lightGreyBackground, } from "https://deno.land/x/quickr@0.3.44/main/console.js"
import { capitalize, indent, toCamelCase, digitsToEnglishArray, toPascalCase, toKebabCase, toSnakeCase, toScreamingtoKebabCase, toScreamingtoSnakeCase, toRepresentation, toString } from "https://deno.land/x/good@0.7.2/string.js"
import { DOMParser, Element, } from "https://deno.land/x/deno_dom/deno-dom-wasm.ts"
import { createHash } from "https://deno.land/std@0.139.0/hash/mod.ts"
import { deferred } from "https://deno.land/std@0.173.0/async/deferred.ts";

export const tempFolder = `${FileSystem.thisFolder}/../cache.ignore/`
await FileSystem.ensureIsFolder(tempFolder)

export async function sha256(message) {
    const msgBuffer = new TextEncoder().encode(message)
    const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
    return hashHex
}

export async function hash(string) {
    return BigInt(await sha256(string, 'utf-8', 'hex'), 16) 
}

export function makeSafeFileName(string) {
    return [...string].map((each,index)=>each.charCodeAt(0).toString(16).padStart(2,"0")).join("")
}

// all these strings look like length 1, all of them them should be length 1, but depending on the deno version, not all of them are length 1
// which is why this is an array and not a string
export const emojiCodes = [
    "😀",
    "😆",
    "😅",
    "🤣",
    "🙃",
    "🫠",
    "😉",
    "😇",
    "🥰",
    "🤩",
    "😘",
    "🥲",
    "😜",
    "🤪",
    "🤑",
    "🤗",
    "🤭",
    "🫣",
    "🤫",
    "🤔",
    "🫡",
    "🤐",
    "🤨",
    "😐",
    "😑",
    "😶",
    "😏",
    "😒",
    "🙄",
    "😬",
    "🤥",
    "😌",
    "😔",
    "😪",
    "🤤",
    "😴",
    "😷",
    "🤢",
    "🤮",
    "🤧",
    "🥵",
    "🥶",
    "🥴",
    "😵",
    "🤯",
    "🤠",
    "🥳",
    "🥸",
    "😎",
    "🤓",
    "🧐",
    "🫤",
    "🙁",
    "😲",
    "😳",
    "🥹",
    "😧",
    "😰",
    "😢",
    "😭",
    "😱",
    "😖",
    "😞",
    "😓",
    "😫",
    "🥱",
    "😤",
    "😡",
    "🤬",
    "😈",
    "💀",
    "💩",
    "🤡",
    "👺",
    "👻",
    "👽",
    "👾",
    "🤖",
    "😺",
    "😹",
    "😻",
    "😼",
    "😽",
    "🙀",
    "😿",
    "😾",
    "🙈",
    "🙉",
    "🙊",
    "💌",
    "💘",
    "💖",
    "💕",
    "💟",
    "💔",
    "🧡",
    "💛",
    "💚",
    "💙",
    "💜",
    "🤎",
    "🖤",
    "🤍",
    "💋",
    "💯",
    "💢",
    "💥",
    "💫",
    "💦",
    "💨",
    "🕳",
    "💬",
    "🗨",
    "🗯",
    "💭",
    "💤",
    "👋",
    "🤚",
    "🖖",
    "🫱",
    "🫲",
    "🫳",
    "🫴",
    "👌",
    "🤌",
    "🤏",
    "🤞",
    "🫰",
    "🤟",
    "🤙",
    "👈",
    "👉",
    "👆",
    "🖕",
    "👇",
    "🫵",
    "👍",
    "👎",
    "✊",
    "👊",
    "🤛",
    "🤜",
    "👏",
    "🙌",
    "🫶",
    "👐",
    "🤲",
    "🤝",
    "🙏",
    "💅",
    "🤳",
    "💪",
    "🦾",
    "🦿",
    "🦵",
    "🦶",
    "👂",
    "👃",
    "🧠",
    "🫀",
    "🫁",
    "🦷",
    "🦴",
    "👀",
    "👁",
    "👅",
    "👄",
    "🫦",
    "👶",
    "👨",
    "🧔‍♂️",
    "🧔‍♀️",
    "👨‍🦰",
    "👨‍🦱",
    "👨‍🦳",
    "👩",
    "👩‍🦰",
    "🧑‍🦰",
    "👩‍🦱",
    "🧑‍🦱",
    "👩‍🦳",
    "🧑‍🦳",
    "🧑‍🦲",
    "👱‍♀️",
    "🧓",
    "👴",
    "👵",
    "🙍",
    "🙎",
    "🙅",
    "🙆",
    "💁",
    "🙋",
    "🧏",
    "🙇",
    "🤦",
    "🤷",
    "👮",
    "🕵",
    "💂",
    "🥷",
    "👷",
    "🫅",
    "🤴",
    "👸",
    "👳",
    "👲",
    "🧕",
    "🤵",
    "👰",
    "🤰",
    "🫃",
    "🫄",
    "🤱",
    "👼",
    "🎅",
    "🤶",
    "🦸",
    "🦹",
    "🧙",
    "🧚",
    "🧛",
    "🧜",
    "🧝",
    "🧞",
    "🧟",
    "🧌",
    "💆",
    "💇",
    "🚶",
    "🧍",
    "🧎",
    "🏃",
    "💃",
    "🕺",
    "🕴",
    "👯",
    "🧖",
    "🧗",
    "🤺",
    "🏇",
    "⛷",
    "🏂",
    "🏌",
    "🏄",
    "🚣",
    "🏊",
    "⛹",
    "🏋",
    "🚴",
    "🚵",
    "🤸",
    "🤼",
    "🤽",
    "🤾",
    "🤹",
    "🧘",
    "🛀",
    "🛌",
    "💑",
    "👪",
    "🗣",
    "👤",
    "👥",
    "👣",
    "🐒",
    "🦍",
    "🦧",
    "🐶",
    "🐕",
    "🐩",
    "🐺",
    "🦊",
    "🦝",
    "🐈",
    "🦁",
    "🐯",
    "🐅",
    "🐆",
    "🐴",
    "🐎",
    "🦄",
    "🦓",
    "🦌",
    "🦬",
    "🐮",
    "🐂",
    "🐃",
    "🐄",
    "🐷",
    "🐖",
    "🐗",
    "🐽",
    "🐏",
    "🐑",
    "🐐",
    "🐪",
    "🐫",
    "🦙",
    "🦒",
    "🐘",
    "🦣",
    "🦏",
    "🦛",
    "🐭",
    "🐁",
    "🐀",
    "🐹",
    "🐰",
    "🐇",
    "🐿",
    "🦫",
    "🦔",
    "🦇",
    "🐻",
    "🐨",
    "🐼",
    "🦥",
    "🦦",
    "🦨",
    "🦘",
    "🦡",
    "🐾",
    "🦃",
    "🐔",
    "🐓",
    "🐣",
    "🐤",
    "🐥",
    "🐦",
    "🐧",
    "🕊",
    "🦅",
    "🦆",
    "🦢",
    "🦉",
    "🦤",
    "🪶",
    "🦩",
    "🦚",
    "🦜",
    "🐸",
    "🐊",
    "🐢",
    "🦎",
    "🐍",
    "🐲",
    "🐉",
    "🦕",
    "🦖",
    "🐳",
    "🐋",
    "🐬",
    "🦭",
    "🐟",
    "🐠",
    "🐡",
    "🦈",
    "🐙",
    "🐚",
    "🪸",
    "🐌",
    "🦋",
    "🐛",
    "🐜",
    "🐝",
    "🪲",
    "🐞",
    "🦗",
    "🪳",
    "🕷",
    "🕸",
    "🦂",
    "🦟",
    "🪰",
    "🪱",
    "🦠",
    "💐",
    "🌸",
    "💮",
    "🪷",
    "🏵",
    "🌹",
    "🥀",
    "🌺",
    "🌻",
    "🌼",
    "🌷",
    "🌱",
    "🪴",
    "🌲",
    "🌳",
    "🌴",
    "🌵",
    "🌾",
    "🌿",
    "🍀",
    "🍁",
    "🍂",
    "🍃",
    "🪹",
    "🪺",
    "🍄",
    "🍇",
    "🍈",
    "🍉",
    "🍊",
    "🍋",
    "🍌",
    "🍍",
    "🥭",
    "🍎",
    "🍏",
    "🍐",
    "🍑",
    "🍒",
    "🍓",
    "🫐",
    "🥝",
    "🍅",
    "🫒",
    "🥥",
    "🥑",
    "🍆",
    "🥔",
    "🥕",
    "🌽",
    "🌶",
    "🫑",
    "🥒",
    "🥬",
    "🥦",
    "🧄",
    "🧅",
    "🥜",
    "🫘",
    "🌰",
    "🍞",
    "🥐",
    "🥖",
    "🫓",
    "🥨",
    "🥯",
    "🥞",
    "🧇",
    "🧀",
    "🍖",
    "🍗",
    "🥩",
    "🥓",
    "🍔",
    "🍟",
    "🍕",
    "🌭",
    "🥪",
    "🌮",
    "🌯",
    "🫔",
    "🥙",
    "🧆",
    "🥚",
    "🍳",
    "🥘",
    "🍲",
    "🫕",
    "🥣",
    "🥗",
    "🍿",
    "🧈",
    "🧂",
    "🥫",
    "🍱",
    "🍘",
    "🍙",
    "🍚",
    "🍛",
    "🍜",
    "🍝",
    "🍠",
    "🍢",
    "🍣",
    "🍤",
    "🍥",
    "🥮",
    "🍡",
    "🥟",
    "🥠",
    "🥡",
    "🦀",
    "🦞",
    "🦐",
    "🦑",
    "🦪",
    "🍦",
    "🍧",
    "🍨",
    "🍩",
    "🍪",
    "🎂",
    "🍰",
    "🧁",
    "🥧",
    "🍫",
    "🍬",
    "🍭",
    "🍮",
    "🍯",
    "🍼",
    "🥛",
    "🫖",
    "🍵",
    "🍶",
    "🍾",
    "🍷",
    "🍸",
    "🍹",
    "🍺",
    "🍻",
    "🥂",
    "🥃",
    "🫗",
    "🥤",
    "🧋",
    "🧃",
    "🧉",
    "🧊",
    "🥢",
    "🍽",
    "🍴",
    "🥄",
    "🔪",
    "🫙",
    "🏺",
    "🌍",
    "🌎",
    "🌏",
    "🌐",
    "🗺",
    "🗾",
    "🧭",
    "🏔",
    "⛰",
    "🌋",
    "🗻",
    "🏕",
    "🏖",
    "🏜",
    "🏝",
    "🏞",
    "🏟",
    "🏛",
    "🏗",
    "🧱",
    "🪨",
    "🪵",
    "🛖",
    "🏘",
    "🏚",
    "🏠",
    "🏡",
    "🏢",
    "🏣",
    "🏤",
    "🏥",
    "🏦",
    "🏨",
    "🏩",
    "🏪",
    "🏫",
    "🏬",
    "🏭",
    "🏯",
    "🏰",
    "💒",
    "🗼",
    "🗽",
    "⛪",
    "🕌",
    "🛕",
    "🕍",
    "⛩",
    "🕋",
    "⛲",
    "⛺",
    "🌁",
    "🌃",
    "🏙",
    "🌄",
    "🌅",
    "🌆",
    "🌇",
    "🌉",
    "🎠",
    "🛝",
    "🎡",
    "🎢",
    "💈",
    "🎪",
    "🚂",
    "🚃",
    "🚄",
    "🚅",
    "🚆",
    "🚇",
    "🚈",
    "🚉",
    "🚊",
    "🚝",
    "🚞",
    "🚋",
    "🚌",
    "🚍",
    "🚎",
    "🚐",
    "🚑",
    "🚒",
    "🚓",
    "🚔",
    "🚕",
    "🚖",
    "🚗",
    "🚘",
    "🚙",
    "🛻",
    "🚚",
    "🚛",
    "🚜",
    "🏎",
    "🏍",
    "🛵",
    "🦽",
    "🦼",
    "🛺",
    "🚲",
    "🛴",
    "🛹",
    "🛼",
    "🚏",
    "🛣",
    "🛤",
    "🛢",
    "⛽",
    "🛞",
    "🚨",
    "🚦",
    "🛑",
    "🚧",
    "🛟",
    "⛵",
    "🛶",
    "🚤",
    "🛳",
    "⛴",
    "🛥",
    "🚢",
    "🛩",
    "🛫",
    "🛬",
    "🪂",
    "💺",
    "🚁",
    "🚟",
    "🚠",
    "🚡",
    "🛰",
    "🚀",
    "🛸",
    "🛎",
    "🧳",
    "⌛",
    "⏳",
    "⌚",
    "⏰",
    "⏱",
    "⏲",
    "🕰",
    "🕑",
    "🌑",
    "🌒",
    "🌓",
    "🌔",
    "🌕",
    "🌖",
    "🌗",
    "🌘",
    "🌙",
    "🌚",
    "🌛",
    "🌜",
    "🌡",
    "🌝",
    "🌞",
    "🪐",
    "⭐",
    "🌟",
    "🌠",
    "🌌",
    "⛅",
    "⛈",
    "🌤",
    "🌥",
    "🌦",
    "🌧",
    "🌨",
    "🌩",
    "🌪",
    "🌫",
    "🌬",
    "🌀",
    "🌈",
    "🌂",
    "⛱",
    "🔥",
    "💧",
    "🌊",
    "🎃",
    "🎄",
    "🎆",
    "🎇",
    "🧨",
    "✨",
    "🎈",
    "🎉",
    "🎊",
    "🎋",
    "🎍",
    "🎎",
    "🎏",
    "🎐",
    "🎑",
    "🧧",
    "🎀",
    "🎁",
    "🎗",
    "🎟",
    "🎫",
    "🎖",
    "🏆",
    "🏅",
    "🥇",
    "🥈",
    "🥉",
    "⚽",
    "⚾",
    "🥎",
    "🏀",
    "🏐",
    "🏈",
    "🏉",
    "🎾",
    "🥏",
    "🎳",
    "🏏",
    "🏑",
    "🏒",
    "🥍",
    "🏓",
    "🏸",
    "🥊",
    "🥋",
    "🥅",
    "⛳",
    "⛸",
    "🎣",
    "🤿",
    "🎽",
    "🎿",
    "🛷",
    "🥌",
    "🎯",
    "🪀",
    "🪁",
    "🔫",
    "🎱",
    "🔮",
    "🪄",
    "🎮",
    "🕹",
    "🎰",
    "🎲",
    "🧩",
    "🧸",
    "🪅",
    "🪩",
    "🪆",
    "🃏",
    "🀄",
    "🎴",
    "🎭",
    "🖼",
    "🎨",
    "🧵",
    "🪡",
    "🧶",
    "🪢",
    "👓",
    "🕶",
    "🥽",
    "🥼",
    "🦺",
    "👔",
    "👕",
    "👖",
    "🧣",
    "🧤",
    "🧥",
    "🧦",
    "👗",
    "👘",
    "🥻",
    "🩱",
    "🩲",
    "🩳",
    "👙",
    "👚",
    "👛",
    "👜",
    "👝",
    "🛍",
    "🎒",
    "🩴",
    "👞",
    "👟",
    "🥾",
    "🥿",
    "👠",
    "👡",
    "🩰",
    "👢",
    "👑",
    "👒",
    "🎩",
    "🎓",
    "🧢",
    "🪖",
    "⛑",
    "📿",
    "💄",
    "💍",
    "💎",
    "🔇",
    "🔈",
    "🔉",
    "🔊",
    "📢",
    "📣",
    "📯",
    "🔔",
    "🔕",
    "🎙",
    "🎚",
    "🎛",
    "🎤",
    "🎧",
    "📻",
    "🎷",
    "🪗",
    "🎸",
    "🎹",
    "🎺",
    "🎻",
    "🪕",
    "🥁",
    "🪘",
    "📲",
    "📞",
    "📟",
    "📠",
    "🔋",
    "🪫",
    "🔌",
    "💻",
    "🖥",
    "🖨",
    "🖱",
    "🖲",
    "💽",
    "💾",
    "💿",
    "📀",
    "🧮",
    "🎥",
    "🎞",
    "📽",
    "🎬",
    "📺",
    "📷",
    "📸",
    "📹",
    "📼",
    "🔍",
    "🔎",
    "🕯",
    "💡",
    "🔦",
    "🏮",
    "🪔",
    "📔",
    "📕",
    "📖",
    "📗",
    "📘",
    "📙",
    "📚",
    "📓",
    "📒",
    "📃",
    "📜",
    "📄",
    "📰",
    "🗞",
    "📑",
    "🔖",
    "🏷",
    "💰",
    "🪙",
    "💴",
    "💵",
    "💶",
    "💷",
    "💸",
    "💳",
    "🧾",
    "💹",
    "📧",
    "📨",
    "📩",
    "📤",
    "📥",
    "📦",
    "📫",
    "📪",
    "📬",
    "📭",
    "📮",
    "🗳",
    "🖋",
    "🖊",
    "🖌",
    "🖍",
    "📝",
    "💼",
    "📁",
    "📂",
    "🗂",
    "📅",
    "📆",
    "🗒",
    "🗓",
    "📇",
    "📈",
    "📉",
    "📊",
    "📋",
    "📌",
    "📍",
    "📎",
    "🖇",
    "📏",
    "📐",
    "🗃",
    "🗄",
    "🗑",
    "🔒",
    "🔓",
    "🔏",
    "🔐",
    "🔑",
    "🗝",
    "🔨",
    "🪓",
    "⛏",
    "🛠",
    "🗡",
    "💣",
    "🪃",
    "🏹",
    "🛡",
    "🪚",
    "🔧",
    "🪛",
    "🔩",
    "🗜",
    "🦯",
    "🔗",
    "⛓",
    "🪝",
    "🧰",
    "🧲",
    "🪜",
    "🧪",
    "🧫",
    "🧬",
    "🔬",
    "🔭",
    "📡",
    "💉",
    "🩸",
    "💊",
    "🩹",
    "🩼",
    "🩺",
    "🩻",
    "🚪",
    "🛗",
    "🪞",
    "🪟",
    "🛏",
    "🛋",
    "🪑",
    "🚽",
    "🪠",
    "🚿",
    "🛁",
    "🪤",
    "🪒",
    "🧴",
    "🧷",
    "🧹",
    "🧺",
    "🧻",
    "🪣",
    "🧼",
    "🫧",
    "🪥",
    "🧽",
    "🧯",
    "🛒",
    "🚬",
    "🪦",
    "🧿",
    "🗿",
    "🪧",
    "🪪",
    "🏧",
    "🚮",
    "🚰",
    "🚹",
    "🚺",
    "🚻",
    "🚼",
    "🚾",
    "🛂",
    "🛃",
    "🛄",
    "🛅",
    "🚸",
    "⛔",
    "🚫",
    "🚳",
    "🚭",
    "🚯",
    "🚱",
    "🚷",
    "📵",
    "🔞",
    "🔃",
    "🔄",
    "🛐",
    "🕉",
    "🕎",
    "🔯",
    "⛎",
    "🔀",
    "🔁",
    "🔂",
    "⏩",
    "⏭",
    "⏯",
    "⏪",
    "⏮",
    "🔼",
    "⏫",
    "🔽",
    "⏬",
    "⏸",
    "⏹",
    "⏺",
    "⏏",
    "🎦",
    "🔅",
    "🔆",
    "📶",
    "📳",
    "📴",
    "❓",
    "❔",
    "❕",
    "❗",
    "🔱",
    "📛",
    "🔰",
    "⭕",
    "✅",
    "❌",
    "❎",
    "🔟",
    "🔢",
    "🔣",
    "🔤",
    "🆒",
    "🆓",
    "🆔",
    "🆕",
    "🆖",
    "🆗",
    "🆘",
    "🆙",
    "🆚",
    "🈁",
    "🈶",
    "🈯",
    "🉐",
    "🈹",
    "🉑",
    "🈴",
    "🈳",
    "🈺",
    "🈵",
    "🔴",
    "🟠",
    "🟡",
    "🟢",
    "🔵",
    "🟣",
    "🟤",
    "⚫",
    "⚪",
    "🟥",
    "🟧",
    "🟨",
    "🟩",
    "🟦",
    "🟪",
    "🟫",
    "⬛",
    "⬜",
    "🔶",
    "🔷",
    "🔺",
    "🔻",
    "💠",
    "🔘",
    "🔳",
    "🔲",
    "🏁",
    "🚩",
    "🎌",
    "🏴",
    "🏳",
]

function unicodeNumberToCharacter(characterCode) {
    if (characterCode >= 0 && characterCode <= 0xD7FF || characterCode >= 0xE000 && characterCode <= 0xFFFF) {
        return String.fromCharCode(characterCode)
    } else if (characterCode >= 0x10000 && characterCode <= 0x10FFFF) {

        // we substract 0x10000 from characterCode to get a 20-bits number
        // in the range 0..0xFFFF
        characterCode -= 0x10000

        // we add 0xD800 to the number formed by the first 10 bits
        // to give the first byte
        const first = ((0xffc00 & characterCode) >> 10) + 0xD800

        // we add 0xDC00 to the number formed by the low 10 bits
        // to give the second byte
        const second = (0x3ff & characterCode) + 0xDC00
        return String.fromCharCode(first) + String.fromCharCode(second)
    }
}

export async function emojiHash(string, size=5) {
    let hexString = await sha256(string, 'utf-8', 'hex')
    if (size < 1) {
        console.warn(`emojiHash given size=${size}, but size=1 is the minimum`)
        size = 1
    } else if (size > hexString.length) {
        console.warn(`emojiHash given size=${size}, but size=${hexString.length} is the maximum`)
        size = hexString.length
    }
    let chunkSize = Math.floor(hexString.length / size)
    let emojis = []
    while (emojis.length < size) {
        const chunk = hexString.slice(0, chunkSize)
        hexString = hexString.slice(chunkSize)
        const emojiIndex = Number(`0x${chunk}`) % emojiCodes.length
        emojis.push(emojiCodes[emojiIndex])
    }
    return emojis.join("")
}

export const deepSortObject = (obj, seen=new Map()) => {
    if (!(obj instanceof Object)) {
        return obj
    } else if (seen.has(obj)) {
        // return the being-sorted object
        return seen.get(obj)
    } else {
        if (obj instanceof Array) {
            const sortedChildren = []
            seen.set(obj, sorted)
            for (const each of obj) {
                sortedChildren.push(deepSortObject(each, seen))
            }
            return sortedChildren
        } else {
            const sorted = {}
            seen.set(obj, sorted)
            for (const eachKey of Object.keys(obj).sort()) {
                sorted[eachKey] = deepSortObject(obj[eachKey], seen)
            }
            return sorted
        }
    }
}

export const stableStringify = (value, ...args) => {
    return JSON.stringify(deepSortObject(value), ...args)
}

export const hashJsonPrimitive = (value) => createHash("md5").update(stableStringify(value)).toString()

export function getInnerTextOfHtml(htmlText) {
    const doc = new DOMParser().parseFromString(htmlText,
        "text/html",
    )
    return doc.body.innerText
}

export const curl = async url=> new Promise(resolve => { 
    fetch(url).then(res=>res.text()).then(body=>resolve(body))
})

export async function jsonRead(path) {
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

// increases resolution over time
function* binaryListOrder(aList) {
    const length = aList.length
    if (length > 0) {
        const middle = Math.floor(length/2)
        yield aList[middle]
        if (length > 1) {
            const upperItems = binaryListOrder(aList.slice(0,middle))
            const lowerItems = binaryListOrder(aList.slice(middle+1))
            // all the sub-elements (alternate between upper and lower)
            for (const eachUpper of upperItems) {
                yield eachUpper
                const eachLower = lowerItems.next()
                if (!eachLower.done) {
                    yield eachLower.value
                }
            }
        }
    }
}

export const debounceFinish = ({cooldownTime=200}, func) => {
    const calls = []
    const cleanUpCalls = ()=>{
        let count = 0
        for (const each of calls) {
            if (each.finishTime) {
                count ++
            }
        }
        if (count>1) {
            calls.splice(0,count-2)
        }
    }

    const freshStart = ()=>{
        calls.length = 0

        const thisCall = deferred()
        // mark the finish time as soon as it happens
        thisCall.then(()=>thisCall.finishTime = (new Date()).getTime());
        thisCall.startTime = (new Date()).getTime()
        calls.push(thisCall)
        ;((async ()=>{
            thisCall.resolve(await func())
            cleanUpCalls()
        })())
        return thisCall
    }
    const onCall = ()=>{
        // if subsequent call
        if (calls.length > 0) {
            const previousCall = calls.slice(-1)[0]
            // dont start another one if the previous one hasn't even started
            if (!previousCall.startTime) {
                return previousCall
            } else {
                const now = (new Date()).getTime()
                const executeAfter = previousCall.finishTime + cooldownTime
                // nothing to wait for, execute immediately
                if (executeAfter < now) {
                    return freshStart()
                // previous thing is finished, but we can't start yet
                } else if (previousCall.finishTime) {
                    // schedule a call
                    const thisCall = deferred()
                    // mark the finish time as soon as it happens
                    thisCall.then(()=>thisCall.finishTime = (new Date()).getTime())
                    // show that a call is on deck
                    calls.push(thisCall)
                    const delayNeeded = now - executeAfter
                    ;((async ()=>{
                        await new Promise(resolve=>setTimeout(resolve, delayNeeded))
                        thisCall.startTime = (new Date()).getTime()
                        thisCall.resolve(await func())
                        cleanUpCalls()
                    })())
                    return thisCall
                // previous thing has started but not finished
                } else {
                    // schedule a call
                    const thisCall = deferred()
                    // mark the finish time as soon as it happens
                    thisCall.then(()=>thisCall.finishTime = (new Date()).getTime())
                    // show that a call is on deck
                    calls.push(thisCall)
                    // once the previous call is finished, then start the countdown to execution
                    previousCall.then(async ()=>{
                        await new Promise(resolve=>setTimeout(resolve, cooldownTime))
                        thisCall.startTime = (new Date()).getTime()
                        thisCall.resolve(await func())
                        cleanUpCalls()
                    })
                    return thisCall
                }
            }
        // if first call
        } else {
            return freshStart()
        }
    }
    onCall.calls = calls
    return onCall
}

export const maxVersionSorter = (createVersionList)=> {
    const compareLists = (listsA, listsB)=> {
        // b-a => bigger goes to element 0
        const comparisonLevels = listsB.map((each, index)=>{
            let b = each || 0
            let a = listsA[index] || 0
            const aIsArray = a instanceof Array
            const bIsArray = b instanceof Array
            if (!aIsArray && !bIsArray) {
                return b - a
            }
            a = aIsArray ? a : [ a ]
            b = bIsArray ? b : [ b ]
            // recursion for nested lists
            return compareLists(a, b)
        })
        for (const eachLevel of comparisonLevels) {
            // first difference indicates a winner
            if (eachLevel !== 0) {
                return eachLevel
            }
        }
        return 0
    }
    return (a,b)=>compareLists(createVersionList(a), createVersionList(b))
}

export async function readIdentityFile(identitiesPath) {
    const fileInfo = await FileSystem.info(identitiesPath)
    let identities
    if (!fileInfo.exists) {
        identities = {}
    } else if (fileInfo.exists) {
        let contents
        try {
            contents = await FileSystem.read(identitiesPath)
            if (!contents) {
                identities = {}
            } else {
                identities = JSON.parse(contents)
            }
        } catch (error) {
        }
        if (!(identities instanceof Object)) {
            console.error(`It appears the identities file: ${identitiesPath} is corrupted (not a JSON object)\n\nNOTE: this file might contain important information so you may want to salvage it.`)
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
    return identities
}