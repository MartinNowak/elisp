;;; pgo-elisp-tools.el --- Setup Emacs Lisp Development Tools.
;; Author: Per Nordlöw

;; install-elisp.el --- Simple Emacs Lisp installer
;; See: http://www.emacswiki.org/cgi-bin/emacs/install-elisp.el
;; WARNING: Removed because it makes it impossible to compile and load anything.
(when nil
  (when (require 'install-elisp nil t)
    (setq install-elisp-repository-directory (elsub "others"))
    (require 'require-or-install nil t)
    ))

;; elisp-depend.el --- Parse depends library of elisp file.
(when (require 'elisp-depend nil t)
  )

;; If some package have not "provide" sentences, use
;; (autoload 'foo "bar") format load some features.
;; Otherwise use (require 'foo) to load features.
;;
;; Below are commands you can use:
;;
;; `elisp-depend-insert-require'        insert depends code.
;; `elisp-depend-insert-comment'        insert depends comment.
;; elisp-format.el
(when (require 'elisp-format nil t)
  )

(provide 'pgo-elisp-tools)
