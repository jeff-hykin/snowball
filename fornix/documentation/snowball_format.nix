{
    # must be JSON-able
    META = {
        "isPackage"               = true;
        "flavor:something: blurb" = true;
        "commitDate"              = "2022-01-01";
    };
    
    # probably can view at: https://github.com/NixOS/nixpkgs/blob/${nixpkgsHash}/${relativePath}
    DEFAULT_INPUTS = {
        _import      = { ... } : url: args: (builtins.import (builtins.fetchTarball ({url=url;}) ) (args) );
        _nixpkgsHash = { ... } : "3d7144c98c06a4ff4ff39e026bbf7eb4d5403b67";
        _pkgs        = { _nixpkgsHash, _import, ...} : _import "https://github.com/NixOS/nixpkgs/archive/${nixpkgsHash}.tar.gz" {};
        python       = { _pkgs, ...} : _pkgs.python3Full;
        # customInput2 = { customInput1, ...} : customInput1.subPackage;
    };
    
    INPUT_CONSTRAINTS = {
        _nixpkgsHash = [
            [ "nixValue:string: a utf-8 encoded string" ]
            [ "nixValue:commitHash: a 40 character git commit hash" ]
        ];
        _pkgs = [
            [ "flavor:nixpkgs: a bundle of effectively all packages" ]
        ];
        python = [
            [ "flavor:nixpkgs: a bundle of effectively all packages" ]
        ];
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
                packages."x86_64-linux"   = pkgs.${attributePath};
                packages."aarch64-linux"  = pkgs.${attributePath};
                packages."i686-linux"     = pkgs.${attributePath};
                packages."x86_64-darwin"  = pkgs.${attributePath};
                packages."aarch64-darwin" = pkgs.${attributePath};
            }
    ;
}