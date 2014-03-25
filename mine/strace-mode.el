;;; strace-mode.el -- Mode (only font-locking) for strace output.
;; Copyright (C) 2007 by Per Nordlöw

(provide 'strace-mode)

(require 'path-utils)
(require 'font-lock)
(require 'font-lock-extras)
(require 'coolock)

(defgroup strace-mode nil
  "Strace mode."
  :group 'wp
  :prefix "strace-")

(defvar strace-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\es" 'center-line)
    map)
  "Major mode keymap for `strace-mode'.")

;; Main
(defface strace-mode-main-face
  '((t (:inherit font-lock-function-name-face :bold t)))
  "*Face used to highlight main line in strace."
  :group 'strace-mode-mode)
(defvar strace-mode-main-face 'strace-mode-main-face)

(defconst strace-mode-font-lock-keywords nil
  "Expressions to font-lock in Operators mode.")
(setq strace-mode-font-lock-keywords
      (append
       (list
        (cons "\\(\".*\"\\)"
              '((1 'font-lock-string-face t)
                ))
        (cons (concat
               "\\(\\(?:" "[0-9]+:[0-9]+:[0-9]+\.[0-9]+ " "\\)?\\)"                 ;optional timestamp

               "\\(" "[[:alnum:]_]+" "\\)" " *" ;function call
               "(" " *" ".*" " *" ")" " *" ;arguments
               "\\(=\\)"                   ;return value equal sign
               " *"
               "\\(?:" "\?" "\\|" "[\-\+]*" "\\|" "-?" "\\(?:0x\\)?" "[[:xdigit:]]*" "\\)"
               " *"
               "\\(" W* "\\)"           ;constant
               " *"
               "\\(" "\\(?:" "(" ".*" ")" "\\)?" "\\)" ;doc
               " *" "$"
               )
              '((1 'font-lock-time-face t)
                (2 'font-lock-function-call-face t) ;TODO: Add button to "man:ls".
                (3 'font-lock-operator-assignment-face t)
                (4 'font-lock-constant-face t)
                (5 'font-lock-comment-face t)
                ))
        (cons "\\(NULL\\)"
              '((1 'font-lock-constant-face append)
                ))
        (cons (concat "\\(" "[[:alnum:]_]+" "\\)=")
              '((1 'font-lock-variable-name-face append)
                )))
       (coolock/c-number)
))

(defcustom strace-mode-hook nil
  "Hook run by function `strace-mode'."
  :type 'hook
  :group 'strace-mode)

(defun browse-man-page-at-mouse ()
  (interactive)
  (man (concat (tap-non-nil-symbol-name-at-point) "(2)")))

;;;###autoload
(define-derived-mode strace-mode comint-mode "Trace (strace)"
  "Major mode for font locking of strace output.
\\{strace-mode-map}
Turning on Operators mode runs `text-mode-hook', then `strace-mode-hook'."
  (use-local-map strace-mode-map)
  (set (make-local-variable 'font-lock-defaults) '(strace-mode-font-lock-keywords))
  (when (and (append-to-load-path (elsub "button-lock"))
             (require 'button-lock nil t))
    (button-lock-mode 1)
    (button-lock-set-button " \\([a-zA-Z_]+\\)(" 'browse-man-page-at-mouse))
  ;;(setq buffer-read-only t)
  )

(add-to-list 'auto-mode-alist '("\\.strace\\'" . strace-mode))
