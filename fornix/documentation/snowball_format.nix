{
    INPUT = {
        # What is expected for each input
        CONSTRAINTS = {
            SYSTEM = [
                # [ "kernel=darwin" "cpu:aarch64" ] # comment out if doesn't work on M1 macs
                [ "kernel=darwin" "cpu=x86_64" ]
                [ "kernel=linux" ]
            ];
            _nixpkgsHash = [
                [
                    "nixValue:string: a utf-8 encoded string"
                    "nixValue:commitHash: a 40 character git commit hash"
                ]
            ];
            _pkgs = [
                [ "flavor:nixpkgs: a bundle of effectively all packages" ]
            ];
            python = [
                [
                    "flavor:python: a programming language that lets you work quickly and integrate systems more effectively"
                    "version:3"
                ]
            ];
        };
        # inputs that this was tested with
        DEFAULT_VALUES = {
            # SYSTEM is always provided and can't be defaulted here (it will default to the host's system package)
            SYSTEM       = null;
            # define a little helper function
            _import      = { ... } : url: args: (builtins.import (builtins.fetchTarball ({url=url;}) ) (args) );
            _nixpkgsHash = { ... } : "3d7144c98c06a4ff4ff39e026bbf7eb4d5403b67";
            _pkgs        = { _nixpkgsHash, _import, ...} : _import "https://github.com/NixOS/nixpkgs/archive/${nixpkgsHash}.tar.gz" {};
            python       = { _pkgs, ...} : _pkgs.python3Full;
            # customInput2 = { customInput1, ...} : customInput1.subPackage;
        };
        TESTED_VALUES = {
            _import      = { ... }@args: [ (DEFAULT_VALUES._import      args) ];
            _nixpkgsHash = { ... }@args: [ (DEFAULT_VALUES._nixpkgsHash args) ];
            _pkgs        = { ... }@args: [ (DEFAULT_VALUES._pkgs        args) ];
            python       = { ... }@args: [ (DEFAULT_VALUES.python       args) ];
        };
    };
    
    PACKAGE_GENERATOR = { python, ... }@input:
        let
            exampleValue1 = "blah";
            exampleValue2 = "blah";
        in
            {
                # packages."x86_64-linux" = pkgs.stdenv.mkDerivation {
                # 
                # };
                packages."${SYSTEM.cpu}-${SYSTEM.kernel}" = python;
            }
    ;
}