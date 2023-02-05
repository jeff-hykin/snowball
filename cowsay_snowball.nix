# impure_helpers source:
    # let
    #     lib = builtins.import "url for standalone lib"
    # in
    #     { __magic__ }: {
    #         runCommandWith = (
    #             {
    #                 # which stdenv to use, defaults to a stdenv with a C compiler, pkgs.stdenv
    #                 stdenv ? __magic__.stdenv
    #                 # whether to build this derivation locally instead of substituting
    #                 , runLocal ? false
    #                 # extra arguments to pass to stdenv.mkDerivation
    #                 , derivationArgs ? {}
    #                 # name of the resulting derivation
    #                 , name
    #                 # TODO(@Artturin): enable strictDeps always
    #             }: buildCommand:
    #                 stdenv.mkDerivation (
    #                     {
    #                         enableParallelBuilding = true;
    #                         buildCommand  = buildCommand;
    #                         name          = name;
    #                         passAsFile = [ "buildCommand" ]
    #                             ++ (derivationArgs.passAsFile or []);
    #                     } // (lib.optionalAttrs runLocal {
    #                         preferLocalBuild = true;
    #                         allowSubstitutes = false;
    #                     }) // builtins.removeAttrs derivationArgs [ "passAsFile" ]
    #                 )
    #         );
    #     
    #         runCommand = name: env: runCommandWith {
    #             stdenv = __magic__.stdenvNoCC;
    #             runLocal = false;
    #             name = name;
    #             derivationArgs = env;
    #         };
    #        
    #         substituteAll = (
    #             args:
    #                 # see the substituteAll in the nixpkgs documentation for usage and constaints
    #                 __magic__.stdenvNoCC.mkDerivation ({
    #                     name = if args ? name then args.name else baseNameOf (toString args.src);
    #                     builder = ./substitute-all.sh;
    #                     src  = args.src;
    #                     preferLocalBuild = true;
    #                     allowSubstitutes = false;
    #                 } // args)
    #         );
    #         emptyFile = (
    #             impureHelpers.runCommand "empty-file" {
    #                 outputHashAlgo = "sha256";
    #                 outputHashMode = "recursive";
    #                 outputHash = "0ip26j2h11n1kgkz36rl4akv694yz65hr72q4kv4b3lxcbi65b3p";
    #                 preferLocalBuild = true;
    #             } "touch $out"
    #         );
    #         writeTextFile =
    #             { name # the name of the derivation
    #             , text
    #             , executable ? false # run chmod +x ?
    #             , destination ? ""   # relative path appended to $out eg "/bin/foo"
    #             , checkPhase ? ""    # syntax checks, e.g. for scripts
    #             , meta ? { }
    #             }:
    #             runCommand name
    #                 { inherit text executable checkPhase meta;
    #                     passAsFile = [ "text" ];
    #                     # Pointless to do this on a remote machine.
    #                     preferLocalBuild = true;
    #                     allowSubstitutes = false;
    #                 }
    #                 ''
    #                     target=$out${lib.escapeShellArg destination}
    #                     mkdir -p "$(dirname "$target")"
    #     
    #                     if [ -e "$textPath" ]; then
    #                         mv "$textPath" "$target"
    #                     else
    #                         echo -n "$text" > "$target"
    #                     fi
    #     
    #                     eval "$checkPhase"
    #     
    #                     (test -n "$executable" && chmod +x "$target") || true
    #                 '';
    #         writeText = name: text: writeTextFile {inherit name text;};
    #     }

# curl replacement source:
    # zlib_Bootstrap1 = { __magic__ }: 
    #     __magic__.buildPackages.zlib.override {
    #         fetchurl = __magic__.stdenv.fetchurlBoot; 
    #     }
    # ;
    # packageConf_Bootstrap1 = { __magic__ }: 
    #     __magic__.buildPackages.pkg-config.override (old: {
    #         pkg-config = old.pkg-config.override {
    #             fetchurl = __magic__.stdenv.fetchurlBoot;
    #         };
    #     })
    # ;
    # perl_Bootstrap1 = { __magic__ }: 
    #     __magic__.buildPackages.perl.override {
    #         fetchurl = __magic__.stdenv.fetchurlBoot;
    #     }
    # ;
    # xz_Bootstrap1 = { __magic__ }: 
    #     __magic__.buildPackages.xz.override {
    #         fetchurl = __magic__.stdenv.fetchurlBoot; 
    #     }
    # ;
    # coreutils_Bootstrap1 = { __magic__, perl_Bootstrap1, xz_Bootstrap1 }: 
    #     buildPackages.coreutils.override {
    #         fetchurl = __magic__.stdenv.fetchurlBoot;
    #         perl = perl_Bootstrap1;
    #         xz = xz_Bootstrap1;
    #         gmp = null;
    #         aclSupport = false;
    #         attrSupport = false;
    #     }
    # ;
    # openssl_Bootstrap1 = { __magic__, perl_Bootstrap1, coreutils_Bootstrap1 }: 
    #     buildPackages.openssl.override {
    #         fetchurl = __magic__.stdenv.fetchurlBoot;
    #         perl = perl_Bootstrap1;
    #         buildPackages = {
    #             perl = perl_Bootstrap1;
    #             coreutils = coreutils_Bootstrap1;
    #         };
    #     }
    # ;
    # libssh2_Bootstrap1 = { __magic__, zlib_Bootstrap1, openssl_Bootstrap1 }: 
    #     __magic__.buildPackages.libssh2.override {
    #         fetchurl = __magic__.stdenv.fetchurlBoot;
    #         zlib     = zlib_Bootstrap1;
    #         openssl  = openssl_Bootstrap1;
    #     }
    # ;
    # keyutils_Bootstrap1 = { __magic__ }: 
    #     __magic__.buildPackages.keyutils.override {
    #         fetchurl = __magic__.stdenv.fetchurlBoot; 
    #     }
    # ;
    # libkrb5_Bootstrap1 = { __magic__, packageConf_Bootstrap1, perl_Bootstrap1, openssl_Bootstrap1, keyutils_Bootstrap1 }: 
    #     __magic__.buildPackages.libkrb5.override {
    #         fetchurl    = __magic__.stdenv.fetchurlBoot;
    #         pkg-config  = packageConf_Bootstrap1;
    #         perl        = perl_Bootstrap1;
    #         openssl     = openssl_Bootstrap1;
    #         keyutils    = keyutils_Bootstrap1;
    #     }
    # ;
    # nghttp2_Bootstrap1 = { __magic__, packageConf_Bootstrap1 }: 
    #     __magic__.buildPackages.nghttp2.override {
    #         fetchurl = __magic__.stdenv.fetchurlBoot;
    #         pkg-config = packageConf_Bootstrap1;
    #         enableApp = false; # curl just needs libnghttp2
    #         enableTests = false; # avoids bringing `cunit` and `tzdata` into scope
    #     }
    # ;
    # curl = { __magic__, packageConf_Bootstrap1, zlib_Bootstrap1, packageConf_Bootstrap1, perl_Bootstrap1, openssl_Bootstrap1, libssh2_Bootstrap1, libkrb5_Bootstrap1, nghttp2_Bootstrap1 }: 
    #     __magic__.buildPackages.curlMinimal.override (old: {
    #         # break dependency cycles
    #         fetchurl   = __magic__.stdenv.fetchurlBoot;
    #         zlib       = zlib_Bootstrap1;
    #         pkg-config = packageConf_Bootstrap1;
    #         perl       = perl_Bootstrap1;
    #         openssl    = openssl_Bootstrap1;
    #         libssh2    = libssh2_Bootstrap1;
    #         # On darwin, libkrb5 needs bootstrap_cmds which would require
    #         # converting many packages to fetchurl_boot to avoid evaluation cycles.
    #         # So turn gssSupport off there, and on Windows.
    #         # On other platforms, keep the previous value.
    #         gssSupport =
    #             if __magic__.stdenv.isDarwin || __magic__.stdenv.hostPlatform.isWindows
    #                 then false
    #                 else old.gssSupport or true; # `? true` is the default
    #         libkrb5 = libkrb5_Bootstrap1;
    #         nghttp2 = nghttp2_Bootstrap1;
    #     });

# FIXME: everything from __magic__ should be limited to a minimal amount of impure values
    # fetchurl is a problem child, needs to be handled manually
    # perl is a problem child, needs to be handled manually
    # e.g. fetchFromGitHub, etc shouldn't be inside __magic__
    # buildPackages can be allowed though (thats kinda the foundation)

{ __magic__ }:
    # __magic__.config
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
            lib           = __magic__.import "url_to_lib";
            impureHelpers = __magic__.import "url to impure helpers" {
                __magic__ = __magic__;
            };
            
            # 
            # packages
            # 
            # cacertBootstrap1 = {
            #     inputs = {
            #         blacklist               = [];
            #         extraCertificateFiles   = [];
            #         extraCertificateStrings = [];
            #         # Used by update.sh
            #         nssOverride             = null;
            #         # Used for tests only
            #         runCommand              = null;
            #         cacert                  = null;
            #         openssl                 = null;
            #         lib                     = __magic__.import "url_to_lib";
            #         stdenv                  = __magic__.stdenv;
            #         fetchurl                = __magic__.stdenv.fetchurlBoot;
            #         writeText               = impureHelpers.writeText;
            #         buildcatrust            = MISSING; # ... this ... is a python package
            #     };
            # };
            zlib_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__; 
                };
            };
            keyutils_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__; 
                };
            };
            packageConf_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__; 
                };
            };
            perl_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__; 
                };
            };
            xz_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__; 
                };
            };
            coreutils_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__;
                    perl_Bootstrap1 = perl_Bootstrap1;
                    xz_Bootstrap1 = xz_Bootstrap1;
                };
            };
            openssl_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__;
                    perl_Bootstrap1 = perl_Bootstrap1;
                    coreutils_Bootstrap1 = coreutils_Bootstrap1; 
                };
            };
            libssh2_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__;
                    zlib_Bootstrap1 = zlib_Bootstrap1;
                    openssl_Bootstrap1 = openssl_Bootstrap1; 
                };
            };
            libkrb5_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__;
                    packageConf_Bootstrap1 = packageConf_Bootstrap1;
                    perl_Bootstrap1 = perl_Bootstrap1;
                    openssl_Bootstrap1 = openssl_Bootstrap1;
                    keyutils_Bootstrap1 = keyutils_Bootstrap1;
                };
            };
            nghttp2_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__;
                    packageConf_Bootstrap1 = packageConf_Bootstrap1; 
                };
            };
            curl_Bootstrap1 = __magic__.package {
                inputs = {
                    __magic__ = __magic__;
                    packageConf_Bootstrap1 = packageConf_Bootstrap1;
                    zlib_Bootstrap1        = zlib_Bootstrap1;
                    packageConf_Bootstrap1 = packageConf_Bootstrap1;
                    perl_Bootstrap1        = perl_Bootstrap1;
                    openssl_Bootstrap1     = openssl_Bootstrap1;
                    libssh2_Bootstrap1     = libssh2_Bootstrap1;
                    libkrb5_Bootstrap1     = libkrb5_Bootstrap1;
                    nghttp2_Bootstrap1     = nghttp2_Bootstrap1; 
                };
            };
            fetchurl = __magic__.package { # NOTE: this is a custom fetchurl, not auto-generated because the all-packages.nix version is problematic
                inputs = {
                    lib           = __magic__.import "url_to_lib";
                    stdenvNoCC    = __magic__.stdenvNoCC;
                    stdenv        = __magic__.stdenv;
                    buildPackages = __magic__.buildPackages; 
                    cacert        = __magic__.buildPackages.cacert; # TODO: this should maybe have the full cacert, but that would require all of python
                    curl          = curl_Bootstrap1;
                    # curl arg is now retreived from buildPackages
                };
            };
            perl_Bootstrap2 = __magic__.package { # NOTE: this is a custom perl, not auto-generated
                inputs = {
                    enableCrypt     = false;
                    enableThreading = true;
                    lib             = __magic__.import "url_to_lib"; 
                    fetchurl        = __magic__.stdenv.fetchurlBoot;
                    config          = __magic__.config; 
                    buildPackages   = __magic__.buildPackages;
                    pkgs            = { # PROBLEMATIC; needs a self-reference apparently
                        perl534   = perl_Bootstrap2.perl534;
                        perl536   = perl_Bootstrap2.perl536;
                        perldevel = perl_Bootstrap2.perldevel;
                    };
                    stdenv          = __magic__.stdenv;
                    callPackage     = MISSING; # PROBLEMATIC
                    fetchFromGitHub = MISSING; 
                    coreutils       = MISSING; 
                    makeWrapper     = MISSING; 
                    zlib            = MISSING; 
                };
            };
            libxcrypt = __magic__.package {
                inputs = {
                    lib        = __magic__.import "url_to_lib";
                    stdenv     = __magic__.stdenv.fetchurlBoot; # special
                    fetchurl   = fetchurl;
                    perl       = perl_Bootstrap2;
                    nixosTests = null;
                };
            };
            
            # 
            # 
            # 
            fetchgit = __magic__.package {
                inputs = {
                    lib         = __magic__.import "url_to_lib";
                    stdenvNoCC  = __magic__.stdenvNoCC; 
                    git         = __magic__.buildPackages.gitMinimal;
                    cacert      = __magic__.buildPackages.cacert;
                    git-lfs     = __magic__.buildPackages.git-lfs;
                };
            };
            bzip2 = {
                inputs = { 
                    lib              = __magic__.import "url_to_lib";
                    stdenv           = __magic__.stdenv;
                    fetchurl         = fetchurl;
                    linkStatic       = __magic__.stdenv.hostPlatform.isStatic || __magic__.stdenv.hostPlatform.isCygwin;
                    autoreconfHook   = MISSING;
                };
            };
            unzip = {
                inputs = { 
                    lib              = __magic__.import "url_to_lib";
                    stdenv           = __magic__.stdenv;
                    fetchurl         = fetchurl;
                    autoreconfHook = MISSING;
                    popt           = MISSING;
                    libiconv       = MISSING;
                };
            };
            unzip = {
                inputs = { 
                    lib              = __magic__.import "url_to_lib";
                    stdenv           = __magic__.stdenv;
                    fetchurl         = fetchurl;
                    bzip2            = bzip2;
                    enableNLS        = false;
                    libnatspec       = MISSING;
                };
            };
            fetchzip = __magic__.package {
                inputs = {
                    lib              = __magic__.import "url_to_lib";
                    fetchurl         = fetchurl;
                    unzip            = MISSING;
                    glibcLocalesUtf8 = MISSING;
                };
            };
            fetchFromGitHub = __magic__.package {
                inputs = {
                    lib      = __magic__.import "url_to_lib";
                    fetchgit = fetchgit;
                    fetchzip = fetchzip;
                };
            };
            gnum4 = __magic__.package {
                inputs = {
                    lib      = __magic__.import "url_to_lib";
                    stdenv   = __magic__.stdenv;
                    fetchurl = fetchurl;
                };
            };
            # FIXME: perl isn't a flat package yet (maybe will be in a few months though)
            perl = __magic__.package {
                inputs = {
                    enableThreading = true;
                    enableCrypt     = true;
                    config          = __magic__.config; 
                    buildPackages   = __magic__.buildPackages;
                    lib             = __magic__.import "url_to_lib"; 
                    stdenv          = __magic__.stdenv; 
                    libxcrypt       = libxcrypt;
                    fetchurl        = fetchurl; 
                    pkgs            = MISSING; # PROBLEMATIC; it only really needs a self-reference, so hopefully this will be factored out soon
                    callPackage     = MISSING; # PROBLEMATIC
                    fetchFromGitHub = fetchFromGitHub; 
                    coreutils       = MISSING; 
                    makeWrapper     = MISSING; 
                    zlib            = MISSING; 
                };
            };
            bison = __magic__.package {
                inputs = {
                    lib      = __magic__.import "url_to_lib";
                    stdenv   = __magic__.stdenv;
                    fetchurl = fetchurl;
                    m4       = gnum4;
                    perl     = MISSING;
                    help2man = MISSING;
                };
            };
            bash = __magic__.package {
                inputs = {
                    withDocs      = false; 
                    forFHSEnv     = false;
                    binutils      = __magic__.stdenv.cc.bintools; 
                    interactive   = __magic__.stdenv.isCygwin; # patch for cygwin requires readline support
                    lib           = __magic__.import "url_to_lib";
                    stdenv        = __magic__.stdenv; 
                    buildPackages = __magic__.buildPackages; 
                    fetchurl      = fetchurl; 
                    bison         = bison; 
                    util-linux    = MISSING; 
                    readline      = MISSING; 
                    texinfo       = MISSING; 
                };
            };
            testers = __magic__.package {
                inputs = {
                    stdenv        = __magic__.stdenv;
                    lib           = lib;
                    runCommand    = impureHelpers.runCommand;
                    substituteAll = impureHelpers.substituteAll;
                    pkgs          = {}; # its only used for python, so we can leave it empty here
                    buildPackages = __magic__.buildPackages;
                    # it doesn't really use the full callPackage so we can overwrite it with a fake one here
                    callPackage   = path: (import path) { 
                        lib = lib;
                        runCommand = impureHelpers.runCommand;
                        emptyFile = impureHelpers.emptyFile;
                        nix-diff = null; # it requires a whole haskell tool chain
                    };
                };
            };
            cowsay = __magic__.package {
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
