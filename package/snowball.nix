{
    # snowball = import (builtins.fetchurl "https://raw.githubusercontent.com/jeff-hykin/snowball/29a4cb39d8db70f9b6d13f52b3a37a03aae48819/snowball.nix")
    # ikill = snowball "https://raw.githubusercontent.com/jeff-hykin/snowball/283c245be12fe40d4ff2b7402e9de06ae9baf698/"
    inputs = rec {
        nixpkgs = (builtins.import
            (builtins.fetchTarball 
                ({
                    url = "https://github.com/NixOS/nixpkgs/archive/85a130db2a80767465b0b8a99e772595e728b2e4.tar.gz";
                })
            )
            ({})
        );
        variant  = "default";
        lib      = nixpkgs.lib;
        stdenv   = nixpkgs.stdenv;
        isPy37   = nixpkgs.isPy37;
        isPy38   = nixpkgs.isPy38;
        isPy39   = nixpkgs.isPy39;
        isPy310  = nixpkgs.isPy310;
        patchelf = nixpkgs.patchelf;
        pillow   = nixpkgs.pillow;
        python   = nixpkgs.python;
        pytorch  = nixpkgs.pytorch;
        buildPythonPackage = nixpkgs.buildPythonPackage;
    };
    outputs = { variant, lib, stdenv, isPy37, isPy38, isPy39, isPy310, patchelf, pillow, python, pytorch, buildPythonPackage, ... }:
        let 
            info = rec {
                name = "torchvision";
                version = "0.13.0";
                description = "PyTorch vision library";
                homepage = "https://pytorch.org/";
                changelog = "https://github.com/pytorch/vision/releases/tag/v${version}";
                date = "20220420";
                license = {
                    deprecated = false;
                    free = true;
                    fullName = "BSD 3-clause \"New\" or \"Revised\" License";
                    redistributable = true;
                    shortName = "bsd3";
                    spdxId = "BSD-3-Clause";
                    url = "https://spdx.org/licenses/BSD-3-Clause.html";
                }; # see lib.licenses to see whats available
                maintainers = [];
                platforms = [
                    [ "x86_64-linux" ]
                    # "aarch64-linux"
                    # "armv7a-linux"
                    # "armv7l-linux"
                    
                    # print lib.platforms.linux to see whats available
                ];
                nightly_binary_hashes = "https://raw.githubusercontent.com/rehno-lindeque/ml-pkgs/master/pkgs/torchvision/nightly-binary-hashes.nix";
            };
            srcs = (builtins.import
                (builtins.fetchurl (info.nightly_binary_hashes))
                ({
                    version = info.version;
                    date = info.date;
                })
            );
            rpath       = lib.makeLibraryPath [ stdenv.cc.cc.lib ];
            pyVerNoDot  = builtins.replaceStrings [ "." ] [ "" ] python.pythonVersion;
            unsupported = throw "Unsupported system";
            
            package0 = buildPythonPackage  {
                version = "${info.version}-${info.date}";
                pname = info.name;
                format = "wheel";
                
                disabled = !(isPy37 || isPy38 || isPy39 || isPy310);
                src = (builtins.fetchurl (srcs."${stdenv.system}-${pyVerNoDot}") || unsupported);
                
                nativeBuildInputs = [
                    patchelf
                ];
                propagatedBuildInputs = [
                    pillow
                    pytorch
                ];

                # The wheel-binary is not stripped to avoid the error of `ImportError: libtorch_cuda_cpp.so: ELF load command address/offset not properly aligned.`.
                dontStrip = true;

                pythonImportsCheck = [ "torchvision" ];

                postFixup = ''
                    # Note: after patchelf'ing, libcudart can still not be found. However, this should
                    #       not be an issue, because PyTorch is loaded before torchvision and brings
                    #       in the necessary symbols.
                    patchelf --set-rpath "${rpath}:${pytorch}/${python.sitePackages}/torch/lib:" \
                    "$out/${python.sitePackages}/torchvision/_C.so"
                '';

                meta = with lib; {
                    description = info.description;
                    homepage = info.homepage;
                    changelog = info.changelog;
                    # Includes CUDA and Intel MKL, but redistributions of the binary are not limited.
                    # https://docs.nvidia.com/cuda/eula/index.html
                    # https://www.intel.com/content/www/us/en/developer/articles/license/onemkl-license-faq.html
                    license = info.license;
                    platforms = info.platforms;
                    maintainers = with maintainers; [];
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