;;; show-num.el --- Show Information about Number at Cursor if any.

(require 'faze)
(require 'relangs)

;;; TODO: Reuse relangs/coolock/pnw-regexps
(defun number-literal-message ()
  (when nil
    (when (and (not isearch-mode)
               (not (minibufferp))
               (not (memq major-mode '(dired-mode)))
               )
      (let* ((sym (thing-at-point 'symbol))
             (bin relangs-binary-number)
             (oct relangs-octal-number)
             (hex relangs-hexadecimal-number))
        (when (stringp sym)
          (cond ((string-match "\\`0[bB][01]+\\'" (faze sym 'num))
                 (let ((num (string-to-number (substring sym 2) 2)))
                   (message "Binary Integer %s, Dec:%s, Hex:%s"
                            (faze sym 'num)
                            (faze num 'num)
                            (faze (format "0x%X" num) 'num)))
                 )
                ((string-match "\\`[[:digit:]]+\\'" (faze sym 'num))
                 (let ((num (string-to-number sym)))
                   (message "Decimal Integer %s, Hex:%s"
                            (faze sym 'num)
                            (faze (format "0x%X" num) 'num)))
                 )
                ((string-match "\\`0[oO][0-7]+\\'" (faze sym 'num))
                 (let ((num (string-to-number (substring sym 2) 8)))
                   (message "Octal Integer %s, Dec:%s, Hex:%s" (faze sym 'num)
                            (faze num 'num)
                            (faze (format "0x%X" num) 'num)))
                 )
                ((string-match "\\`0[xX][[:xdigit:]]+\\'" (faze sym 'num))
                 (let ((num (string-to-number (substring sym 2) 16)))
                   (message "Hexadecimal Integer %s, Dec:%s"
                            (faze sym 'num)
                            (faze num 'num)))
                 ))
          )))))

(require 'calc-bin)

(defun number-to-string-in-radix (number base)
  "Convert NUMBER to string in BASE.
See http://stackoverflow.com/questions/10360196/how-to-display-numbers-in-different-bases-under-elisp"
  (let ((calc-number-radix base))
    (math-format-radix number)))
(eval-when-compile (assert-equal (number-to-string-in-radix 10 2) "1010"))

;;; TODO: Ask Drew to fixes tap-thing-at-point so that it fetches also at the
;;; end like eldoc does.
;;; TODO: Reuse relangs/coolock/pnw-regexps
(defun number-literal-message ()
  (when nil
    (unless (or (minibufferp)
                (memq major-mode '(dired-mode)))
      (let ((sym (or (tap-thing-at-point 'sexp)
                     (when (looking-back "[0-9a-zA-Z]")
                       (backward-char)
                       (prog1
                           (tap-thing-at-point 'sexp)
                         (forward-char))))))
        (when (stringp sym)
          (cond ((string-match "\\`0[bB][01]+\\'" (faze sym 'num))
                 (let ((num (string-to-number (substring sym 2) 2)))
                   (message "Binary Integer %s, Dec:%s, Hex:%s"
                            (faze sym 'num)
                            (faze num 'num)
                            (faze (format "0x%X" num) 'num)))
                 )
                ((string-match "\\`[[:digit:]]+\\'" (faze sym 'num))
                 (let ((num (string-to-number sym)))
                   (message "Decimal Integer %s, Hex:%s Bin:%s"
                            (faze sym 'num)
                            (faze (format "0x%X" num) 'num)
                            (faze(number-to-string-in-radix num 2) 'num)))
                 )
                ((string-match "\\`0[oO][0-7]+\\'" (faze sym 'num))
                 (let ((num (string-to-number (substring sym 2) 8)))
                   (message "Octal Integer %s, Dec:%s, Hex:%s Bin:%s" (faze sym 'num)
                            (faze num 'num)
                            (faze (format "0x%X" num) 'num)
                            (faze (number-to-string-in-radix num 2) 'num)))
                 )
                ((string-match "\\`0[xX][[:xdigit:]]+\\'" (faze sym 'num))
                 (let ((num (string-to-number (substring sym 2) 16)))
                   (message "Hexadecimal Integer %s, Dec:%s Bin:%s"
                            (faze sym 'num)
                            (faze num 'num)
                            (faze (number-to-string-in-radix num 2) 'num)))
                 ))
          )))))
;;; Use: 256
;;; Use: 0b1000101010101
;;; Use: 0o12
;;; Use: 0x101
;; (add-hook 'post-command-hook 'number-literal-message t)
(defun activate-literal-message-mode ()
  (add-hook 'post-command-hook 'number-literal-message t))
(defun dectivate-literal-message-mode ()
  (remove-hook 'post-command-hook 'number-literal-message t))
;; (add-hook 'c-mode-common-hook 'activate-literal-message-mode t)
;; (add-hook 'prog-mode-hook 'activate-literal-message-mode t)
;; (add-hook 'python-mode-hook 'activate-literal-message-mode t)
;; NOTE: Disabled because this hangs forever when opening shell script files
;; (add-hook 'after-change-major-mode-hook 'activate-literal-message-mode t)
(remove-hook 'after-change-major-mode-hook 'activate-literal-message-mode)

(provide 'show-num)
