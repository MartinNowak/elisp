;;; pgo-grep.el --- Setup Grep Interface.

;; See: http://www.emacswiki.org/cgi-bin/wiki/GrepPlus
(when nil (eval-after-load "grep" '(require 'grep+ nil t)))

;; grep-a-lot.el --- manages multiple search results buffers for grep.el
;; Warning: Note: Disabled because it errors for me during recompile.
;; (when (require 'grep-a-lot nil t)
;;   (grep-a-lot-setup-keys))

;; grep-o-matic.el --- auto grep word under cursor
(require 'grep-o-matic nil t)

;; grep-ed.el
(require 'grep-ed nil t)

;; repository-root.el --- deduce the repository root directory for a given file
(require 'repository-root nil t)

;; igrep.el --- An improved interface to `grep` and `find`
(when nil (progn (require 'igrep nil t)))

(when (require 'grep nil t)
  (add-to-list 'grep-find-ignored-directories ".deps")
  (add-to-list 'grep-find-ignored-directories "autom4te.cache")
  )

(require 'tgrep nil t)              ;My Own Grep Wrapper

(provide 'pgo-grep)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-grep.el ends here
