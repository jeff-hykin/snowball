import { Denox } from "denox"

// forgot about the whole imports-of-imports problem, and circular python/numpy kind of dependency
    // could model numpy as a constraint on python
    // could allow numpy to mutate python (or any package)

// installer:
    // downloads deno
    // installs denox
    // (thats it)

const autoInputs = Denox.readAutomatedInputs("package.json")
Denox.generateBuildLock({
    packageInfo: {
        ...autoInputs.packageInfo,
        name: "blah blah",
        blurb: "blahblah",
        version: [ 1,2,3, "a" ],
    },
    inputs: {
        ...autoInputs.inputs,
        gcc12_linux_x86: await Denox.getFromUrl({url:"https://something.something"}), // auto adds ipfs address
        quickrFileSystem: await Denox.denoImport("https://deno.land/x/quickr@0.6.20/main/file_system.js"),
        quickrRun: await Denox.denoImport("https://deno.land/x/quickr@0.6.20/main/run.js",),
        gnuMake: await Denox.package({
            inputs: {},
            contraints: [ 'blah blah blah blah' ],
            urlSources: [
                "https://somewhere"
            ],
            use: {
                executables: [ "make" ],
            },
        }),
        pythonLinuxX86: await Denox.package({
            inputs: {
                gcc: Denox.fromInputs("gcc12_linux_x86"),
                make: Denox.fromInputs("gnuMake"),
            },
            contraints: [
                "version: 3",
                "version: >3.8",
            ],
            urlSources: [
                "https://somewhere"
            ],
            use: {
                paths: {
                    "lib/python.h": "src/lib/python3.h",
                },
                executables: {
                    "python": "python3",
                    "pip": "pip3",
                },
                envVars: {
                    "PYTHONPATH": "PYTHONPATH",
                },
            },
        }),
        numpy: await Denox.package({
            inputs: {
                python: Denox.fromInputs("python"),
            },
            contraints: [
                "version: 1.24",
            ],
            urlSources: [
                "https://somewhere"
            ],
            use: {
                packageMutationOf: {
                    "python": true,
                }
            },
        }),
    },
    targets: [
        ...autoInputs.targets,
        // gives warning for non standard constraints
        {
            impure: {
                system: {
                    constraints: [ "kernel: linux", "cpu_arch: x86_64" ],
                    executables: {
                        "gcc": [ "posix" ],
                        "g++": [ "posix" ],
                        "sh": [ "posix" ],
                        "tr": [ "posix" ],
                        "touch": [ "posix" ],
                        "sed": [ "posix" ],
                        "rm": [ "posix" ],
                        "mv": [ "posix" ],
                        "make": [ "posix" ],
                        "ln": [ "posix" ],
                        "ld": [ "posix" ],
                        "grep": [ "posix" ],
                        "dirname": [ "posix" ],
                        "cp": [ "posix" ],
                        "cmp": [ "posix" ],
                        "chmod": [ "posix" ],
                        "cat": [ "posix" ],
                        "as": [ "posix" ],
                        "ar": [ "posix" ],
                    },
                },
            },
            buildFunctionPath: "./builds/linux.js",
            exports: {
                bytes: {}, // returned by build function
                executables: {},
                
            }
        }
    ],
})


// build does a few thing
    // downloads btyes
    // hashes them
    // creates a system object with os/kernel/cpu
    // symlinks impure 

// ^ that generates this lock file
export default {
    INPUTS: {
        "gcc12_linux_x86": {
            PURE: {
                HASH: {
                    sha256: "",
                },
                URL_SOURCES: [
                    "https://something.something",
                    "ipfs:kadflasdjfladjflkajd",
                ],
                MAGNET_LINKS: [
                    ""
                ],
            },
        },
        "quickrFileSystem": {
            PURE: {
                HASH: {
                    sha256: "",
                },
                URL_SOURCES: [
                    "https://deno.land/x/quickr@0.6.20/main/file_system.js",
                    "ipfs:kadflasdjfladjflkajd",
                ],
                MAGNET_LINKS: [
                    ""
                ],
            },
        },
        "quickrRun": {
            PURE: {
                HASH: {
                    sha256: "",
                },
                URL_SOURCES: [
                    "https://deno.land/x/quickr@0.6.20/main/run.js",
                    "ipfs:kadflasdjfladjflkajd",
                ],
                MAGNET_LINKS: [
                    ""
                ],
            },
        },
        "quickrConsole": {
            PURE: {
                HASH: {
                    sha256: "",
                },
                URL_SOURCES: [
                    "https://deno.land/x/quickr@0.6.20/main/console.js",
                    "ipfs:kadflasdjfladjflkajd",
                ],
                MAGNET_LINKS: [
                    ""
                ],
            },
        },
        "python": {
            BUILDABLE: {
                CONSTRAINTS: [
                    "version: 3",
                    "version: >3.8",
                ],
                OUTPUTS: {
                    PATHS: {
                        "lib/python.h": "src/lib/python3.h",
                    },
                    URL_SOURCES: {
                        
                    },
                    EXECUTABLES: {
                        "python": "python3",
                        "pip": "pip3",
                    },
                    ENV_VARS: {
                        "PYTHONPATH": "DEFAULT_PYTHONPATH",
                    },
                },
            }
        },
    },
    MAPPINGS: [
        {
            IMPURE_CONSTRAINTS: [
                {
                    SYSTEM: [
                        "processor: x86_64",
                        "fileSystem: btfs"
                    ],
                    DENOX: [
                        "version: 1",
                    ],
                },
                {
                    SYSTEM: [
                        "processor: x86_64",
                        "fileSystem: hfs"
                    ],
                    DENOX: [
                        "version: 1",
                    ],
                },
            ],
            BUILD({ quickrFileSystem, quickrRun, quickrConsole, gcc12_linux_x86, python }) {
                const { FileSystem } = eval(new TextDecoder().decode(quickrFileSystem))
                const { run } = eval(new TextDecoder().decode(quickerRun))
                const { Console } = eval(new TextDecoder().decode(quickrConsole))
                
                // add gcc binary
                await Deno.writeFile("bin/gcc", gcc12_linux_x86)
                await FileSystem.setPermissions({ owner: { canExecute: true, }, group: { canExecute: true, }, other: { canExecute: true } })
                Console.env.PATH = `${FileSystem.pwd}/bin/gcc:${Console.env.PATH}`
                
                // do something with it
                await run`make install`

                // modify python by adding a module, so python is re-exported
            },
            EXPORTS: {
                PATHS: {},
                EXECUTABLES: {},
                ENV_VARS: {},
                PACKAGES: {},
            }
        },
    ],
}