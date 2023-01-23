- DONE Get signature CLI tool working
- DONE initial write of create-identity function
- DONE initial write of cli-publish
- DONE figure out how a package will be used by nix: the online site is just a registry/tutorial. Installers don't need to know about it, but maybe later they can use it

- test make create-identity function
- test publish cli side
- finish publish newReleaseInfo
- test publish server side
- fix allowing the indexing system to save to disk
- switch to using a recursive IPFS hash of a folder instead of sha256

- webpage render:
    - url for nix-installer, url for virkshop installer
    - list the search results: toolName, entity emoji hash, tool adjectives
    - on tool click -> list versions, flavors, adjectives, render iframeSrc
    - on version click, show copy-paste install commands for each source

- consider the difference between searching for a nix derivation, and just a nix funciton, or a deno function    

- add overthrow cli command
- add create-entity, and maybe reword the whole identity/entity thing

- consider when two things (numpy, ffmpeg) need to share an upstream dependency (llvm), but when not given a default argument, they end up using different versions of nixpkgs, and then result in terrible errors.
    ```
    llvm11=snowball.get { url = "llvm11"; inputs={} });
    llvm9=snowball.get { url = "llvm9"; inputs={} });
    python2=snowball.get { url = "python2"; inputs={ llvm=llvm9;  } });
    python3=snowball.get { url = "python3"; inputs={ llvm=llvm11; } });
    blah=snowball.get {
        url="blah";
        inputs={
            python=python3
        }; 
    }
    ```
- finish the `extract_to_repo.js`
    - redefine the snowball format, allow static information such as whether it is outputing a function or a package
    - creates a new repo in a temp folder
    - grabs info about a package from current nixpkgs
    - uses position to get the associated file
    - list all relevent commits
    - for each relevent nixpkg commit
        - create a tool.json trying to extract version, inputs, etc
        - create a default.nix that pulls from that nixpkgs
        - add the source code to the bottom of default.nix
        - try to auto-detect inputs, put them as commented-out sections
        - make a commit in the new repo
        - try to publish it to fornix, but make a new entity each time so it can be transfered to someone later

- create a nixpkgs nightly
    - somehow try updating each of the existing federated packages with new versions
    - try detecting new packages, and slowly add them to the federation