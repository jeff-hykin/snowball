import { createHash } from "https://deno.land/std@0.139.0/hash/mod.ts"
export const hashJsonPrimitive = (value) => createHash("md5").update(JSON.stringify(value)).toString()