- create full recursive cowsay snowball
    - DONE: bundle lib into one nix file
    - `generate_postfix.js` search for every default.nix and every callPackage ./path
    - create an args.nix for each of them
    - find the corrisponding attribute being assigned to  import or callPackage ./path, and create another assignment below it with `[attr_name]_Args =` and then callPackage on the args path
    - make package-args.nix
        - copy `all-package.nix`, find all `[name] = callPackage [pathLiteral] [...stuff];` and check which ones are a function that returns a derivation
        - parse the `[pathLiteral]`, get all the arguments, create `[pathLiteral].arguments.nix` with the same parameters, but add a `@arguments` if its missing and then return `arguments`
        - replace the `[name] = callPackage [pathLiteral]  [...stuff];` with `[name] = callPackage [pathLiteral].arguments.nix [...stuff];`
        - generate an import statement for each of the arguments
    - create a `snowball.nix` inside every package folder
        - a function with an input for `__magic__`
        - have a `input.default` that uses builtins to import arg-default values from the local args function
        - have an `output` function that accepts `__magic__` and all the normal arguments, and have the body of the function be the same as the normal function body
        - guess constraints (system described below)
    - for each of the default values in each package, try to replace by importing dependencies with snowball-dependencies with every argument specified, and add every snowball-dependency argument value to the list of arguments on the main package
    - make a list of packages that take problematic things (pkgs, callPackage, etc) as inputs, have those as splicing-off points



- DONE Get signature CLI tool working
- DONE initial write of create-identity function
- DONE initial write of cli-publish
- DONE figure out how a package will be used by nix: the online site is just a registry/tutorial. Installers don't need to know about it, but maybe later they can use it


- snowballifying nixpkgs:
    - every package needs:
        - inputs
        - constraints on any package-inputs
        - a list of inputs that caused all tests to pass
        - a system value that is fed-down to anything that needs system
    - package discovery:
        - recursively explore attributes (keep track of seen objects) and detect when something is a derivation (.type == "derivation")
            - BFS exploration
            - read in bad attribute paths from ENV var
            - print the attribute path before exploring it
            - external program keeps track of error states, adds "bad" paths to list
    - package conversion:
        - in the worse case: create a nix function that returns an attribute set (which will be a derivation)
            - do a hardcoded check on the existing derivation object for anything system related (__impureHostDeps, __darwinAllowLocalNetworking, __propagatedImpureHostDeps, stdenv, system, etc)
            - add `__magic__.system` to the nix function input, and set the attribute of any purely system-related attributes
            - for the remaining attributes, recursively explore them 2 levels deep.
              This will touch anything in buildInputs, nativeBuildInputs, and the like.
              For each:
                - if the value is a derivation, then auto-generate a unique name for it, add it to the nix-function inputs
                - if the value is a function, its going to have to be imported from the pinned nixpkgs url (this is a possible source of hidden dependencies, but there's not much that can be done about it since nix-tracing tools are too limited, and nix can't be statically anaylzed)
                - if the value is primitive, add it as an input with a default value
                - if the value is itself, then create a special `__magic__.self` argument
                - if the value is a container (list or attr-set) that does not contain a function (recursively), treat it like a primitive
                - if the value is a container (list or attr-set) that contains a funciton, then import the value from the nixpkgs url
            - once all those inputs have been gathered, the input constraints can be created
                - if the value is a package, then its given a flavor constraint, tries to generate version constraints, and tries to generate system constraints
                - if the value is literal, then its given a nullable nix-type constraint (bool/string/attr-set) 
                - if the value isn't either of those, then it still gets the nix-value constraint
            - all the inputs are then put into the `testedInputs` list
        - if there's a meta.position, and doing `callPackage` on that path results in the same derivation
            - then copy the source code
            - find any relative paths, and replace them with paths to `/nix/store`
            - extract all the input names
                - check the inputs against a hardcoded list of impure values, and common values like `lib`. Handle the input-constraints and test values for those manually
                - otherwise, create many copies of the function in the source file, keep the same arguments as but have each copy return a different one of the arguments. Use callPackage on each of them to get the value of each argument
                - given the argument values
                    - generate the constraints:
                        - if the value is a package, then give it a flavor constraint, try to generate version constraints, and try to generate system constraints
                        - if the value is itself, skip it
                        - otherwise it gets a nix-type constraint (bool/string/attr-set)
                    - generate the testedInputs:
                        - self values are ignored
                        - if the value doesn't contain a function then place the literal value in the spot
                        - if the value does contain a funciton, then use an expression that imports from nixpkgs to get it
        
        - FIXME: try to not use default-arguments for imported packages (auto-write every single input)
                 check if there is a snowball version of the input, and if there is, then use that to find what the inputs are 
                 then fill those inputs using the shared-dependency algorithm, adding each one as an input argument
                 #TODO: think about how overriding will work under this scenario (if one thing needs to be isolated, but isn't)
        
            
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