// convert the scrape.js into this task
    // have it output in the correct publish format

import { getReleventCommitsFor, manuallyGetMeta } from "../support/nixpkgs.js"
import { binaryListOrder } from "../support/utils.js"
import { toCamelCase } from "https://deno.land/x/good@0.5.14/string.js"

// handle in order of estimated popularity, all relevent commits for a particular package

// given package info, create a snowboll format repository
    // example output:
        // {
        //         # commit date: 2021-03-19
        //         # probably can view at: https://github.com/NixOS/nixpkgs/blob/f5e8bdd07d1afaabf6b37afc5497b1e498b8046f/pkgs/development/interpreters/python/cpython/2.7/default.nix
        //         inputs = {
        //             nixpkgsHash   = { ...} : "f5e8bdd07d1afaabf6b37afc5497b1e498b8046f";
        //             pkgs          = { nixpkgsHash, ...} : (builtins.import (builtins.fetchTarball ({url="https://github.com/NixOS/nixpkgs/archive/f5e8bdd07d1afaabf6b37afc5497b1e498b8046f.tar.gz";}) ) ({}) );
        //             # customInput1 = { pkgs, ...} : pkgs.something;
        //             # customInput2 = { customInput1, ...} : customInput1.subPackage;
        //         };
        //         outputs = { pkgs, ... }@input:
        //             let
        //                 exampleValue1 = "blah";
        //                 exampleValue2 = "blah";
        //             in
        //                 {
        //                     # packages."x86_64-linux" = pkgs.stdenv.mkDerivation {
        //                     # 
        //                     # };
        //                     packages."x86_64-linux"   = pkgs.python27Full;
        //                     packages."aarch64-linux"  = pkgs.python27Full;
        //                     packages."i686-linux"     = pkgs.python27Full;
        //                     packages."x86_64-darwin"  = pkgs.python27Full;
        //                     packages."aarch64-darwin" = pkgs.python27Full;
        //                 }
        //         ;
        //     }

    // example input:
        // "nixpkgs.python310": {
        //     "name": "python3-3.10.2",
        //     "pname": "python3",
        //     "version": "3.10.2",
        //     "system": "x86-darwin",
        //     "meta": {
            //     "available": true,
            //     "broken": false,
            //     "description": "A high-level dynamically-typed programming language",
            //     "homepage": "http://python.org",
            //     "insecure": false,
            //     "license": {
            //         "deprecated": false,
            //         "free": true,
            //         "fullName": "Python Software Foundation License version 2",
            //         "redistributable": true,
            //         "shortName": "psfl",
            //         "spdxId": "Python-2.0",
            //         "url": "https://spdx.org/licenses/Python-2.0.html"
            //     },
            //     "longDescription": "Python is a remarkably powerful dynamic programming language that\nis used in a wide variety of application domains. Some of its key\ndistinguishing features include: clear, readable syntax; strong\nintrospection capabilities; intuitive object orientation; natural\nexpression of procedural code; full modularity, supporting\nhierarchical packages; exception-based error handling; and very\nhigh level dynamic data types.\n",
            //     "maintainers": [
            //         {
            //         "email": "fridh@fridh.nl",
            //         "github": "fridh",
            //         "githubId": 2129135,
            //         "name": "Frederik Rietdijk"
            //         }
            //     ],
            //     "name": "python3-3.10.2",
            //     "outputsToInstall": [
            //         "out"
            //     ],
            //     "platforms": [
            //         "aarch64-linux",
            //         "armv5tel-linux",
            //         "armv6l-linux",
            //         "armv7a-linux",
            //         "armv7l-linux",
            //         "i686-linux",
            //         "m68k-linux",
            //         "mipsel-linux",
            //         "powerpc64-linux",
            //         "powerpc64le-linux",
            //         "riscv32-linux",
            //         "riscv64-linux",
            //         "s390-linux",
            //         "s390x-linux",
            //         "x86-linux",
            //         "x86-darwin",
            //         "i686-darwin",
            //         "aarch64-darwin",
            //         "armv7a-darwin"
            //     ],
            //     "position": "/nix/store/wkbdshg9bqx62x1pjpmhk6kb9pfrymcw-nixpkgs-22.05pre360843.3eb07eeafb5/nixpkgs/pkgs/development/interpreters/python/cpython/default.nix:494",
            //     "unfree": false,
            //     "unsupported": false
        //     }
        // }