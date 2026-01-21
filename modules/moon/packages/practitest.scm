(define-module (moon packages practitest)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages rails) 
  #:use-module (gnu packages ruby-check)
  #:use-module (gnu packages java)
  #:use-module (gnu packages ruby-xyz)
  #:use-module (guix build-system ruby)
  #:use-module (guix build-system copy)
  #:use-module (gnu packages readline) 
  #:use-module (nonguix build-system binary)
  #:use-module (guix download)
  #:use-module (guix gexp) 
  #:use-module (gnu packages web)
  #:use-module (guix build utils)	;
  #:use-module (gnu packages erlang)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages base)
  #:use-module (gnu packages pkg-config)
  #:use-module (nongnu packages clojure)
  #:use-module (gnu packages clojure)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages serialization))

(define-public ruby-pt
  (package
    (inherit ruby)
    (name "ruby-pt") 
    (version "3.2.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                     "https://cache.ruby-lang.org/pub/ruby/3.2/ruby-" version ".tar.xz"))
              (sha256
               (base32 "08wy2ishjwbccfsrd0iwmyadbwjzrpyxnk74wcrf7163gq7jsdab"))))))

(define-public bundler-pt
  (package
    (inherit bundler)
    (name "bundler-pt")
    (version "2.5.5")
    (source (origin
              (method url-fetch)
              (uri (rubygems-uri "bundler" version))
              (sha256
               (base32
                "0qm4h2h06mcbx4xxnjfnrrsgdbh1zzg0ck35590adqihj0kgxiqk"))))
    (arguments 
     (list #:tests? #f 
           #:ruby ruby-pt))))

(define-public bundler-configured
  (package
    (inherit bundler-pt)    ; Start with the specific version above
    (name "bundler-configured")
    (inputs (list libxml2 libxslt tzdata postgresql))
    (native-search-paths
     (list (search-path-specification
	     (variable "LD_LIBRARY_PATH")
	     (files '("lib")))))
    
    (arguments
     (list
      #:tests? #f
      #:ruby ruby-pt
      #:phases
      #~(modify-phases %standard-phases
          ;; We add the wrapper phase here, effectively "configuring" the resulting binary
          (add-after 'install 'wrap-bundler-config
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin/bundle"))
                     (libxml2-path (assoc-ref inputs "libxml2"))
		     (postgresql-lib (string-append (assoc-ref inputs "postgresql") 
                                                    "/lib"))
                     (tzdata-path (string-append (assoc-ref inputs "tzdata") 
                                                 "/share/zoneinfo")))
                
                (unless (file-exists? bin)
                  (error "Bundle binary not found!"))
		
                (wrap-script bin
                  `("BUNDLE_BUILD__NOKOGIRI" =
                    (,(string-append "--with-xml2-dir=" libxml2-path)))
                  `("BUNDLE_PATH" = ("vendor/bundle"))
                  `("TZDIR" = (,tzdata-path)))))))))))



(define-public babashka-moon
  (package/inherit babashka
		   (name "babashka-moon")
		   (arguments
		    (list
		     #:patchelf-plan
		     ''(("bb" ("zlib")))
		     #:install-plan
		     ''(("bb" "/bin/"))))))

(define-public clojure-tools-moon
  (package
   (name "clojure-tools-moon")
   (version "1.12.4.1582")
   (source
    (origin
     (method url-fetch)
     (uri (string-append "https://download.clojure.org/install/clojure-tools-"
                         version
                         ".tar.gz"))
     (sha256 (base32 "08gzfblnz0zhnk6pwr9vcm6y168psgrwmqww3wqk1v7j5gr68n7x"))))
   (build-system copy-build-system)
   (arguments
    `(#:install-plan
      `(("deps.edn" "lib/clojure/")
        ("example-deps.edn" "lib/clojure/")
        ("tools.edn" "lib/clojure/")
        ("exec.jar" "lib/clojure/libexec/")
        (,(string-append "clojure-tools-" ,version ".jar")
         "lib/clojure/libexec/clojure-tools.jar")
        ("clojure" "bin/")
        ("clj" "bin/"))
      #:phases
      (modify-phases
       %standard-phases
       (add-after 'unpack 'fix-paths
		  (lambda* (#:key inputs outputs #:allow-other-keys)
		    (let* ((out (assoc-ref outputs "out"))
			   (lib (string-append out "/lib/clojure"))
			   (libexec (string-append lib "/libexec")))
		      ;; Add JVM args for jdk.compiler module access (needed by orchard/CIDER)
		      (substitute*
		       "clojure"
		       (("PREFIX") lib)
		       (("\\$install_dir/libexec/clojure-tools-\\$version\\.jar")
			(string-append libexec "/clojure-tools.jar"))
		       (("exec java")
			(string-append "exec java "
				       "--add-modules=ALL-SYSTEM "
				       "--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED "
				       "--add-exports=jdk.compiler/com.sun.source.doctree=ALL-UNNAMED "
				       "--add-exports=jdk.compiler/com.sun.source.tree=ALL-UNNAMED "
				       "--add-exports=jdk.compiler/com.sun.source.util=ALL-UNNAMED "
				       "--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED "
				       "--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED "
				       "--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED")))
		      (substitute*
		       "clj"
		       (("BINDIR") (string-append out "/bin"))
		       (("rlwrap") (search-input-file inputs "/bin/rlwrap")))))))))
   (inputs (list rlwrap))
   (propagated-inputs (list clojure clojure-tools-deps))
   (home-page "https://clojure.org/releases/tools")
   (synopsis "CLI tools for the Clojure programming language")
   (description "The Clojure command line tools can be used to start a
Clojure repl, use Clojure and Java libraries, and start Clojure programs.")
   (license license:epl1.0)))

(define-public ruby-lsp
  (package
    (name "ruby-lsp")
    (version "0.26.4")
    (source
     (origin
       (method url-fetch)
       (uri (rubygems-uri "ruby-lsp" version))
       (sha256
        (base32 "1xx96yfi5aqm1d3aps2nl5mls0vnm8xwvw75vy1ik3vc0rm09cqw"))))
    (build-system ruby-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          ;; This is the Magic Fix:
          (add-after 'install 'remove-gemfile
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((out (assoc-ref outputs "out")))
                ;; We recursively find any file named "Gemfile" or "Gemfile.lock" 
                ;; inside the installation directory and delete it.
                ;; This forces the app to rely on the system (Guix) GEM_PATH.
                (for-each delete-file
                          (find-files out "^Gemfile"))))))))
    
    ;; 1. Tools needed ONLY for building/compiling (not needed at runtime)
    (native-inputs 
     (list gcc-toolchain 
           gnu-make 
           pkg-config))

    ;; 2. Libraries needed at runtime (The dependencies of ruby-lsp)
    ;; Note: 'ruby' is implicit in ruby-build-system, but valid to keep.
    (propagated-inputs 
     (list libyaml
           ruby-io-console
           ruby-date 
           ruby-reline 
           ruby-language-server-protocol 
           ruby-prism))

    (synopsis "An opinionated language server for Ruby")
    (description "An opinionated language server for Ruby.")
    (home-page "https://github.com/Shopify/ruby-lsp")
    (license license:expat)))

(define-public ruby-lsp-rails
  (package
   (name "ruby-lsp-rails")
   (version "0.4.8")
   (source
    (origin
     (method url-fetch)
     (uri (rubygems-uri "ruby-lsp-rails" version))
     (sha256
      (base32 "1bj4bj35l9jas2yf6w93j5ngw3f24lck2j9h5zmxwqs0dn91z7gh"))))
   (build-system ruby-build-system)
   (propagated-inputs (list ruby-lsp))
   (native-inputs
    (list ruby-rake
          ruby-minitest))
   (arguments
     (list
      ;; Disable tests so we don't need rails/railties loaded
      #:tests? #f))
   (synopsis
    "A Ruby LSP addon that adds extra editor functionality for Rails applications")
   (description
    "This package provides a Ruby LSP addon that adds extra editor functionality for
Rails applications.")
   (home-page "https://github.com/Shopify/ruby-lsp-rails")
   (license license:expat)))

;; (define-public ruby-lsp
;;   (package
;;    (name "ruby-lsp")
;;    (version "0.26.4")
;;    (source
;;     (origin
;;      (method url-fetch)
;;      (uri (rubygems-uri "ruby-lsp" version))
;;      (sha256
;;       (base32 "1xx96yfi5aqm1d3aps2nl5mls0vnm8xwvw75vy1ik3vc0rm09cqw"))))
;;    (build-system ruby-build-system)
;;    (arguments
;;     '(#:tests? #f))
;;    (native-inputs 
;;     (list ))
;;    (propagated-inputs (list ruby-io-console ruby-date ruby-reline ruby libyaml ruby-language-server-protocol ruby-prism
;; 			    gcc-toolchain gnu-make pkg-config))
;;    (synopsis "An opinionated language server for Ruby")
;;    (description "An opinionated language server for Ruby.")
;;    (home-page "https://github.com/Shopify/ruby-lsp")
;;    (license license:expat)))


(define-public erlang-no-wx
  (package
    (inherit erlang)
    (name "erlang-no-wx")
    (inputs
     (modify-inputs (package-inputs erlang)
		    (delete "wxwidgets")))))




