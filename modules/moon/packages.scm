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
  #:use-module (gnu packages commencement))

(define-public claude-cli
  (package
    (name "claude-cli")
    (version "2.1.11")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/"
                    version "/linux-x64/claude"))
              (sha256 (base32 "0qz2zvz56cmwfh6i2c94qh1wsh9xqny021ikhafg3vsz7mhwqycx"))))
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

(define-public github-cli
  (package
    (name "github-cli")
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
       #:patchelf-plan '()
       #:install-plan
       '(("." "lib/aws-cli/"))
       #:phases
       (modify-phases %standard-phases
         (replace 'unpack
           (lambda* (#:key inputs #:allow-other-keys)
             (invoke "unzip" (assoc-ref inputs "source"))
             (chdir "aws/dist")))
         (add-after 'install 'patch-binaries
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (lib (string-append out "/lib/aws-cli"))
                    (ld-linux (string-append (assoc-ref inputs "libc")
                                             "/lib/ld-linux-x86-64.so.2")))
               (for-each (lambda (binary)
                           (invoke "patchelf" "--set-interpreter" ld-linux binary)
                           (invoke "patchelf" "--set-rpath" lib binary))
                         (list (string-append lib "/aws")
                               (string-append lib "/aws_completer"))))))
         (add-after 'patch-binaries 'create-symlinks
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin"))
                    (lib (string-append out "/lib/aws-cli")))
               (mkdir-p bin)
               (symlink (string-append lib "/aws") (string-append bin "/aws"))
               (symlink (string-append lib "/aws_completer") (string-append bin "/aws_completer"))))))))
    (native-inputs (list unzip patchelf))
    (inputs (list glibc))
    (synopsis "Official Amazon AWS command-line interface")
    (description
     "The AWS Command Line Interface (CLI) is a unified tool to manage your
AWS services from the command line.")
    (home-page "https://aws.amazon.com/cli/")
    (license license:asl2.0)))
