{
    # snowball = import (builtins.fetchurl "https://raw.githubusercontent.com/jeff-hykin/snowball/29a4cb39d8db70f9b6d13f52b3a37a03aae48819/snowball.nix")
    # ikill = snowball "https://raw.githubusercontent.com/jeff-hykin/snowball/283c245be12fe40d4ff2b7402e9de06ae9baf698/"
    inputs = 
        let 
            nixpkgs = (builtins.import
                (builtins.fetchTarball 
                    ({
                        url = "https://github.com/NixOS/nixpkgs/archive/85a130db2a80767465b0b8a99e772595e728b2e4.tar.gz";
                    })
                )
                ({})
            );
            arch = nixpkgs.rust.toRustTarget nixpkgs.stdenv.hostPlatform;
            fetch_librusty_v8 = args: nixpkgs.fetchurl {
                name = "librusty_v8-${args.version}";
                url = "https://github.com/denoland/rusty_v8/releases/download/v${args.version}/librusty_v8_release_${arch}.a";
                sha256 = args.shas.${nixpkgs.stdenv.hostPlatform.system};
                meta = { inherit (args) version; };
            };
        in
            {
                variant  = "default";
                stdenv             = nixpkgs.stdenv;
                lib                = nixpkgs.lib;
                callPackage        = nixpkgs.callPackage;
                fetchFromGitHub    = nixpkgs.fetchFromGitHub;
                rustPlatform       = nixpkgs.rustPlatform;
                installShellFiles  = nixpkgs.installShellFiles;
                libiconv           = nixpkgs.libiconv;
                libobjc            = nixpkgs.libobjc;
                Security           = nixpkgs.Security;
                CoreServices       = nixpkgs.CoreServices;
                Metal              = nixpkgs.Metal;
                Foundation         = nixpkgs.Foundation;
                QuartzCore         = nixpkgs.QuartzCore;
                librusty_v8        = (nixpkgs.fetch_librusty_v8 ({}));
            };
    outputs = { variant, stdenv, lib, callPackage, fetchFromGitHub, rustPlatform, installShellFiles, libiconv, libobjc, Security, CoreServices, Metal, Foundation, QuartzCore, librusty_v8, ... }:
        let 
            version = "1.21.0";
            info = {
                name = "deno";
                version = version;
                homepage = "https://deno.land/";
                changelog = "https://github.com/denoland/deno/releases/tag/v${version}";
                description = "A secure runtime for JavaScript and TypeScript";
                longDescription = ''
                    Deno aims to be a productive and secure scripting environment for the modern programmer.
                    Deno will always be distributed as a single executable.
                    Given a URL to a Deno program, it is runnable with nothing more than the ~15 megabyte zipped executable.
                    Deno explicitly takes on the role of both runtime and package manager.
                    It uses a standard browser-compatible protocol for loading modules: URLs.
                    Among other things, Deno is a great replacement for utility scripts that may have been historically written with
                    bash or python.
                '';
                license = lib.licenses.mit;
                maintainers = [ lib.maintainers.jk ];
                platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
            };
            package0 = rustPlatform.buildRustPackage rec {
                pname = info.name;
                version = info.version;

                src = fetchFromGitHub {
                    owner = "denoland";
                    repo = info.name;
                    rev = "v${info.version}";
                    sha256 = "sha256-Sv9Keb+6vc6Lr+H/gAi9/4bmBO18gv9bqAjBIpOrtnk=";
                };
                cargoSha256 = "sha256-EykIg8rU2VBag+3834SwMYkz9ZR6brOo/0NXXvrGqsU=";

                postPatch = ''
                    # upstream uses lld on aarch64-darwin for faster builds
                    # within nix lld looks for CoreFoundation rather than CoreFoundation.tbd and fails
                    substituteInPlace .cargo/config --replace '"-C", "link-arg=-fuse-ld=lld"' ""
                '';

                # Install completions post-install
                nativeBuildInputs = [ installShellFiles ];

                buildAndTestSubdir = "cli";

                buildInputs = lib.optionals stdenv.isDarwin [ libiconv libobjc Security CoreServices Metal Foundation QuartzCore ];

                # The v8 package will try to download a `librusty_v8.a` release at build time to our read-only filesystem
                # To avoid this we pre-download the file and export it via RUSTY_V8_ARCHIVE
                RUSTY_V8_ARCHIVE = librusty_v8;

                # Tests have some inconsistencies between runs with output integration tests
                # Skipping until resolved
                doCheck = false;

                preInstall = ''
                    find ./target -name libswc_common${stdenv.hostPlatform.extensions.sharedLibrary} -delete
                '';

                postInstall = ''
                    installShellCompletion --cmd deno \
                    --bash <($out/bin/deno completions bash) \
                    --fish <($out/bin/deno completions fish) \
                    --zsh <($out/bin/deno completions zsh)
                '';

                doInstallCheck = true;
                installCheckPhase = ''
                    runHook preInstallCheck
                    $out/bin/deno --help
                    $out/bin/deno --version | grep "deno ${info.version}"
                    runHook postInstallCheck
                '';

                passthru.updateScript =  (builtins.fetchurl (https://raw.githubusercontent.com/NixOS/nixpkgs/d7ca105981b7249338a278ac96b6afad6affb338/pkgs/development/web/deno/update/update.ts));

                meta = {
                    homepage        = info.homepage;
                    changelog       = info.changelog;
                    description     = info.description;
                    longDescription = info.longDescription;
                    license         = info.license;
                    maintainers     = info.maintainers;
                    platforms       = info.platforms;
                };
            };
        in
            {
                info = info;
                package0 = package0;
                nixShell = {
                    buildInputs = [ package0 ];
                };
            };
}