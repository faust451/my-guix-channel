(define-module (moon packages)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages base)
  #:use-module (guix search-paths)
  #:use-module ((nonguix licenses) #:select (nonfree))
  #:use-module ((guix licenses) #:select (expat))
  #:use-module (guix build-system copy)
  #:use-module (gnu packages gcc)
  #:use-module (nonguix build-system binary)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module ((guix licenses) #:prefix license:))

(define-public claude-cli
  (package
    (name "claude-cli")
    (version "2.1.218")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/"
                    version "/linux-x64/claude"))
              (sha256 (base32 "1wk3mzgmrfpprwwagx5gka7w2jphiwsh7h8j22pvhdlk39sp2871"))))
    (build-system binary-build-system)
    (arguments
     (list
      #:validate-runpath? #f
      #:strip-binaries? #f
      #:install-plan #~'(("claude" "bin/claude"))
      ;; empty list = only patch interpreter, no rpath
      #:patchelf-plan #~'(("claude" ()))  
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'chmod
            (lambda _
              (chmod "claude" #o755))))))
    (inputs (list glibc))
    (supported-systems '("x86_64-linux"))
    (synopsis "Claude Code CLI from Anthropic")
    (description "AI-powered coding assistant for the terminal.")
    (home-page "https://docs.anthropic.com/en/docs/claude-code")
    (license (nonfree "https://www.anthropic.com/legal/consumer-terms"))))

(define-public gh-bin
  (package
    (name "gh-bin")
    (version "2.63.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/cli/cli/releases/download/v" version
             "/gh_" version "_linux_amd64.tar.gz"))
       (sha256
        (base32  "007d5lkh02wsq6g0z7d24f4hg2d2hyvx5ibgfkxhbc4wl8fdnbwi"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("bin/gh" "bin/")
         ("share/man/" "share/man/"))))
    (synopsis "GitHub's official command line tool")
    (description
     "gh is GitHub on the command line. It brings pull requests, issues,
GitHub Actions, and other GitHub features to your terminal.")
    (home-page "https://cli.github.com/")
    (license expat)))

(define-public gleam
  (package
    (name "gleam")
    (version "1.14.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/gleam-lang/gleam/releases/download/v"
             version "/gleam-v" version "-x86_64-unknown-linux-musl.tar.gz"))
       (sha256
        (base32 "1s6c9wm1hdwx6s1y80y5ibfh856w8kyfqqf2y44z507byfxnmijx"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan '(("gleam" "bin/gleam"))))
    (supported-systems '("x86_64-linux"))
    (synopsis "Friendly language for building type-safe, scalable systems")
    (description
     "Gleam is a friendly language for building type-safe, scalable systems!
It compiles to Erlang and JavaScript, and has a robust type system, a powerful
build tool, and excellent tooling.")
    (home-page "https://gleam.run")
    (license license:asl2.0)))

(define-public zig
  (package
    (name "zig")
    (version "0.17.0-dev.305+bdfbf432d")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://ziglang.org/builds/zig-x86_64-linux-" version ".tar.xz"))
       (sha256
        (base32 "0fh3gjpp7nyyad4wxjj4m3y5fi67cwhv99vkv4chv9m85r4gfffz"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan
       '(("." "share/zig/"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'symlink-bin
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin")))
               (mkdir-p bin)
               (symlink (string-append out "/share/zig/zig")
                        (string-append bin "/zig"))))))))
    (supported-systems '("x86_64-linux"))
    (synopsis "General-purpose programming language and toolchain")
    (description
     "Zig is a general-purpose programming language and toolchain for
maintaining robust, optimal, and reusable software.  It is also a drop-in
C/C++ compiler that supports cross-compilation out of the box.")
    (home-page "https://ziglang.org")
    (license license:expat)))

(define-public zig-zls
  (package
    (name "zig-zls")
    (version "0.17.0-dev.37+e4bfcd4a")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://builds.zigtools.org/zls-x86_64-linux-"
             version ".tar.xz"))
       (sha256
        (base32 "18g7q5p0brgnwpcwrjj851m2ms2gmix2yqry40ksd37pka0d27df"))))
    (build-system copy-build-system)
    (arguments
     '(#:install-plan '(("zls" "bin/zls"))))
    (supported-systems '("x86_64-linux"))
    (synopsis "Zig Language Server")
    (description
     "ZLS is a language server for Zig, providing features such as code
completion, go-to-definition, diagnostics, and refactoring for editors that
support the Language Server Protocol.")
    (home-page "https://github.com/zigtools/zls")
    (license license:expat)))

(define-public awscli
  (package
    (name "awscli")
    (version "2.33.6")
    (source
     (origin
       (method url-fetch)
       (uri "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip")
       (sha256
        (base32 "042j45yshsq77hrfh9n4f6agyhabcsvb7lhyckfrk4220ydrsyp2"))))
    (build-system binary-build-system)
    (arguments
     '(#:validate-runpath? #f
       #:patchelf-plan
       '(("aws" ())
         ("aws_completer" ()))
       #:install-plan
       '(("." "bin/"))
       #:phases
       (modify-phases %standard-phases
         (replace 'unpack
           (lambda* (#:key inputs #:allow-other-keys)
             (invoke "unzip" (assoc-ref inputs "source"))
             (chdir "aws/dist")))
         (add-after 'patchelf 'set-rpath
           (lambda _
             (for-each (lambda (bin)
                         (invoke "patchelf" "--set-rpath" "$ORIGIN" bin))
                       '("aws" "aws_completer")))))))
    (native-inputs (list unzip))
    (synopsis "Official Amazon AWS command-line interface")
    (description
     "The AWS Command Line Interface (CLI) is a unified tool to manage your
AWS services from the command line.")
    (home-page "https://aws.amazon.com/cli/")
    (license license:asl2.0)))
