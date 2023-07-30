const Denox = {
    init() {
        const constraints = []
        Denox.addSystemConstraints(constraints)
        return {
            constraints
        }
    },
    addSystemConstraints(constraints) {
        constraints.add(`denox:version: 1`)
        // 
        // OS Info
        // 
            // OS common name
            // OS version
            // OS exact identification (build number etc)
                // TODO: consider ubuntu, debian, etc (stacked OS tags)
            if (Deno.build.os == "darwin") {
                constraints.push(`operating_system:tag: unix`)
                constraints.push(`operating_system:tag: darwin`)
                constraints.push(`operating_system:tag: mac_os`)
            } else {
                constraints.push(`operating_system:tag: unix`)
                constraints.push(`operating_system:tag: linux`)
            }
        
        // 
        // CPU info
        // 
            constraints.push(`processor:family: ${Deno.build.arch}`,)
            // bit-ness
            // core count
                // big core
                // small core
            // ISA details
                // features
                    // sse3
                    // ssse3
                    // sse4_1
                    // sse4_2
                    // sse4_a
                    // avx
                    // avx2
                    // avx512
                    // aes
                    // fma
                    // fma4
                // x86_64 Intel
                //     westmere       = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes"                                    ]
                //     sandybridge    = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx"                              ]
                //     ivybridge      = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx"                              ]
                //     haswell        = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2"          "fma"        ]
                //     broadwell      = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2"          "fma"        ]
                //     skylake        = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2"          "fma"        ]
                //     skylake-avx512 = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ]
                //     cannonlake     = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ]
                //     icelake-client = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ]
                //     icelake-server = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ]
                //     cascadelake    = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ]
                //     cooperlake     = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ]
                //     tigerlake      = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ]
                // x86_64 AMD
                //     btver1         = [ "sse3" "ssse3" "sse4_1" "sse4_2"                                                  ]
                //     btver2         = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx"                              ]
                //     bdver1         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx"                 "fma" "fma4" ]
                //     bdver2         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx"                 "fma" "fma4" ]
                //     bdver3         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx"                 "fma" "fma4" ]
                //     bdver4         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2"          "fma" "fma4" ]
                //     znver1         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2"          "fma"        ]
                //     znver2         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2"          "fma"        ]
                //     znver3         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2"          "fma"        ]
        
        // 
        // Hardware info
        // 
            // RAM
            // swap
        
        // 
        // File System Info
        // 
            // max path length
            // max file name length
            // file system valid characters
            // file system case conflict
            // file system number of files per folder
            // max file size
            // permission structure
            
            // problem is file system family info usually needs compiled tools to detect
            // diskutil for MocOS
            // lsblk for linux
    },
}
const system = Denox.init()

export default {
    publish() {
        return {
            INPUTS: {},
            MAPPINGS: [
                {
                    IMPURE: [
                        {
                            CONSTRAINTS: [
                                "processor:family: x86_64",
                                "operating_system:tag: unix",
                                "denox:version: 1",
                            ],
                        },
                    ],
                    BUILD({ quickrFileSystem, quickrRun, quickrConsole, gcc12_linux_x86, python }) {
                        const { FileSystem } = eval(new TextDecoder().decode(quickrFileSystem))
                        const { run      } = eval(new TextDecoder().decode(quickerRun))
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
    },
}