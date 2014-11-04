;;; eload.el --- Auto-recompilation of feature sources before requiring.
;; Author: Per Nordlöw
;; byte-code-cache.el --- Compile files as they're used
;; Note: This has to be placed in front of all other loads in order
;; to be used as often as possible.
;; See: http://www.emacswiki.org/cgi-bin/wiki/AutoRecompile
(when nil        ;Note: TODO Disabled because it doesn't work with require!
  (when (eload 'byte-code-cache)
    ;; So that we can transfer compiled stuff when we move our installation.
    (setq bcc-cache-directory (elsub "byte-cache"))
    (add-to-list 'bcc-blacklist "/anything-c-adaptive-history$")
    (add-to-list 'bcc-blacklist "/pnw-custom.el$")
    (add-to-list 'bcc-blacklist "!semantic.cache$")
    ))

(require 'power-utils)

(defun eload (feature &optional dir src file-url vc-repos load-flag)
  "Auto-compile FEATURE library source and then require FEATURE if its online.
Build (Install) software SRC in directory DIR optionally first
downloading it from FILE-URL or through VC-REPOS. TODO Merge
with package install-elisp.el and byte-code-cache.el."
  (when dir
    (append-to-load-path dir))
  (or (require feature nil t)
      (progn (warn "Desired feature '%s not available" (faze feature 'const))
             nil)))

(defun auto-compiled-soft-require (feature &optional dir src file-url vc-repos load-flag)
  "Auto-compile FEATURE library source and then require FEATURE if its online.
Build (Install) software SRC in directory DIR (defaulting to
`default-directory') optionally first downloading it from
FILE-URL or through VC-REPOS. TODO Merge with package
install-elisp.el and byte-code-cache.el.
If LOAD-FLAG is 'ask' ask for it."
  (when nil
    (let* ((full-src (or (when src
                           (expand-file-name src (file-name-as-directory (or dir default-directory)))) ;try to use user given
                         (ignore-errors
                           (find-library-name (symbol-name feature))))) ;try to find sources based on `feature'
           (lfull (or                   ;file to load
                   (when (and full-src
                              (file-exists-p full-src)
                              (require 'bytecomp nil t)
                              (let ((dest (strip-file-extension (byte-compile-dest-file full-src) "gz")))
                                (when dest
                                  (if (or (not (file-exists-p dest)) ;either `full-src' hasn't been compiled yet
                                          (file-newer-than-file-p full-src dest)) ;or `full-src' has changed
                                      (when (ignore-errors (byte-compile-file full-src)) dest) ;upon success use `dest'
                                    ;; otherwise `full-src' has already been compiled to `dest' so
                                    dest)))) ;so use that instead
                     )
                   full-src)))
      (append-to-load-path dir)
      (or (require feature nil t)       ;either full-src provides `feature'
          (when lfull
            (case load-flag
              (ask (if (y-or-n-p (concat "Load file " lfull "?"))
                       (load-file lfull)))
              (t (load-file lfull))
              (nil (load-file lfull))   ;default to true
              ))))))
;; Use: (eload 'org-bibtex)
;; Use: (eload 'bookmark+)
;; Use: (eload 'unavailabe-package)
(defalias 'desire 'auto-compiled-soft-require)

(provide 'eload)
