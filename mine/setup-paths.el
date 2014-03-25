;;; setup-paths.el --- Setup load-path, exec-path, info-path, Environment Paths, etc.
;; Author: Per Nordlöw

;; Note: *APPEND* my directorys to prevent from overriding Emacs
;; default libraries.

;; Note: Skipping this! Functionality sucks!
;;(add-to-load-path (elsub "vtags")) ;prepend to override standard etags.el

;; ===========================================================================

;; Note: Put this before (elsub "others") because it
;; should always be uptodate by icicle-download-wizard

(prepend-to-load-path (elsub "flymake"))

(append-to-load-path "~/elisp")            ;Note: my sources before other stuff
(append-to-load-path (elsub "mine"))             ;Note: my sources before other stuff
(append-to-load-path (elsub "edb"))                    ;EDB
(append-to-load-path (elsub "emacs-wget"))                   ;emacs-wget

(append-to-load-path (elsub "htmlfontify"))   ;htmlfontify

(append-to-load-path (elsub "speck"))         ;speck
(append-to-load-path (elsub "ebnf2ps"))             ;ebnf2ps

(append-to-load-path "~/.emacs.d")          ;my compiled stuff

(append-to-load-path (elsub "company"))

(append-to-load-path (elsub "ga"))
(append-to-load-path (elsub "eproject"))

;; See: http://www.emacswiki.org/emacs/TinyTools
(append-to-load-path (elsub "tiny-tools/lisp/other"))
(append-to-load-path (elsub "tiny-tools/lisp/tiny"))
(append-to-load-path (elsub "tiny-tools/bin"))
(append-to-load-path (elsub "mk-project"))
(append-to-load-path (elsub "babel-dev"))
(append-to-load-path (elsub "clookup"))

(append-to-load-path (elsub "slime"))
(append-to-load-path (elsub "gist"))
(append-to-load-path (elsub "mv-shell"))
(append-to-load-path (elsub "hideshow-org"))
(append-to-load-path (elsub "el-get"))
(append-to-load-path (elsub "fill-column-indicator"))
(append-to-load-path (elsub "s-x-emacs-werkstatt"))

(append-to-load-path (elsub "popup-el")) ;WARNING: Takes over auto-complete's version!

(append-to-load-path (elsub "nakkay/int"))

(append-to-load-path (elsub "emacs-oauth"))
(append-to-load-path (elsub "google-contacts"))

;;(append-to-load-path (elsub "~/elisp/magic"))
(append-to-load-path (elsub "dvc/build"))
(append-to-load-path (elsub "git-emacs"))

(append-to-load-path (elsub "gitconfig-mode/"))
(append-to-load-path (elsub "auto-highlight-symbol-mode/"))
(append-to-load-path (elsub "auto-pair/"))
(append-to-load-path (elsub "mocker/"))
(append-to-load-path (elsub "ucs-utils/"))
(append-to-load-path (elsub "buffer-utils/"))
(append-to-load-path (elsub "string-utils/"))
(append-to-load-path (elsub "font-utils/"))
(append-to-load-path (elsub "list-utils/"))
(append-to-load-path (elsub "back-button/"))
(append-to-load-path (elsub "anaphora/"))
(append-to-load-path (elsub "alert/"))
(append-to-load-path (elsub "nav-flash/"))
(append-to-load-path (elsub "vector-utils/"))
(append-to-load-path (elsub "button-lock/"))
(append-to-load-path (elsub "browse-url-dwim/"))
(append-to-load-path (elsub "dynamic-fonts/"))
(append-to-load-path (elsub "flyspell-lazy/"))
(append-to-load-path (elsub "hippie-namespace/"))
(append-to-load-path (elsub "ido-load-library/"))
(append-to-load-path (elsub "unicode-enbox/"))
(append-to-load-path (elsub "unicode-whitespace/"))
(append-to-load-path (elsub "unicode-progress-reporter/"))
(append-to-load-path (elsub "minimal-session-saver/"))
(append-to-load-path (elsub "emacs-color-theme-solarized/"))
(append-to-load-path (elsub "pcache/"))
(append-to-load-path (elsub "hardhat/"))
(append-to-load-path (elsub "persistent-soft/"))
(append-to-load-path (elsub "ignoramus/"))
(append-to-load-path (elsub "truthy/"))
(append-to-load-path (elsub "multiple-line-edit/"))
(append-to-load-path (elsub "emacs-async/"))
(append-to-load-path (elsub "syntactic-sugar/"))
(append-to-load-path (elsub "smooth-scroll/"))
(append-to-load-path (elsub "double-type/"))
(append-to-load-path (elsub "linear-undo/"))


(append-to-load-path (elsub "others"))       ;other sources

;;; Note: Alternative way of doing it.
(when nil
  (let ((default-directory (elsub "others")))
    (normal-top-level-add-to-load-path '("emms"
                                         "erc"
                                         "planner"
                                         "w3"))))

(prepend-to-load-path (elsub "miscbits-el"))  ;override stuff in ~/elisp

;;; ===========================================================================
;;; Environment Paths

(setq elisp-depend-directory-list '("~/alt/share/emacs/"))

;; Path used in function executable-find
(append-to-exec-path "/usr/local/bin") ;Standard locally built packages.
(append-to-exec-path "/sw/bin")      ;Fink (on Max OS X) packages.
(append-to-exec-path "/opt/csw/bin") ;Solaris packages.
(prepend-to-exec-path (expand-file-name "~/alt/bin") t) ;My Stuff.

;; Path used in function shell-command
(setenv "PATH" (concat (expand-file-name "~/alt/bin:")
                       "/usr/local/bin:"
                       "/opt/csw/bin:"
                       "/sw/bin:"
                       (getenv "PATH")))

;; Path used in function `shell-command' and others.
(setenv "LD_LIBRARY_PATH" (concat (expand-file-name "~/alt/lib") ":"
                                  "/usr/local/lib" ":"
                                  (getenv "LD_LIBRARY_PATH")))

(setenv "MANPATH"
        (concat "~/alt/share/man:"
                "~/alt/man:"
                "/usr/local/share/man:"
                "/usr/share/man:"
                (getenv "MANPATH")))

(setenv "INFOPATH"
        (concat (elsub "ecb/info-help:")
                (elsub "magit:")
                (elsub "info:")
                (elsub "contrib/cedet/semantic/doc:")
                (elsub "contrib/cedet/ede/doc:")
                "~/alt/share/info:"
                "~/alt/info:"
                "/usr/local/share/info:"
                "/usr/local/info:"
                (getenv "INFOPATH")))

;;; ===========================================================================

;; FOI Proxy Settings
(setq host-is-foi
      (or (equal (string-match "buddha" (shell-command-to-string "hostname")) 0)
          (equal (string-match "haiku" (shell-command-to-string "hostname")) 0))
      )
(when host-is-foi
  (defvar foi-proxy-host "www-gw.foi.se")
  (defvar foi-proxy-port "8080")

  (defvar pnw/http_proxy (concat "http://" foi-proxy-host ":" foi-proxy-port))
  (defvar pnw/ftp_proxy (concat "ftp://" foi-proxy-host ":" foi-proxy-port))

  (when (boundp 'http-proxy-host) (setq http-proxy-host foi-proxy-host))
  (when (boundp 'http-proxy-port) (setq http-proxy-port foi-proxy-port))

  (setenv "http_proxy" pnw/http_proxy)
  (setenv "ftp_proxy" pnw/ftp_proxy)
  )

;;; ===========================================================================

;;; GNU Info Settings

;; Add bzip2 suffixes to info reader.
;;(XEmacs
;; (require 'info)
;; (setq Info-suffix-list
;;       (append '(
;;               (".info.bz2" . "bzip2 -dc %s")
;;               (".bz2"      . "bzip2 -dc %s")
;;               )
;;             Info-suffix-list)))

(progn
  (add-to-list 'Info-default-directory-list (expand-file-name "/usr/local/teTeX/info/"))
  (add-to-list 'Info-default-directory-list (expand-file-name "/usr/freeware/info/"))

  ;; CEDET Info Paths
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/ede/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/cogre/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/eieio/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/tests/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/speedbar/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/common/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/semantic/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/semantic/bovine")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/semantic/doc/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/semantic/symref/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/ede/doc/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/srecode/doc/")))
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "cedet/srecode/")))

  ;; ECB Info Paths
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "ecb/info-help/")))

  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "vhdl-mode/")))

  ;; Note: My separate info direction-reversed for CEDET.
  (add-to-list 'Info-default-directory-list (expand-file-name (elsub "info")))

  ;; Note: My local builds.
  (add-to-list 'Info-default-directory-list (expand-file-name "~/alt/info"))
  (add-to-list 'Info-default-directory-list (expand-file-name "~/alt/share/info"))

  (setq Info-directory-list Info-default-directory-list)
  )

;;; Search all Info indices
;; (when (require 'info-apropos nil t)
;;   )

(provide 'setup-paths)
