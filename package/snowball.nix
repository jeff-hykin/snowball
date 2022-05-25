{
    # snowball = import (builtins.fetchurl "https://raw.githubusercontent.com/jeff-hykin/snowball/29a4cb39d8db70f9b6d13f52b3a37a03aae48819/snowball.nix")
    # ikill = snowball "https://raw.githubusercontent.com/jeff-hykin/snowball/283c245be12fe40d4ff2b7402e9de06ae9baf698/"
    inputs =  {
        snowball        = {           ...}: import (builtins.fetchurl "https://raw.githubusercontent.com/jeff-hykin/snowball/29a4cb39d8db70f9b6d13f52b3a37a03aae48819/snowball.nix");
        nixpkgs         = { snowball, ...}: snowball.nixpkgsAt ("$COMMIT_HASH");
        stdenv          = { nixpkgs , ...} : nixpkgs.stdenv;
        lib             = { nixpkgs , ...} : nixpkgs.lib;
        callPackage     = { nixpkgs , ...} : nixpkgs.callPackage;
        fetchFromGitHub = { nixpkgs , ...} : nixpkgs.fetchFromGitHub;
        isLinux         = { stdenv  , ...} : stdenv.isLinux;
        isDarwin        = { stdenv  , ...} : stdenv.isDarwin;
    };
    outputs = { nixpkgs, stdenv, lib, ...}@inputs :
        let
            package = nixpkgs.$packagePath;
        in
            {
                nix_v1 = {
                    package = package;
                };
                snowball_v1 = {
                    shell = {
                        packages = [];
                        inputsFrom = [];
                        buildInputs = [ package ];
                        nativeBuildInputs = [];
                        propagatedBuildInputs = [];
                        propagatedNativeBuildInputs = [];
                        shellHook = "";
                    };
                };
            }
    ;
}