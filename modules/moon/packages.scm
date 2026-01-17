(define-module (moon packages)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module (nonguix build-system binary)
  #:use-module ((guix licenses) #:select (expat gpl3+))
  #:use-module ((nonguix licenses) #:select (nonfree)))

;; https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.11/linux-x64-musl/claude
(define-public claude-cli
  (package
   (name "claude-cli")
   (version "2.1.11")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/"
                  version "/linux-x64-musl/claude"))
            (sha256 (base32 "0r8hwxswgaidjrmz9b7yv6baa915bkdd6w602x8l1r9w13vbm54i"))))
   (build-system binary-build-system)
   (arguments
    (list
     #:validate-runpath? #f
     #:strip-binaries? #f
     #:install-plan #~'(("claude" "bin/claude"))
     #:phases
     #~(modify-phases %standard-phases
		      (replace 'unpack
			       (lambda* (#:key source #:allow-other-keys)
				 (copy-file source "claude")
				 (chmod "claude" #o755))))))
   (inputs (list `(,gcc "lib") glibc))
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
