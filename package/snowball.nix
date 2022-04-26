{
    inputs = rec {
        nix = (builtins.import
            (builtins.fetchTarball 
                ({
                    url = "https://github.com/NixOS/nixpkgs/archive/85a130db2a80767465b0b8a99e772595e728b2e4.tar.gz";
                })
            )
            ({})
        ).nix;
    };
    outputs = { variant, nix, ... }:
        let 
            info = {
                name = "nix";
                version = nix.version;
                description = nix.meta.description; # see lib.licenses to see whats available
                homepage = nix.meta.homepage; # see lib.licenses to see whats available
                license = nix.meta.license; # see lib.licenses to see whats available
                maintainers = nix.meta.maintainers;
                platforms = nix.meta.platforms;
            };
        in
            {
                info = info;
                package0 = nix;
                nixShell = {
                    buildInputs = [ nix ];
                };
            };
}