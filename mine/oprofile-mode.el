;;; oprofile-mode.el -- GNU Emacs major mode (only font-locking) for oprofile output

(require 'oprofile)

(defvar oprofile-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\es" 'center-line)
    map)
  "Major mode keymap for `oprofile-mode'.")

;; Main
(defface oprofile-mode-main-face
  '((t (:inherit font-lock-function-name-face :bold t)))
  "*Face used to highlight main line in oprofile."
  :group 'oprofile)
(defvar oprofile-mode-main-face 'oprofile-mode-main-face)

(defconst oprofile-mode-font-lock-keywords
  (progn
    (require 'font-lock)
    (list
     ;; Function Names
     (list (concat
	    "^ "			;line begins with a space
	    ".*" " "
	    "\\(" "[[:alnum:]_]+" "\\)" "$")
	   1 'font-lock-function-name-face)
     (list (concat
	    "^ "			;line begins with a space
	    ".*" " "
	    "\\(" "[[:alnum:]_]+" "\\)" " "
	    "\\[" "self" "\\]" "$")
	   1 'font-lock-function-name-face)
     (list (concat
	    "^[[:digit:]]"			;line begins with a number
	    ".*" " "
	    "\\(" "[[:alnum:]_]+" "\\)" "$")
	   1 'oprofile-mode-main-face)
     ))
  "Expressions to font-lock in Operators mode.")

(defcustom oprofile-mode-hook nil
  "Hook run by function `oprofile-mode'."
  :type 'hook
  :group 'oprofile)

;;;###autoload
(define-derived-mode oprofile-mode text-mode "Profile (oprofile)"
  "Major mode for font locking of oprofile output.
\\{oprofile-mode-map}
Turning on Operators mode runs `text-mode-hook', then `oprofile-mode-hook'."
  (use-local-map oprofile-mode-map)
  (set (make-local-variable 'font-lock-defaults) '(oprofile-mode-font-lock-keywords))
  (setq buffer-read-only t)
  )

;; Always switch to text mode for filenames that
(add-to-list 'auto-mode-alist '("\.opreport\\'" . oprofile-mode))
(add-to-list 'auto-mode-alist '("\.oprofile\\'" . oprofile-mode))

(provide 'oprofile-mode)
