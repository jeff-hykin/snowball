export let commonInterface = {}

if (globalThis.Deno) {
    const { FileSystem } = await import(`https://deno.land/x/quickr@0.5.0/main/file_system.js`)
    const { Console } = await import(`https://deno.land/x/quickr@0.5.0/main/console.js`)
    const { run, throwIfFails, zipInto, mergeInto, returnAsString, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo } = await import("https://deno.land/x/quickr@0.5.0/main/run.js")
    class UserPickedCancel extends Error {}
    
    commonInterface = {
        FileSystem,
        Console,
        Custom: {
            async userAborted() {
                throw UserPickedCancel()
            },
            async getDefaultIdentityName() {
                try {
                    return (await run`whoami ${Stdout(returnAsString)}`).replace(/\n/,"").trim() 
                } catch (error) {}
                return ""
            }
        } 
    }
}