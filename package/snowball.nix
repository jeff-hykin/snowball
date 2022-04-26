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
    };
    outputs = { meta, inputs, ... }:
        let 
            lib                = inputs.lib;
            stdenv             = inputs.stdenv;
            buildPythonPackage = inputs.buildPythonPackage;
            fetchurl           = inputs.fetchurl;
            isPy37             = inputs.isPy37;
            isPy38             = inputs.isPy38;
            isPy39             = inputs.isPy39;
            isPy310            = inputs.isPy310;
            patchelf           = inputs.patchelf;
            pillow             = inputs.pillow;
            python             = inputs.python;
            pytorch            = inputs.pytorch;
            rpath              = lib.makeLibraryPath [ stdenv.cc.cc.lib ];
            version            = meta.version;
            date               = meta.date;
            pyVerNoDot         = builtins.replaceStrings [ "." ] [ "" ] python.pythonVersion;
            srcs        = import (builtins.fetchurl (meta.nightly_binary_hashes)) { inherit version date; };
            unsupported = throw "Unsupported system";
        in
            rec {
                package0 = inputs.buildPythonPackage  {
                    version = "${version}-${date}";
                    pname = meta.name;
                    format = "wheel";
                    src = fetchurl srcs."${stdenv.system}-${pyVerNoDot}" or unsupported;
                    disabled = !(isPy37 || isPy38 || isPy39 || isPy310);
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
                        description = "PyTorch vision library";
                        homepage = "https://pytorch.org/";
                        changelog = "https://github.com/pytorch/vision/releases/tag/v${version}";
                        # Includes CUDA and Intel MKL, but redistributions of the binary are not limited.
                        # https://docs.nvidia.com/cuda/eula/index.html
                        # https://www.intel.com/content/www/us/en/developer/articles/license/onemkl-license-faq.html
                        license = licenses.bsd3;
                        platforms = platforms.linux;
                        maintainers = with maintainers; [];
                    };
                };
                nixShell = {
                    buildInputs = [ package0 ];
                };
            };
}