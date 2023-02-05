let
    genericData = {
        shellFile = if localSystem.isAarch64 then ./unpack-bootstrap-tools-aarch64.sh else ./unpack-bootstrap-tools.sh;
        bootstrapTarball = (
            if localSystem.isAarch64 then
                "http://tarballs.nixos.org/stdenv-darwin/aarch64/20acd4c4f14040485f40e55c0a76c186aa8ca4f3/"
            else
                "http://tarballs.nixos.org/stdenv-darwin/x86_64/c253216595572930316f2be737dc288a1da22558/"
        );
        checkSums = {
            sh      = if localSystem.isAarch64 then "17m3xrlbl99j3vm7rzz3ghb47094dyddrbvs2a6jalczvmx7spnj" else "sha256-igMAVEfumFv/LUNTGfNi2nSehgTNIP4Sg+f3L7u6SMA=";
            bzip2   = if localSystem.isAarch64 then "1khs8s5klf76plhlvlc1ma838r8pc1qigk9f5bdycwgbn0nx240q" else "sha256-K3rhkJZipudT1Jgh+l41Y/fNsMkrPtiAsNRDha/lpZI=";
            mkdir   = if localSystem.isAarch64 then "1m9nk90paazl93v43myv2ay68c1arz39pqr7lk5ddbgb177hgg8a" else "sha256-VddFELwLDJGNADKB1fWwWPBtIAlEUgJv2hXRmC4NEeM=";
            cpio    = if localSystem.isAarch64 then "17pxq61yjjvyd738fy9f392hc9cfzkl612sdr9rxr3v0dgvm8y09" else "sha256-SWkwvLaFyV44kLKL2nx720SvcL4ej/p2V/bX3uqAGO0=";
            tarball = if localSystem.isAarch64 then "1v2332k33akm6mrm4bj749rxnnmc2pkbgcslmd0bbkf76bz2ildy" else "sha256-kRC/bhCmlD4L7KAvJQgcukk7AinkMz4IwmG1rqlh5tA=";
        };
    };
    
    
    fetch = { file, sha256, executable ? true }: import <nix/fetchurl.nix> {
        url = "${genericData.bootstrapTarball}/${file}";
        system      = localSystem.system;
        sha256      = sha256;
        executable  = executable;
    };
    
    bootstrapFiles = {
        sh      = fetch { file = "sh"   ; sha256 = genericData.checkSums.sh   ; };
        bzip2   = fetch { file = "bzip2"; sha256 = genericData.checkSums.bzip2; };
        mkdir   = fetch { file = "mkdir"; sha256 = genericData.checkSums.mkdir; };
        cpio    = fetch { file = "cpio" ; sha256 = genericData.checkSums.cpio ; };
        tarball = fetch { file = "bootstrap-tools.cpio.bz2"; sha256 = genericData.checkSums.tarball; executable = false; };
    };
    
    bootstrapTools = bootstrapTools = derivation ({
        system = builtins.localSystem;

        name = "bootstrap-tools";
        builder = bootstrapFiles.sh; # Not a filename! Attribute 'sh' on bootstrapFiles
        args = [ genericData.shellFile ];

        mkdir    = bootstrapFiles.mkdir;
        bzip2    = bootstrapFiles.bzip2;
        cpio     = bootstrapFiles.cpio;
        tarball  = bootstrapFiles.tarball;

        __impureHostDeps = commonImpureHostDeps;
    } // lib.optionalAttrs __magic__.config.contentAddressedByDefault {
        __contentAddressed = true;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
    });
{ __magic__ }:
    # __magic__.fetchurl
    # __magic__.stdenvNoCC
    
    # __magic__.stdenv.shellPackage                     # bash
    # __magic__.stdenv.__bootPackages            
    # __magic__.stdenv.__extraImpureHostDeps     
    # __magic__.stdenv.__hatPackages             
    # __magic__.stdenv.__impureHostDeps          
    # __magic__.stdenv.__sandboxProfile          
    # __magic__.stdenv.all                       
    # __magic__.stdenv.allowedRequisites         
    # __magic__.stdenv.args                      
    # __magic__.stdenv.bootstrapTools            
    # __magic__.stdenv.builder                   
    # __magic__.stdenv.buildPlatform             
    # __magic__.stdenv.cc                        
    # __magic__.stdenv.defaultBuildInputs        
    # __magic__.stdenv.defaultNativeBuildInputs  
    # __magic__.stdenv.drvAttrs                  
    # __magic__.stdenv.drvPath                   
    # __magic__.stdenv.extraBuildInputs          
    # __magic__.stdenv.extraNativeBuildInputs    
    # __magic__.stdenv.extraSandboxProfile       
    # __magic__.stdenv.fetchurlBoot              
    # __magic__.stdenv.hasCC                     
    # __magic__.stdenv.hostPlatform              
    # __magic__.stdenv.initialPath               
    # __magic__.stdenv.is32bit                   
    # __magic__.stdenv.is64bit                   
    # __magic__.stdenv.isAarch32                 
    # __magic__.stdenv.isAarch64                 
    # __magic__.stdenv.isBigEndian               
    # __magic__.stdenv.isBSD                     
    # __magic__.stdenv.isCygwin                  
    # __magic__.stdenv.isDarwin                  
    # __magic__.stdenv.isFreeBSD                 
    # __magic__.stdenv.isi686                    
    # __magic__.stdenv.isLinux                   
    # __magic__.stdenv.isMips                    
    # __magic__.stdenv.isOpenBSD                 
    # __magic__.stdenv.isSunOS                   
    # __magic__.stdenv.isx86_32                  
    # __magic__.stdenv.isx86_64                  
    # __magic__.stdenv.libc                      
    # __magic__.stdenv.meta                      
    # __magic__.stdenv.mkDerivation
    # __magic__.stdenv.name
    # __magic__.stdenv.out
    # __magic__.stdenv.outPath
    # __magic__.stdenv.outputName
    # __magic__.stdenv.override
    # __magic__.stdenv.overrideDerivation
    # __magic__.stdenv.overrides
    # __magic__.stdenv.preHook
    # __magic__.stdenv.setup
    # __magic__.stdenv.shell
    # __magic__.stdenv.shellPackage
    # __magic__.stdenv.system
    # __magic__.stdenv.targetPlatform
    # __magic__.stdenv.type
    {
        inputs = rec {
            # 
            # values
            # 
            lib = __magic__.import "url_to_lib";
            # runCommandWith = (
            #     {
            #         # which stdenv to use, defaults to a stdenv with a C compiler, pkgs.stdenv
            #         stdenv ? __magic__.stdenv
            #         # whether to build this derivation locally instead of substituting
            #         , runLocal ? false
            #         # extra arguments to pass to stdenv.mkDerivation
            #         , derivationArgs ? {}
            #         # name of the resulting derivation
            #         , name
            #         # TODO(@Artturin): enable strictDeps always
            #     }: buildCommand:
            #         stdenv.mkDerivation (
            #             {
            #                 enableParallelBuilding = true;
            #                 buildCommand  = buildCommand;
            #                 name          = name;
            #                 passAsFile = [ "buildCommand" ]
            #                     ++ (derivationArgs.passAsFile or []);
            #             } // (lib.optionalAttrs runLocal {
            #                 preferLocalBuild = true;
            #                 allowSubstitutes = false;
            #             }) // builtins.removeAttrs derivationArgs [ "passAsFile" ]
            #         )
            # );
            
            # runCommand = name: env: runCommandWith {
            #     stdenv = __magic__.stdenvNoCC;
            #     runLocal = false;
            #     name = name;
            #     derivationArgs = env;
            # };
            
            # substituteAll = (
            #     args:
            #         # see the substituteAll in the nixpkgs documentation for usage and constaints
            #         __magic__.stdenvNoCC.mkDerivation ({
            #             name = if args ? name then args.name else baseNameOf (toString args.src);
            #             builder = ./substitute-all.sh;
            #             src  = args.src;
            #             preferLocalBuild = true;
            #             allowSubstitutes = false;
            #         } // args)
            # );
            
            # fetchurl = (
            #     {
            #         lib,
            #         buildPackages ? { inherit stdenvNoCC; },
            #         stdenvNoCC,
            #         # Note that `curl' may be `null', in case of the native stdenvNoCC.
            #         curl,
            #         cacert ? null 
            #     }:
            #         let
            #             mirrors = import ./mirrors.nix;
            #             # Write the list of mirrors to a file that we can reuse between
            #             # fetchurl instantiations, instead of passing the mirrors to
            #             # fetchurl instantiations via environment variables.  This makes the
            #             # resulting store derivations (.drv files) much smaller, which in
            #             # turn makes nix-env/nix-instantiate faster.
            #             mirrorsFile =
            #                 buildPackages.stdenvNoCC.mkDerivation ({
            #                     name = "mirrors-list";
            #                     strictDeps = true;
            #                     builder = ./write-mirror-list.sh;
            #                     preferLocalBuild = true;
            #                 } // mirrors);
            #
            #             # Names of the master sites that are mirrored (i.e., "sourceforge",
            #             # "gnu", etc.).
            #             sites = builtins.attrNames mirrors;
            #
            #             impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
            #                 # This variable allows the user to pass additional options to curl
            #                 "NIX_CURL_FLAGS"
            #
            #                 # This variable allows the user to override hashedMirrors from the
            #                 # command-line.
            #                 "NIX_HASHED_MIRRORS"
            #
            #                 # This variable allows overriding the timeout for connecting to
            #                 # the hashed mirrors.
            #                 "NIX_CONNECT_TIMEOUT"
            #             ] ++ (map (site: "NIX_MIRRORS_${site}") sites);
            #
            #         in
            #
            #         { # URL to fetch.
            #             url ? ""
            #
            #         , # Alternatively, a list of URLs specifying alternative download
            #             # locations.  They are tried in order.
            #             urls ? []
            #
            #         , # Additional curl options needed for the download to succeed.
            #             # Warning: Each space (no matter the escaping) will start a new argument.
            #             # If you wish to pass arguments with spaces, use `curlOptsList`
            #             curlOpts ? ""
            #
            #         , # Additional curl options needed for the download to succeed.
            #             curlOptsList ? []
            #
            #         , # Name of the file.  If empty, use the basename of `url' (or of the
            #             # first element of `urls').
            #             name ? ""
            #
            #             # for versioned downloads optionally take pname + version.
            #         , pname ? ""
            #         , version ? ""
            #
            #         , # SRI hash.
            #             hash ? ""
            #
            #         , # Legacy ways of specifying the hash.
            #             outputHash ? ""
            #         , outputHashAlgo ? ""
            #         , md5 ? ""
            #         , sha1 ? ""
            #         , sha256 ? ""
            #         , sha512 ? ""
            #
            #         , recursiveHash ? false
            #
            #         , # Shell code to build a netrc file for BASIC auth
            #             netrcPhase ? null
            #
            #         , # Impure env vars (https://nixos.org/nix/manual/#sec-advanced-attributes)
            #             # needed for netrcPhase
            #             netrcImpureEnvVars ? []
            #
            #         , # Shell code executed after the file has been fetched
            #             # successfully. This can do things like check or transform the file.
            #             postFetch ? ""
            #
            #         , # Whether to download to a temporary path rather than $out. Useful
            #             # in conjunction with postFetch. The location of the temporary file
            #             # is communicated to postFetch via $downloadedFile.
            #             downloadToTemp ? false
            #
            #         , # If true, set executable bit on downloaded file
            #             executable ? false
            #
            #         , # If set, don't download the file, but write a list of all possible
            #             # URLs (resulting from resolving mirror:// URLs) to $out.
            #             showURLs ? false
            #
            #         , # Meta information, if any.
            #             meta ? {}
            #
            #             # Passthru information, if any.
            #         , passthru ? {}
            #             # Doing the download on a remote machine just duplicates network
            #             # traffic, so don't do that by default
            #         , preferLocalBuild ? true
            #
            #             # Additional packages needed as part of a fetch
            #         , nativeBuildInputs ? [ ]
            #         }:
            #
            #         let
            #             urls_ =
            #                 if urls != [] && url == "" then
            #                     (if lib.isList urls then urls
            #             else throw "`urls` is not a list")
            #                 else if urls == [] && url != "" then
            #                     (if lib.isString url then [url]
            #             else throw "`url` is not a string")
            #                 else throw "fetchurl requires either `url` or `urls` to be set";
            #
            #             hash_ =
            #                 # Many other combinations don't make sense, but this is the most common one:
            #                 if hash != "" && sha256 != "" then throw "multiple hashes passed to fetchurl" else
            #
            #                 if hash != "" then { outputHashAlgo = null; outputHash = hash; }
            #                 else if md5 != "" then throw "fetchurl does not support md5 anymore, please use sha256 or sha512"
            #                 else if (outputHash != "" && outputHashAlgo != "") then { inherit outputHashAlgo outputHash; }
            #                 else if sha512 != "" then { outputHashAlgo = "sha512"; outputHash = sha512; }
            #                 else if sha256 != "" then { outputHashAlgo = "sha256"; outputHash = sha256; }
            #                 else if sha1   != "" then { outputHashAlgo = "sha1";   outputHash = sha1; }
            #                 else if cacert != null then { outputHashAlgo = "sha256"; outputHash = ""; }
            #                 else throw "fetchurl requires a hash for fixed-output derivation: ${lib.concatStringsSep ", " urls_}";
            #         in
            #
            #         stdenvNoCC.mkDerivation ((
            #             if (pname != "" && version != "") then
            #                 { inherit pname version; }
            #             else
            #                 { name =
            #                     if showURLs then "urls"
            #                     else if name != "" then name
            #                     else baseNameOf (toString (builtins.head urls_));
            #                 }
            #         ) // {
            #             builder = ./builder.sh;
            #
            #             nativeBuildInputs = [ curl ] ++ nativeBuildInputs;
            #
            #             urls = urls_;
            #
            #             # If set, prefer the content-addressable mirrors
            #             # (http://tarballs.nixos.org) over the original URLs.
            #             preferHashedMirrors = true;
            #
            #             # New-style output content requirements.
            #             inherit (hash_) outputHashAlgo outputHash;
            #
            #             SSL_CERT_FILE = if (hash_.outputHash == "" || hash_.outputHash == lib.fakeSha256 || hash_.outputHash == lib.fakeSha512 || hash_.outputHash == lib.fakeHash)
            #                                             then "${cacert}/etc/ssl/certs/ca-bundle.crt"
            #                                             else "/no-cert-file.crt";
            #
            #             outputHashMode = if (recursiveHash || executable) then "recursive" else "flat";
            #
            #             curlOpts = lib.warnIf (lib.isList curlOpts) ''
            #                 fetchurl for ${toString (builtins.head urls_)}: curlOpts is a list (${lib.generators.toPretty { multiline = false; } curlOpts}), which is not supported anymore.
            #                 - If you wish to get the same effect as before, for elements with spaces (even if escaped) to expand to multiple curl arguments, use a string argument instead:
            #                     curlOpts = ${lib.strings.escapeNixString (toString curlOpts)};
            #                 - If you wish for each list element to be passed as a separate curl argument, allowing arguments to contain spaces, use curlOptsList instead:
            #                     curlOptsList = [ ${lib.concatMapStringsSep " " lib.strings.escapeNixString curlOpts} ];'' curlOpts;
            #             curlOptsList = lib.escapeShellArgs curlOptsList;
            #             inherit showURLs mirrorsFile postFetch downloadToTemp executable;
            #
            #             impureEnvVars = impureEnvVars ++ netrcImpureEnvVars;
            #
            #             nixpkgsVersion = lib.trivial.release;
            #
            #             inherit preferLocalBuild;
            #
            #             postHook = if netrcPhase == null then null else ''
            #                 ${netrcPhase}
            #                 curlOpts="$curlOpts --netrc-file $PWD/netrc"
            #             '';
            #
            #             inherit meta;
            #             passthru = { inherit url; } // passthru;
            #         })
            # );
            
            # 
            # packages
            # 
            bash = {
                inputs = {
                    
                };
            };
            testers = {
                inputs = {
                    stdenv        = __magic__.stdenv;
                    lib           = lib;
                    runCommand    = runCommand;
                    substituteAll = substituteAll;
                    pkgs          = {}; # its only used for python, so we can leave it empty here
                    buildPackages = {
                        bash      = MISSING;
                        coreutils = MISSING;
                    };
                    # it doesn't really use the full callPackage so we can overwrite it with a fake one here
                    callPackage   = path: (import path) { 
                        lib = lib;
                        runCommand = runCommand;
                        nix-diff = null; # it requires
                        emptyFile = (
                            runCommand "empty-file" {
                                outputHashAlgo = "sha256";
                                outputHashMode = "recursive";
                                outputHash = "0ip26j2h11n1kgkz36rl4akv694yz65hr72q4kv4b3lxcbi65b3p";
                                preferLocalBuild = true;
                            } "touch $out"
                        );
                    };
                };
            };
            cowsay = {
                inputs = {
                    lib                = lib;
                    fetchFromGitHub    = __magic__.import "url to fetchFromGitHub";
                    fetchpatch         = __magic__.import "url to fetchpatch";
                    nix-update-script  = __magic__.import "url to nix-update-script";
                    testers            = testers;
                    perl               = MISSING;
                };
            };
        };
    }





stdenv.mkDerivation rec {
  pname = "cowsay";
  version = "3.7.0";

  outputs = [ "out" "man" ];

  src = fetchFromGitHub {
    owner = "cowsay-org";
    repo = "cowsay";
    rev = "v${version}";
    hash = "sha256-t1grmCPQhRgwS64RjEwkK61F2qxxMBKuv0/DzBTnL3s=";
  };

  patches = [
    # Install cowthink as a symlink, not a copy
    # See https://github.com/cowsay-org/cowsay/pull/18
    (fetchpatch {
      url = "https://github.com/cowsay-org/cowsay/commit/9e129fa0933cf1837672c97f5ae5ad4a1a10ec11.patch";
      hash = "sha256-zAYEUAM5MkyMONAl5BXj8hBHRalQVAOdpxgiM+Ewmlw=";
    })
  ];

  buildInputs = [ perl ];

  makeFlags = [
    "prefix=${placeholder "out"}"
  ];

  passthru = {
    updateScript = nix-update-script { };
    tests.version = testers.testVersion {
      package = __magic__.self;
      command = "cowsay --version";
    };
  };

  meta = with lib; {
    description = "A program which generates ASCII pictures of a cow with a message";
    homepage = "https://cowsay.diamonds";
    changelog = "https://github.com/cowsay-org/cowsay/releases/tag/v${version}";
    license = licenses.gpl3Only;
    platforms = platforms.all;
    maintainers = with maintainers; [ rob anthonyroussel ];
  };
}
