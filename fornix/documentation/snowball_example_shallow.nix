{
    INPUT = {
        SYSTEM = {
            CONSTRAINTS = [
                # [ "kernel=darwin" "cpu:aarch64" ] # comment out if doesn't work on M1 macs
                [ "kernel=darwin" "cpu=x86_64" ]
                [ "kernel=linux" ]
            ];
            GENERATE_DEFAULT_VALUE = null; # system cannot be defaulted (it will always be the current system)
        };
        _nixpkgsHash = {
            CONSTRAINTS = [
                [ "flavor:nixpkgs: a bundle of effectively all packages" ]
            ];
            GENERATE_DEFAULT_VALUE = { ... } : "3d7144c98c06a4ff4ff39e026bbf7eb4d5403b67";
        };
        _pkgs = {
            CONSTRAINTS = [
                [
                    "nixValue:string: a utf-8 encoded string"
                    "nixValue:commitHash: a 40 character git commit hash"
                ]
            ];
            GENERATE_DEFAULT_VALUE = { _nixpkgsHash, ... }: (url: args: (builtins.import (builtins.fetchTarball ({url=url;}) ) (args) )) "https://github.com/NixOS/nixpkgs/archive/${nixpkgsHash}.tar.gz" {};
        };
        _nixDefaultArgs = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _pkgs, ... }: _pkgs.python__Args;
        };
        lib  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.lib;
        };
        stdenv  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.stdenv;
        };
        fetchurl  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.fetchurl;
        };
        fetchpatch  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.fetchpatch;
        };
        bzip2  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.bzip2;
        };
        expat  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.expat;
        };
        libffi  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.libffi;
        };
        gdbm  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.gdbm;
        };
        xz  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.xz;
        };
        mailcap  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.mailcap;
        };
        mimetypesSupport  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.mimetypesSupport;
        };
        ncurses  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.ncurses;
        };
        openssl  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.openssl;
        };
        openssl_legacy  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.openssl_legacy;
        };
        readline  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.readline;
        };
        sqlite  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.sqlite;
        };
        tcl  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.tcl;
        };
        tk  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.tk;
        };
        tix  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.tix;
        };
        libX11  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.libX11;
        };
        xorgproto  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.xorgproto;
        };
        x11Support  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.x11Support;
        };
        bluez  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.bluez;
        };
        bluezSupport  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.bluezSupport;
        };
        zlib  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.zlib;
        };
        tzdata  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.tzdata;
        };
        libxcrypt  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.libxcrypt;
        };
        self  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.self;
        };
        configd  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.configd;
        };
        autoreconfHook  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.autoreconfHook;
        };
        autoconf-archive  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.autoconf-archive;
        };
        pkg-config  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.pkg-config;
        };
        python-setup-hook  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.python-setup-hook;
        };
        nukeReferences  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.nukeReferences;
        };
        packageOverrides  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.packageOverrides;
        };
        pkgsBuildBuild  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.pkgsBuildBuild;
        };
        pkgsBuildHost  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.pkgsBuildHost;
        };
        pkgsBuildTarget  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.pkgsBuildTarget;
        };
        pkgsHostHost  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.pkgsHostHost;
        };
        pkgsTargetTarget  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.pkgsTargetTarget;
        };
        sourceVersion  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.sourceVersion;
        };
        sha256  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.sha256;
        };
        passthruFun  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.passthruFun;
        };
        bash  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.bash;
        };
        stripConfig  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.stripConfig;
        };
        stripIdlelib  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.stripIdlelib;
        };
        stripTests  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.stripTests;
        };
        stripTkinter  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.stripTkinter;
        };
        rebuildBytecode  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.rebuildBytecode;
        };
        stripBytecode  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.stripBytecode;
        };
        includeSiteCustomize  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.includeSiteCustomize;
        };
        static  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.static;
        };
        enableOptimizations  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.enableOptimizations;
        };
        enableNoSemanticInterpositio  [python = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.enableNoSemanticInterpositio;
        };
        enableLTO  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.enableLTO;
        };
        reproducibleBuild  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.reproducibleBuild;
        };
        pythonAttr  = {
            CONSTRAINTS = [];
            GENERATE_DEFAULT_VALUE = { _nixDefaultArgs, ...} : _nixDefaultArgs.pythonAttr;
        };

        CONSTRAINTS = { # constraints per INPUT value
            SYSTEM                        = [];
            _nixpkgsHash = [
                [
                    "nixValue:string: a utf-8 encoded string"
                    "nixValue:commitHash: a 40 character git commit hash"
                ]
            ];
            _pkgs = [
                [ "flavor:nixpkgs: a bundle of effectively all packages" ]
            ];
            lib                           = [];
            stdenv                        = [];
            fetchurl                      = [];
            fetchpatch                    = [];
            bzip2                         = [];
            expat                         = [];
            libffi                        = [];
            gdbm                          = [];
            xz                            = [];
            mailcap                       = [];
            mimetypesSupport              = [];
            ncurses                       = [];
            openssl                       = [];
            openssl_legacy                = [];
            readline                      = [];
            sqlite                        = [];
            tcl                           = [];
            tk                            = [];
            tix                           = [];
            libX11                        = [];
            xorgproto                     = [];
            x11Support                    = [];
            bluez                         = [];
            bluezSupport                  = [];
            zlib                          = [];
            tzdata                        = [];
            libxcrypt                     = [];
            self                          = [];
            configd                       = [];
            autoreconfHook                = [];
            autoconf-archive              = [];
            pkg-config                    = [];
            python-setup-hook             = [];
            nukeReferences                = [];
            packageOverrides              = [];
            pkgsBuildBuild                = [];
            pkgsBuildHost                 = [];
            pkgsBuildTarget               = [];
            pkgsHostHost                  = [];
            pkgsTargetTarget              = [];
            sourceVersion                 = [];
            sha256                        = [];
            passthruFun                   = [];
            bash                          = [];
            stripConfig                   = [];
            stripIdlelib                  = [];
            stripTests                    = [];
            stripTkinter                  = [];
            rebuildBytecode               = [];
            stripBytecode                 = [];
            includeSiteCustomize          = [];
            static                        = [];
            enableOptimizations           = [];
            enableNoSemanticInterposition = [];
            enableLTO                     = [];
            reproducibleBuild             = [];
            pythonAttr                    = [];
        };
        # inputs that this was tested with
        DEFAULT_VALUES = {
            # SYSTEM is always provided and can't be defaulted here (it will default to the host's system package)
            SYSTEM       = null;
            # define a little helper function
            _import      = { ... } : url: args: (builtins.import (builtins.fetchTarball ({url=url;}) ) (args) );
            _pkgsUrl     = { ... } : "3d7144c98c06a4ff4ff39e026bbf7eb4d5403b67";
            _pkgs        = { _pkgsUrl, _import, ...} : _import "https://github.com/NixOS/nixpkgs/archive/${nixpkgsHash}.tar.gz" {};
            python       = { _pkgs, ...} : _pkgs.python3Full;
            # customInput2 = { customInput1, ...} : customInput1.subPackage;
        };
        TESTED_VALUES = {
            _import  = { ... }@args: [ (DEFAULT_VALUES._import  args) ];
            _pkgsUrl = { ... }@args: [ (DEFAULT_VALUES._pkgsUrl args) ];
            _pkgs    = { ... }@args: [ (DEFAULT_VALUES._pkgs    args) ];
            python   = { ... }@args: [ (DEFAULT_VALUES.python   args) ];
        };
    };
    
    TESTED_INPUTS = self: [
        self {
            SYSTEM = [ "kernel=darwin" "cpu=x86_64" "os_version=" ]; # system is the only special exception that can be a list of all attributes that the system had
            _nixpkgsHash = "3d7144c98c06a4ff4ff39e026bbf7eb4d5403b67";
        }
    ];
    
    OUTPUT = { SYSTEM, _pkgs, ... }@input:
        let
            exampleValue1 = "blah";
            exampleValue2 = "blah";
        in
            _pkgs.callPackage ./package.nix
    ;
}