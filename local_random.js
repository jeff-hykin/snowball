const file = await Deno.open("/dev/urandom")
const buffer = new Uint8Array(256)
while (1) {
    file.readSync(buffer)
    const myFile = Deno.openSync("./random.ignore", { write: true, truncate:true })
    await myFile.write(new TextEncoder().encode(buffer))
    myFile.close()
}