let 
    permittedInsecurePackages = [
        "linux-4.13.16"
        "openssl-1.0.2u"
    ];
in
    {__id_static="0.9965333620239523";__id_dynamic=builtins.hashFile "sha256" /Users/jeffhykin/repos/snowball/random.ignore;

        allowUnfree = true;
        nixpkgs.config.permittedInsecurePackages = permittedInsecurePackages;
        permittedInsecurePackages = permittedInsecurePackages;
    }