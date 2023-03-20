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
        
        python = {
            CONSTRAINTS = [
                [
                    "flavor:python: a programming language that lets you work quickly and integrate systems more effectively"
                    "version:3"
                ]
            ];
            GENERATE_DEFAULT_VALUE = { _pkgs, ...} : _pkgs.python3Full;
        };
    };
    
    TESTED_INPUTS = self: [
        self {
            SYSTEM = [ "kernel=darwin" "cpu=x86_64" "os_version=" ]; # system is the only special exception that can be a list of all attributes that the system had
            _nixpkgsHash = "3d7144c98c06a4ff4ff39e026bbf7eb4d5403b67";
        }
    ];
    
    OUTPUT = { SYSTEM, python, ... }@input:
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