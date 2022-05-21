{
    # ozoneSnow = import (builtins.fetchurl "https://raw.githubusercontent.com/jeff-hykin/snowball/d8e99a84049e8a2b4cf7fa4726d6e36204e8c41b/package/snowball.nix");
    # ozoneSnowball = (ozoneSnow.outputs (ozoneSnow.inputs // {}));
    # ozonePackage = ozoneSnowball.package0;
        
    inputs = rec {
        nixpkgs = (import (builtins.fetchTarball { url = "https://github.com/NixOS/nixpkgs/archive/307aac8774fbcb83f4f732edfd14d774611001aa.tar.gz"; }) {});
        variant       = "default";
        lib           = nixpkgs.lib;
        stdenv        = nixpkgs.stdenv;
        fetchurl      = nixpkgs.fetchurl;
        fontconfig    = nixpkgs.fontconfig;
        freetype      = nixpkgs.freetype;
        libICE        = nixpkgs.libICE;
        libSM         = nixpkgs.libSM;
        udev          = nixpkgs.udev;
        libX11        = nixpkgs.libX11;
        libXcursor    = nixpkgs.libXcursor;
        libXext       = nixpkgs.libXext;
        libXfixes     = nixpkgs.libXfixes;
        libXrandr     = nixpkgs.libXrandr;
        libXrender    = nixpkgs.libXrender;
    };
    outputs = { nixpkgs, variant, lib, stdenv, fetchurl, fontconfig, freetype, libICE, libSM, udev, libX11, libXcursor, libXext, libXfixes, libXrandr, libXrender, ... }:
        let 
            # info = rec {
            #     name = "torchvision";
            #     version = "0.13.0";
            #     description = "PyTorch vision library";
            #     homepage = "https://pytorch.org/";
            #     changelog = "https://github.com/pytorch/vision/releases/tag/v${version}";
            #     date = "20220420";
            #     license = {
            #         deprecated = false;
            #         free = true;
            #         fullName = "BSD 3-clause \"New\" or \"Revised\" License";
            #         redistributable = true;
            #         shortName = "bsd3";
            #         spdxId = "BSD-3-Clause";
            #         url = "https://spdx.org/licenses/BSD-3-Clause.html";
            #     }; # see lib.licenses to see whats available
            #     maintainers = [];
            #     platforms = [
            #         [ "x86_64-linux" ]
            #         # "aarch64-linux"
            #         # "armv7a-linux"
            #         # "armv7l-linux"
                    
            #         # print lib.platforms.linux to see whats available
            #     ];
            #     nightly_binary_hashes = "https://raw.githubusercontent.com/rehno-lindeque/ml-pkgs/master/pkgs/torchvision/nightly-binary-hashes.nix";
            # };
            info = {};
            package0 = stdenv.mkDerivation rec {
                pname = "segger-ozone";
                version = "3.22a";

                src = if
                    stdenv.system == "aarch64-linux"
                    # x86 mac: https://www.segger.com/downloads/jlink/JLink_MacOSX.pkg
                    # M1 mac: https://www.segger.com/downloads/jlink/JLink_MacOSX_arm64.pkg
                then
                    fetchurl {
                        url = "https://www.segger.com/downloads/jlink/Ozone_Linux_V${(lib.replaceChars ["."] [""] version)}_arm64.tgz";
                        sha256 = lib.fakeSha256;
                    }
                else
                    fetchurl {
                        url = "https://www.segger.com/downloads/jlink/Ozone_Linux_V${(lib.replaceChars ["."] [""] version)}_x86_64.tgz";
                        sha256 = "0v1r8qvp1w2f3yip9fys004pa0smlmq69p7w77lfvghs1rmg1649";
                    }
                ;

                rpath = lib.makeLibraryPath [
                    fontconfig
                    freetype
                    libICE
                    libSM
                    udev
                    libX11
                    libXcursor
                    libXext
                    libXfixes
                    libXrandr
                    libXrender
                ] + ":${stdenv.cc.cc.lib}/lib64";

                installPhase = ''
                    mkdir -p $out/bin
                    mv Lib lib
                    mv * $out
                    ln -s $out/Ozone $out/bin
                '';

                postFixup = ''
                    udev --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$out/Ozone" \
                    --set-rpath ${rpath}:$out/lib "$out/Ozone"

                    for file in $(find $out/lib -maxdepth 1 -type f -and -name \*.so\*); do
                        udev --set-rpath ${rpath}:$out/lib $file
                    done
                '';

                meta = with lib; {
                    description = "J-Link Debugger and Performance Analyzer";
                    longDescription = ''
                        Ozone is a cross-platform debugger and performance analyzer for J-Link
                        and J-Trace.

                            - Stand-alone graphical debugger
                            - Debug output of any tool chain and IDE 1
                            - C/C++ source level debugging and assembly instruction debugging
                            - Debug information windows for any purpose: disassembly, memory,
                            globals and locals, (live) watches, CPU and peripheral registers
                            - Source editor to fix bugs immediately
                            - High-speed programming of the application into the target
                            - Direct use of J-Link built-in features (Unlimited Flash
                            Breakpoints, Flash Download, Real Time Terminal, Instruction Trace)
                            - Scriptable project files to set up everything automatically
                            - New project wizard to ease the basic configuration of new projects

                        1 Ozone has been tested with the output of the following compilers:
                        GCC, Clang, ARM, IAR. Output of other compilers may be supported but is
                        not guaranteed to be.
                    '';
                    homepage = "https://www.segger.com/products/development-tools/ozone-j-link-debugger";
                    license = licenses.unfree;
                    maintainers = [ maintainers.bmilanov ];
                    platforms = lib.platforms.linux ++ [
                        
                    ];
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