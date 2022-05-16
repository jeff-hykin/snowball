let 
    permittedInsecurePackages = [
        "linux-4.13.16"
        "openssl-1.0.2u"
    ];
in
    {
        allowUnfree = true;
        nixpkgs.config.permittedInsecurePackages = permittedInsecurePackages;
        permittedInsecurePackages = permittedInsecurePackages;
    }