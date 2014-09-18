;;; alert-tags.el --- Syntax Highlight Special Comment Tags.
;;; Commentary:
;;; Author: Per Nordlöw
;;; Code:

(defgroup alert-tags nil
  "Alert-Tags."
  :group 'font-lock
  :prefix "alert-tags-")

(defface font-lock-note-face		;note
  '((((class color) (background dark)) (:foreground "lightgreen" :background "gray32" :bold t))
    (((class color) (background light)) (:foreground "Yellow" :background "gray64" :bold t))
    (t ()))
  "Font Lock mode face used to highlight note tags."
  :group 'alert-tags)

(defface font-lock-warn-face		;warn
  '((((class color) (background dark)) (:foreground "gold1" :background "gray32" :bold t))
    (((class color) (background light)) (:foreground "Orange" :background "gray64" :bold t))
    (t ()))
  "Font Lock mode face used to highlight warn tags."
  :group 'alert-tags)

(defface font-lock-alert-face		;alert
  '((((class color) (background dark)) (:foreground "#ff6060" :background "gray32" :bold t))
    (((class color) (background light)) (:foreground "Red" :background "gray64" :bold t))
    (t ()))
  "Font Lock mode face used to highlight alert tags."
  :group 'alert-tags)
:
(defconst note-tags
  '(
    "ReadMe" "README"
    "Install" "INSTALL"

    ;; In English
    "FixMe" "FIXME"
    "ToDo" "TODO"
    "Test" "TEST"
    "Note" "NOTE"
    "See" "SEE"
    "Obs" "OBS"
    "Observe" "OBSERVE"

    "Nota_bene" "Nota_BENE"
    "EXAMPLE" "Example"
    "EXAMPLES" "Examples"
    "USAGE" "Usage"
    "USE" "Use"
    )
  "Special Tags/Words mainly used in source code comments to note the user.")

(defconst warn-tags
  '(
    "WARNING" "Warning"
    "IMPORTANT" "Important"
    "VARNING" "Varning"
    "TOREVIEW" "ToReview"
    )
  "Special Tags/Words mainly used in source code comments to warn the user.")


(defconst alert-tags
  '(
    "Error" "ERROR"
    "Fel" "FEL"
    "Alert" "ALERT"
    "Panic" "PANIC"
    "Bug" "BUG"
    )
  "Special Tags/Words mainly used in source code comments to alert the user.")

;; ToDo: Use only inside comments!
(defun alert-tags-font-locking ()
  "Activate font-locking of alert-tags."
  (font-lock-add-keywords
   nil
   (list
    (cons (concat "\\<"
                  "@\?" "\\(" (regexp-opt note-tags) "?" "\\)"
                  "@\?" "\\(" (regexp-opt warn-tags) "?" "\\)"
                  "@\?" "\\(" (regexp-opt alert-tags) "?" "\\)"
                  "\\>"
                  ":[^:]"
                  )
          '((1 'font-lock-note-face prepend)
            (2 'font-lock-warn-face prepend)
            (3 'font-lock-alert-face prepend)
            )))))

;; all modes for now
;; WARNING: This ruins icicles highlighting. DONT USE!
;; (add-hook 'after-change-major-mode-hook 'alert-tags-font-locking t)
;; (remove-hook 'after-change-major-mode-hook 'alert-tags-font-locking)

(add-hook 'prog-mode-hook 'alert-tags-font-locking t)
(add-hook 'text-mode-hook 'alert-tags-font-locking t)
(add-hook 'outline-mode-hook 'alert-tags-font-locking t)
(add-hook 'org-mode-hook 'alert-tags-font-locking t)
(add-hook 'tex-mode-hook 'alert-tags-font-locking t)
(add-hook 'latex-mode-hook 'alert-tags-font-locking t)
(add-hook 'emacs-lisp-mode-hook 'alert-tags-font-locking t)
(add-hook 'sh-mode-hook 'alert-tags-font-locking t)
(add-hook 'c-mode-common-hook 'alert-tags-font-locking t)
(add-hook 'python-mode-hook 'alert-tags-font-locking t)
(add-hook 'ruby-mode-hook 'alert-tags-font-locking t)
(add-hook 'scons-mode-hook 'alert-tags-font-locking t)
(add-hook 'ada-mode-hook 'alert-tags-font-locking t)
(add-hook 'd-mode-hook 'alert-tags-font-locking t)
(add-hook 'octave-mode-hook 'alert-tags-font-locking t)
(add-hook 'matlab-mode-hook 'alert-tags-font-locking t)
(add-hook 'makefile-mode-hook 'alert-tags-font-locking t)
(add-hook 'jam-mode-hook 'alert-tags-font-locking t)
(add-hook 'autoconf-mode-hook 'alert-tags-font-locking t)

;; Highlight GCC Attribute Arguments.
(defun emacs-lisp-header-font-locking ()
  "Emacs Lisp Comment Header."
  (list
   (cons (concat "^;; Version: \\(" "[0-9.]+" "\\)$")
         '(1 'font-lock-note-face t))
   ))

(add-hook 'emacs-lisp-mode-hook 'emacs-lisp-header-font-locking t)

(provide 'alert-tags)
;;; alert-tags.el ends here
