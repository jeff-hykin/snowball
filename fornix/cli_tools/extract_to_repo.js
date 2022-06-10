#!/usr/bin/env -S deno run --allow-all
import { getPackageInfo, allCommitsFor, getReleventCommitsFor } from "../support/nixpkgs.js"
import { jsonRead } from "../support/basics.js"

const { run, Timeout, Env, Cwd, Stdin, Stdout, Stderr, Out, Overwrite, AppendTo, zipInto, mergeInto, returnAsString, } = await import(`https://deno.land/x/quickr@0.3.24/main/run.js`)
const { FileSystem } = await import(`https://deno.land/x/quickr@0.3.24/main/file_system.js`)

const name = Deno.args[0]

// 
// create a target repo
// 
const repoFolder = `${FileSystem.thisFolder}/../cache.ignore/extracted_repos/${name}`; await FileSystem.ensureIsFolder(repoFolder)
const snowballPath = `${repoFolder}/snowball/snow.nix`
await run`git clone -b template/package https://github.com/jeff-hykin/snowball ${repoFolder}`
await (FileSystem.cwd = repoFolder)
// checkout the correct branch for the package
const packageBranchName = `packages/${name}`
await run`git checkout -b ${packageBranchName}`
await run`git push --set-upstream origin ${packageBranchName}`

// 
// begin processsing commits
// 
const commits = await getReleventCommitsFor({packageName: name})
for (const [hash, dateString] of Object.entries(commits)) {
    const infos = await getPackageInfo({hash, packageName})
    // {
    //     "nixpkgs.python": {
    //         "name": "python-2.7.18",
    //         "pname": "python",
    //         "version": "2.7.18",
    //         "system": "x86_64-linux",
    //         "meta": {
    //         "available": true,
    //         "description": "A high-level dynamically-typed programming language",
    //         "homepage": "http://python.org",
    //         "license": {
    //             "fullName": "Python Software Foundation License version 2",
    //             "shortName": "psfl",
    //             "spdxId": "Python-2.0",
    //             "url": "https://spdx.org/licenses/Python-2.0.html"
    //         },
    //         "longDescription": "Python is a remarkably powerful dynamic programming language that\nis used in a wide variety of application domains. Some of its key\ndistinguishing features include: clear, readable syntax; strong\nintrospection capabilities; intuitive object orientation; natural\nexpression of procedural code; full modularity, supporting\nhierarchical packages; exception-based error handling; and very\nhigh level dynamic data types.\n",
    //         "maintainers": [
    //             {
    //             "email": "fridh@fridh.nl",
    //             "github": "fridh",
    //             "githubId": 2129135,
    //             "name": "Frederik Rietdijk"
    //             }
    //         ],
    //         "name": "python-2.7.18",
    //         "outputsToInstall": [
    //             "out"
    //         ],
    //         "platforms": [
    //             "aarch64-linux",
    //             "armv5tel-linux",
    //             "armv6l-linux",
    //             "armv7a-linux",
    //             "armv7l-linux",
    //             "mipsel-linux",
    //             "i686-cygwin",
    //             "i686-freebsd",
    //             "i686-linux",
    //             "i686-netbsd",
    //             "i686-openbsd",
    //             "x86_64-cygwin",
    //             "x86_64-freebsd",
    //             "x86_64-linux",
    //             "x86_64-netbsd",
    //             "x86_64-openbsd",
    //             "x86_64-solaris",
    //             "x86_64-darwin",
    //             "i686-darwin",
    //             "aarch64-darwin",
    //             "armv7a-darwin",
    //             "x86_64-windows",
    //             "i686-windows",
    //             "wasm64-wasi",
    //             "wasm32-wasi",
    //             "x86_64-redox",
    //             "powerpc64le-linux",
    //             "riscv32-linux",
    //             "riscv64-linux",
    //             "arm-none",
    //             "armv6l-none",
    //             "aarch64-none",
    //             "avr-none",
    //             "i686-none",
    //             "x86_64-none",
    //             "powerpc-none",
    //             "msp430-none",
    //             "riscv64-none",
    //             "riscv32-none",
    //             "vc4-none",
    //             "js-ghcjs",
    //             "aarch64-genode",
    //             "i686-genode",
    //             "x86_64-genode"
    //         ],
    //         "position": "/nix/store/x0q87hvyab6431g84iswgr92qz5wngaw-nixpkgs-20.09pre240426.f9567594d5a/nixpkgs/pkgs/development/interpreters/python/cpython/2.7/default.nix:278",
    //         "priority": -100
    //         }
    //     }
    // }            
    for (const [attributePath, info] of Object.entries(infos)) {
        if (info.version && info.meta && info.meta.path) {
            const snowballString = generateSnowballString({
                nixpkgsHash: hash,
                attributePath,
                relativePath: info.meta.path,
            })
            await FileSystem.write({ data: snowballString, path: snowballPath,})
            await run`git add -A`
            await run`git commit -m ${info.version}`
            await run`git push`
            await run`git tag ${info.version}`
            await run`git push origin ${info.version}`
        }
    }
}

function generateSnowballString({ nixpkgsHash, attributePath, relativePath }) {
    return `{
        # probably can view at: https://github.com/NixOS/nixpkgs/blob/${nixpkgsHash}/${relativePath}
        inputs = {
            nixpkgsHash   = { ...} : "${nixpkgsHash}";
            pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/${nixpkgsHash}.tar.gz";}) ) ({}) );
            # customInput1 = { pkgs, ...} : pkgs.something;
            # customInput2 = { customInput1, ...} : customInput1.subPackage;
        };
        outputs = { pkgs, ... }@input:
            let
                exampleValue1 = "blah";
                exampleValue2 = "blah";
            in
                {
                    # packages."x86_64-linux" = pkgs.stdenv.mkDerivation {
                    # 
                    # };
                    packages."x86_64-linux"   = pkgs.${attributePath};
                    packages."aarch64-linux"  = pkgs.${attributePath};
                    packages."i686-linux"     = pkgs.${attributePath};
                    packages."x86_64-darwin"  = pkgs.${attributePath};
                    packages."aarch64-darwin" = pkgs.${attributePath};
                }
        ;
    }`
}