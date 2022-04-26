{
    meta = {
        name = "salt";
        version = "v0.2.3";
        description = "Fast and simple task management from the CLI.";
        homepage = "https://github.com/Milo123459/salt";
        license = "mit";
        maintainers = [ ];
        github = {
            owner = "Milo123459";
            repo = "salt";
            rev = "v0.2.3";
            sha256 = "1d17lxz8kfmzybbpkz1797qkq1h4jwkbgwh2yrwrymraql8rfy42";
        };
        cargoPackage = {
            sha256 = "1615z6agnbfwxv0wn9xfkh8yh5waxpygv00m6m71ywzr49y0n6h6";
        };
    };
    inputs = rec {
        nixpkgs = (builtins.import
            (builtins.fetchTarball 
                ({
                    url = "https://github.com/NixOS/nixpkgs/archive/85a130db2a80767465b0b8a99e772595e728b2e4.tar.gz";
                })
            )
            ({})
        );
        # get a rustPlatform that has edition2021
        rustPlatform = nixpkgs.rustPlatform;
        fetchFromGitHub = nixpkgs.fetchFromGitHub;
        lib = nixpkgs.lib;
    };
    outputs = { meta, inputs, ... }: rec {
        preflakePackage = inputs.rustPlatform.buildRustPackage  {
            pname = meta.name;
            version = meta.version;
            src = (inputs.fetchFromGitHub (meta.github));
            cargoSha256 = meta.cargoPackage.sha256;
            meta = meta;
        };
        nixShell = {
            buildInputs = [ preflakePackage ];
        };
    };
}