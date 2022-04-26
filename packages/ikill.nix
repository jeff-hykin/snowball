{
    meta = {
        name = "ikill";
        version = "v1.5.0";
        description = "Interactively kill running processes, inspired by fkill-cli";
        homepage = "https://github.com/pjmp/ikill";
        license = "mit";
        maintainers = [ ];
        github = {
            owner = "pjmp";
            repo = "ikill";
            rev = "v1.5.0";
            sha256 = "0hpq7x9qk7cga26385phbsqaz100ipngnj0gh2zys43bg466w4dk";
        };
        cargoPackage = {
            sha256 = "1937lpvwnw4cbdk9aivrga3d1m30chkaxwlg2n3j0ybik8lp42b7";
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
        preflakePackage = inputs.rustPlatform.buildRustPackage rec {
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