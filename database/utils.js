import { sha256 } from "https://denopkg.com/chiefbiiko/sha256@v1.0.0/mod.ts"
import { DOMParser, Element, } from "https://deno.land/x/deno_dom/deno-dom-wasm.ts"

function hash(string) {
    return parseInt(sha256(string, 'utf-8', 'hex'), 16) 
}

function getInnerTextOfHtml(htmlText) {
    const doc = new DOMParser().parseFromString(htmlText,
        "text/html",
    )
    return doc.body.innerText
}

const curl = async url=> new Promise(resolve => { 
    fetch(url).then(res=>res.text()).then(body=>resolve(body))
})