(define-module (moon packages)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (nonguix build-system binary)
  #:use-module ((nonguix licenses) #:prefix license:))

(define-public claude-cli
  (package
   (name "claude-cli")
   (version "2.0.67")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/"
                  version "/linux-x64-musl/claude"))
            (sha256 (base32 "1wr6cxrf608z22adhjwvx1rinxyv3rbjls00j3si8f6zsmwj58dj"))))
   (build-system binary-build-system)
   (arguments
    (list
     #:validate-runpath? #f
     #:strip-binaries? #f
     #:install-plan #~'(("claude" "bin/claude"))
     #:patchelf-plan #~'(("claude" ()))
     #:phases
     #~(modify-phases %standard-phases
		      (replace 'unpack
			       (lambda* (#:key source #:allow-other-keys)
				 (copy-file source "claude")
				 (chmod "claude" #o755))))))
   (supported-systems '("x86_64-linux"))
   (synopsis "Claude Code CLI from Anthropic")
   (description "AI-powered coding assistant for the terminal.")
   (home-page "https://docs.anthropic.com/en/docs/claude-code")
   (license (license:nonfree "https://www.anthropic.com/legal/consumer-terms"))))
