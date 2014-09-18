;;; alert-tags.el --- Syntax Highlight Special Comment Tags.
;;; Commentary:
;;; Author: Per Nordlöw
;;; TODO Restrict matching to comments only.
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

(defconst note-tags
  '("README" "INSTALL" "FIXME" "TODO" "TEST")
  "Special tags/words mainly used in source code comments to note the user.")

(defconst warn-tags
  '("WARNING" "IMPORTANT" "VARNING" "TOREVIEW")
  "Special Tags/Words mainly used in source code comments to warn the user.")


(defconst alert-tags
  '("ERROR" "FEL" "ALERT" "PANIC" "BUG")
  "Special Tags/Words mainly used in source code comments to alert the user.")

;; ToDo Use only inside comments!
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
                  ;; ":[^:]"
                  )
          '((1 'font-lock-note-face prepend)
            (2 'font-lock-warn-face prepend)
            (3 'font-lock-alert-face prepend)
            )))))

;; all modes for now
;; WARNING This ruins icicles highlighting. DONT USE!
;; (add-hook 'after-change-major-mode-hook 'alert-tags-font-locking t)
;; (remove-hook 'after-change-major-mode-hook 'alert-tags-font-locking)

(dolist (mode '(prog-mode-hook
                text-mode-hook
                outline-mode-hook
                org-mode-hook
                tex-mode-hook
                latex-mode-hook
                emacs-lisp-mode-hook
                sh-mode-hook
                c-mode-common-hook
                python-mode-hook
                ruby-mode-hook
                scons-mode-hook
                ada-mode-hook
                d-mode-hook
                octave-mode-hook
                matlab-mode-hook
                makefile-mode-hook
                jam-mode-hook
                autoconf-mode-hook))
  (add-hook mode 'alert-tags-font-locking t))

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
