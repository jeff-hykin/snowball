{
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
        package0 = inputs.rustPlatform.buildRustPackage  {
            pname = meta.name;
            version = meta.version;
            src = (inputs.fetchFromGitHub (meta.github));
            cargoSha256 = meta.cargoPackage.sha256;
            meta = meta;
        };
        nixShell = {
            buildInputs = [ package0 ];
        };
    };
}