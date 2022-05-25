{
    stdenv,
    buildPackages,
    lib,
    fetchurl,
    fetchpatch,
    fetchFromSavannah,
    fetchFromGitHub,
    zlib,
    openssl,
    gdbm,
    ncurses,
    readline,
    groff,
    libyaml,
    libffi,
    jemalloc,
    autoreconfHook,
    bison,
    autoconf,
    libiconv,
    libobjc,
    libunwind,
    Foundation,
    buildEnv,
    bundler,
    bundix,
    makeWrapper,
    buildRubyGem,
    defaultGemConfig,
    removeReferencesTo
} @ args:

    let
        op = lib.optional;
        ops = lib.optionals;
        opString = lib.optionalString;
        patchSet = fetchFromGitHub {
            owner  = "skaes";
            repo   = "rvm-patchsets";
            rev    = "0251817e2b9d5f73370bbbb12fdf7f7089bd1ac3";
            sha256 = "1biiq5xzzdfb4hr1sgmx14i2nr05xa9w21pc7dl8c5n4f2ilg8ss";
        };
        config = fetchFromSavannah { # Ruby >= 2.1.0 tries to download config.{guess,sub}
            repo = "config";
            rev = "576c839acca0e082e536fd27568b90a446ce5b96";
            sha256 = "11bjngchjhj0qq0ppp8c37rfw0yhp230nvhs2jvlx15i9qbf56a0";
        };
        rubygems = import ./rubygems {
            stdenv = stdenv;
            lib = lib;
            fetchurl = fetchurl; 
        };
        rubyVersion = import ./ruby-version.nix { # Contains the ruby version heuristics
            lib = lib;
        };

        generic = { version, sha256, generatePatches }:
            let
                ver = version;
                tag = ver.gitTag;
                atLeast30 = lib.versionAtLeast ver.majMin "3.0";
                self = lib.makeOverridable (
                    {
                        stdenv,
                        buildPackages,
                        lib,
                        fetchurl,
                        fetchpatch,
                        fetchFromSavannah,
                        fetchFromGitHub,
                        useRailsExpress ? true,
                        rubygemsSupport ? true,
                        zlib,
                        zlibSupport ? true,
                        openssl,
                        opensslSupport ? true,
                        gdbm,
                        gdbmSupport ? true,
                        ncurses,
                        readline,
                        cursesSupport ? true,
                        groff,
                        docSupport ? true,
                        libyaml,
                        yamlSupport ? true,
                        libffi,
                        fiddleSupport ? true,
                        jemalloc,
                        jemallocSupport ? false,
                        removeReferencesTo,
                        # By default, ruby has 3 observed references to stdenv.cc:
                        #
                        # - If you run:
                        #     ruby -e "puts RbConfig::CONFIG['configure_args']"
                        # - In:
                        #     $out/${passthru.libPath}/${stdenv.hostPlatform.system}/rbconfig.rb
                        #   Or (usually):
                        #     $(nix-build -A ruby)/lib/ruby/2.6.0/x86_64-linux/rbconfig.rb
                        # - In $out/lib/libruby.so and/or $out/lib/libruby.dylib,
                        jitSupport ? false,
                        autoreconfHook,
                        bison,
                        autoconf,
                        buildEnv,
                        bundler,
                        bundix,
                        libiconv,
                        libobjc,
                        libunwind,
                        Foundation,
                        makeWrapper,
                        buildRubyGem,
                        defaultGemConfig,
                        baseRuby ? (buildPackages.ruby.override {
                            useRailsExpress = false;
                            docSupport = false;
                            rubygemsSupport = false;
                        }),
                        useBaseRuby ? stdenv.hostPlatform != stdenv.buildPlatform || useRailsExpress
                    }:
                        stdenv.mkDerivation rec {
                            pname = "ruby";
                            version = version;
                            src = (
                                if useRailsExpress
                                then fetchFromGitHub {
                                    owner  = "ruby";
                                    repo   = "ruby";
                                    rev    = tag;
                                    sha256 = sha256.git;
                                }
                                
                                else fetchurl {
                                    url = "https://cache.ruby-lang.org/pub/ruby/${ver.majMin}/ruby-${ver}.tar.gz";
                                    sha256 = sha256.src;
                                }
                            );
                            outputs = (
                                [ "out" ]
                                ++ (lib.optional (docSupport) "devdoc")
                            );
                            nativeBuildInputs = (
                                [ autoreconfHook bison ]
                                ++ (op docSupport groff)
                                ++ (op useBaseRuby baseRuby)
                            );
                            buildInputs = (
                                [ autoconf ]
                                ++ (op  (fiddleSupport)   libffi             )
                                ++ (ops (cursesSupport)   [ ncurses readline])
                                ++ (op  (zlibSupport)     zlib               )
                                ++ (op  (opensslSupport)  openssl            )
                                ++ (op  (gdbmSupport)     gdbm               )
                                ++ (op  (yamlSupport)     libyaml            )
                                ++ (op  (jemallocSupport) jemalloc           )
                                # Looks like ruby fails to build on darwin without readline even if curses
                                # support is not enabled, so add readline to the build inputs if curses
                                # support is disabled (if it's enabled, we already have it) and we're
                                # running on darwin
                                ++ (op  (!cursesSupport && stdenv.isDarwin) readline                                 )
                                ++ (ops (stdenv.isDarwin)                   [ libiconv libobjc libunwind Foundation ])
                            );

                            enableParallelBuilding = true;

                            patches = (generatePatches {
                                patchSet        = patchSet;
                                useRailsExpress = useRailsExpress;
                                ops             = ops;
                                fetchpatch      = fetchpatch;
                                rubygemsSupport = rubygemsSupport;
                                patchLevel      = ver.patchLevel;
                            });
                            
                            postUnpack = opString rubygemsSupport ''
                                rm -rf $sourceRoot/{lib,test}/rubygems*
                                cp -r ${rubygems}/lib/rubygems* $sourceRoot/lib
                                cp -r ${rubygems}/test/rubygems $sourceRoot/test
                            '';

                            postPatch = ''
                                sed -i configure.ac -e '/config.guess/d'
                                cp --remove-destination ${config}/config.guess tool/
                                cp --remove-destination ${config}/config.sub tool/
                                '' + opString (!atLeast30) ''
                                # Make the build reproducible for ruby <= 2.7
                                # See https://github.com/ruby/io-console/commit/679a941d05d869f5e575730f6581c027203b7b26#diff-d8422f096931c58d4463e2489f62a228b0f24f0492950ba88c8c89a0d741cfe6
                                sed -i ext/io/console/io-console.gemspec -e '/s\.date/d'
                            '';

                            configureFlags = [
                                    (lib.enableFeature (!stdenv.hostPlatform.isStatic) "shared")
                                    (lib.enableFeature true "pthread")
                                    (lib.withFeatureAs true "soname" "ruby-${version}")
                                    (lib.withFeatureAs useBaseRuby "baseruby" "${baseRuby}/bin/ruby")
                                    (lib.enableFeature jitSupport "jit-support")
                                    (lib.enableFeature docSupport "install-doc")
                                    (lib.withFeature jemallocSupport "jemalloc")
                                    (lib.withFeatureAs docSupport "ridir" "${placeholder "devdoc"}/share/ri")
                                ] ++ ops stdenv.isDarwin [
                                    # on darwin, we have /usr/include/tk.h -- so the configure script detects
                                    # that tk is installed
                                    "--with-out-ext=tk"
                                    # on yosemite, "generating encdb.h" will hang for a very long time without this flag
                                    "--with-setjmp-type=setjmp"
                                ]
                            ;

                            preConfigure = opString docSupport ''
                                # rdoc creates XDG_DATA_DIR (defaulting to $HOME/.local/share) even if
                                # it's not going to be used.
                                export HOME=$TMPDIR
                            '';

                            # fails with "16993 tests, 2229489 assertions, 105 failures, 14 errors, 89 skips"
                            # mostly TZ- and patch-related tests
                            # TZ- failures are caused by nix sandboxing, I didn't investigate others
                            doCheck = false;

                            preInstall = ''
                                # Ruby installs gems here itself now.
                                mkdir -pv "$out/${passthru.gemPath}"
                                export GEM_HOME="$out/${passthru.gemPath}"
                            '';

                            installFlags = lib.optional docSupport "install-doc";
                            # Bundler tries to create this directory
                            postInstall = ''
                                rbConfig=$(find $out/lib/ruby -name rbconfig.rb)
                                # Remove references to the build environment from the closure
                                sed -i '/^  CONFIG\["\(BASERUBY\|SHELL\|GREP\|EGREP\|MKDIR_P\|MAKEDIRS\|INSTALL\)"\]/d' $rbConfig
                                # Remove unnecessary groff reference from runtime closure, since it's big
                                sed -i '/NROFF/d' $rbConfig
                                ${
                                    lib.optionalString (!jitSupport) ''
                                    # Get rid of the CC runtime dependency
                                    ${removeReferencesTo}/bin/remove-references-to \
                                        -t ${stdenv.cc} \
                                        $out/lib/libruby*
                                    ${removeReferencesTo}/bin/remove-references-to \
                                        -t ${stdenv.cc} \
                                        $rbConfig
                                    sed -i '/CC_VERSION_MESSAGE/d' $rbConfig
                                    ''
                                }
                                # Bundler tries to create this directory
                                mkdir -p $out/nix-support
                                cat > $out/nix-support/setup-hook <<EOF
                                addGemPath() {
                                    addToSearchPath GEM_PATH \$1/${passthru.gemPath}
                                }
                                addRubyLibPath() {
                                    addToSearchPath RUBYLIB \$1/lib/ruby/site_ruby
                                    addToSearchPath RUBYLIB \$1/lib/ruby/site_ruby/${ver.libDir}
                                    addToSearchPath RUBYLIB \$1/lib/ruby/site_ruby/${ver.libDir}/${stdenv.hostPlatform.system}
                                }

                                addEnvHooks "$hostOffset" addGemPath
                                addEnvHooks "$hostOffset" addRubyLibPath
                                EOF
                                '' + opString docSupport ''
                                # Prevent the docs from being included in the closure
                                sed -i "s|\$(DESTDIR)$devdoc|\$(datarootdir)/\$(RI_BASE_NAME)|" $rbConfig
                                sed -i "s|'--with-ridir=$devdoc/share/ri'||" $rbConfig

                                # Add rbconfig shim so ri can find docs
                                mkdir -p $devdoc/lib/ruby/site_ruby
                                cp ${./rbconfig.rb} $devdoc/lib/ruby/site_ruby/rbconfig.rb
                                '' + opString useBaseRuby ''
                                # Prevent the baseruby from being included in the closure.
                                ${removeReferencesTo}/bin/remove-references-to \
                                    -t ${baseRuby} \
                                    $rbConfig $out/lib/libruby*
                            '';

                            disallowedRequisites =
                                op (!jitSupport) stdenv.cc.cc
                                ++ op useBaseRuby baseRuby;

                            meta = with lib; {
                                description = "The Ruby language";
                                homepage    = "http://www.ruby-lang.org/en/";
                                license     = licenses.ruby;
                                maintainers = with maintainers; [ vrthra manveru marsam ];
                                platforms   = platforms.all;
                            };

                            passthru = rec {
                                version = ver;
                                rubyEngine = "ruby";
                                libPath = "lib/${rubyEngine}/${ver.libDir}";
                                gemPath = "lib/${rubyEngine}/gems/${ver.libDir}";
                                devEnv =
                                    let
                                        bundler_ = bundler.override {
                                            ruby = ruby;
                                        };
                                        bundix_ = bundix.override {
                                            bundler = bundler_;
                                        };
                                    in
                                        buildEnv {
                                            name = "${ruby.rubyEngine}-dev-${ruby.version}";
                                            paths = [
                                                bundix_
                                                bundler_
                                                ruby
                                            ];
                                            pathsToLink = [ "/bin" ];
                                            ignoreCollisions = true;
                                        }
                                ;
                                inherit (import ../../ruby-modules/with-packages {
                                    lib = lib;
                                    stdenv = stdenv;
                                    makeWrapper = makeWrapper;
                                    buildRubyGem = buildRubyGem;
                                    buildEnv = buildEnv;
                                    gemConfig = defaultGemConfig;
                                    ruby = self;
                                }) withPackages gems;

                                # deprecated 2016-09-21
                                majorVersion = ver.major;
                                minorVersion = ver.minor;
                                teenyVersion = ver.tiny;
                                patchLevel = ver.patchLevel;
                            } // lib.optionalAttrs useBaseRuby {
                                baseRuby = baseRuby;
                            };
                            
                            # Have `configure' avoid `/usr/bin/nroff' in non-chroot builds.
                            NROFF =
                                if docSupport
                                then "${groff}/bin/nroff"
                                
                                else null;
                        }
                ) args;
            in
                self;
    in 
        {
            ruby_2_6 = generic {
                version = rubyVersion "2" "6" "9" "";
                sha256 = {
                    src = "1fzgn1w62y71fgan6vxfcaxwql74zb5a841p2nr9xgv4mixawyzb";
                    git = "1v7x5zj31zjjy73ak0m3avqxyc0kcpykk926k853xgk85vq3y8bk";
                };
                generatePatches =  { patchSet, useRailsExpress, ops, patchLevel, fetchpatch, rubygemsSupport }:
                    ops useRailsExpress [
                        "${patchSet}/patches/ruby/2.6/head/railsexpress/01-fix-broken-tests-caused-by-ad.patch"
                        "${patchSet}/patches/ruby/2.6/head/railsexpress/02-improve-gc-stats.patch"
                        "${patchSet}/patches/ruby/2.6/head/railsexpress/03-more-detailed-stacktrace.patch"
                        ./do-not-regenerate-revision.h.patch
                    ]
                    ++ (op (rubygemsSupport) (fetchpatch { url = "https://github.com/ruby/ruby/commit/261d8dd20afd26feb05f00a560abd99227269c1c.patch"; sha256 = "0wrii25cxcz2v8bgkrf7ibcanjlxwclzhayin578bf0qydxdm9qy"; }))
                ;
            };
            
            ruby_2_7 = generic {
                version = rubyVersion "2" "7" "5" "";
                sha256 = {
                    src = "1wc1hwmz4m6iqlmqag8liyld917p6a8dvnhnpd1v8d8jl80bjm97";
                    git = "16565fyl7141hr6q6d74myhsz46lvgam8ifnacshi68vzibwjbbh";
                };
                generatePatches =  { patchSet, useRailsExpress, ops, patchLevel, fetchpatch, rubygemsSupport }:
                    ops useRailsExpress [
                        "${patchSet}/patches/ruby/2.7/head/railsexpress/01-fix-broken-tests-caused-by-ad.patch"
                        "${patchSet}/patches/ruby/2.7/head/railsexpress/02-improve-gc-stats.patch"
                        "${patchSet}/patches/ruby/2.7/head/railsexpress/03-more-detailed-stacktrace.patch"
                        ./do-not-regenerate-revision.h.patch
                    ]
                    ++ (op (rubygemsSupport) (fetchpatch { url = "https://github.com/ruby/ruby/commit/261d8dd20afd26feb05f00a560abd99227269c1c.patch"; sha256 = "0wrii25cxcz2v8bgkrf7ibcanjlxwclzhayin578bf0qydxdm9qy"; }))
                    # Ruby prior to 3.0 has a bug the installer (tools/rbinstall.rb) but
                    # the resulting error was swallowed. Newer rubygems no longer swallows
                    # this error. We upgrade rubygems when rubygemsSupport is enabled, so
                    # we have to fix this bug to prevent the install step from failing.
                    # See https://github.com/ruby/ruby/pull/2930
                ;
            };

            ruby_3_0 = generic {
                version = rubyVersion "3" "0" "3" "";
                sha256 = {
                    src = "1b4j39zyyvdkf1ax2c6qfa40b4mxfkr87zghhw19fmnzn8f8d1im";
                    git = "1q19w5i1jkfxn7qq6f9v9ngax9h52gxwijk7hp312dx6amwrkaim";
                };
                generatePatches =  { patchSet, useRailsExpress, ops, patchLevel, fetchpatch, rubygemsSupport }:
                    (ops useRailsExpress [
                        "${patchSet}/patches/ruby/3.0/head/railsexpress/01-improve-gc-stats.patch"
                        "${patchSet}/patches/ruby/3.0/head/railsexpress/02-malloc-trim.patch"
                        ./do-not-regenerate-revision.h.patch
                        ./do-not-update-gems-baseruby.patch
                    ])
                ;
            };

            ruby_3_1 = generic {
                version = rubyVersion "3" "1" "0" "";
                sha256 = {
                    src = "sha256-UKBQTG7ctNYc5rjP292qlXBxlfqw7Ne16SZUsqlBKFQ=";
                    git = "sha256-TcsoWY+zVZeue1/ypV1L0WERp1UVK35WtVtYPYiJh4c=";
                };
                generatePatches =  { patchSet, useRailsExpress, ops, patchLevel, fetchpatch, rubygemsSupport }:
                    ops useRailsExpress [
                        # no patches yet (2021-12-25)
                        ./do-not-update-gems-baseruby.patch
                    ]
                ;
            };
        }
