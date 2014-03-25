;;; elisp-utils.el --- Small useful snippets used in development of Emacs Lisp.
;; Author: Per Nordlöw

(require 'list-callers)
(require 'font-lock-extras)
(require 'obarray-utils)
(require 'power-utils)

(defalias 'elisp-mode 'emacs-lisp-mode)

(defun symbol-function-key-strings-list (symbol)
  "Lookup a list of strings describing the function keybindings of SYMBOL."
  (interactive "aFunction: ")
  (mapcar 'key-description (where-is-internal symbol))
  )
;; Use: (symbol-function-key-strings-list 'isearch-forward)
;; Use: (symbol-function-key-strings-list 'find-file)

(defun symbol-function-keys-string (symbol &optional separator)
  "Get a string describing function keybindings of SYMBOL.
If SYMBOL has no keybindings return nil."
  (let ((keys (symbol-function-key-strings-list symbol)))
    (cond ((null keys)
           nil)
          ((listp keys)
           (concat (when (> (length keys) 1)
                     "either ")
                   (mapconcat (lambda (key)
                                (faze key 'font-lock-keycomb-face))
                              keys
                              (or separator
                                  ", "))))
          ((stringp keys)
           keys)
          (t
           (error "Unsupported format of %s" keys)))))
;; Use: (symbol-function-keys-string 'xxx)
;; Use: (symbol-function-keys-string 'isearch-forward)
;; Use: (symbol-function-keys-string 'find-file)

(defun read-symbol-at-point-interactive (prompt &optional predicate)
  "Read symbol from global `obarray' defaulting to symbol at point."
  (let* ((fn (or (and (fboundp 'symbol-nearest-point)
                      (symbol-nearest-point))
                 (function-called-at-point)))
         (enable-recursive-minibuffers t))
    (when (if predicate
              (funcall predicate fn)
            (intern-soft fn))
      (setq fn nil))
    (list (intern-soft
           (completing-read prompt
                            (if predicate ;if predicate is given
                                obarray ;we need the ray obarray
                              (obarray-lazy-completion-table) ;otherwise we can colorize things
                              )
                            predicate t nil nil
                            (and fn (symbol-name fn)) t)))))
;; Test:
(when nil
  (read-symbol-at-point-interactive "Describe Lisp function: " (lambda (x) (and (functionp x)
                                                                    (not (subrp (symbol-function x))))))
  )

(defun describe-lisp-function (function)
  "Describe an Emacs FUNCTION written in Emacs Lisp."
  (interactive (read-symbol-at-point-interactive
                "Describe Lisp function: "
                (lambda (fn) (and (functionp fn)
                                  (not (subrp (symbol-function fn)))))))
  (unless (functionp function)
    (error "Not a defined function: `%s'" function))
  (when (subrp (symbol-function function))
    (error "Built-in (non Lisp) function: `%s'" function))
  (describe-function function))
;; Use: (describe-lisp-function 'find-file)

(defun describe-builtin-function (function)
  "Describe an Emacs builtin FUNCTION (written in C)."
  (interactive (read-symbol-at-point-interactive
                "Describe builtin function: "
                (lambda (fn) (and (functionp fn)
                                  (subrp (symbol-function fn))))))
  (unless (functionp function)
    (error "Not a defined function: `%s'" function))
  (unless (subrp (symbol-function function))
    (error "Non-Built-in (Lisp) function: `%s'" function))
  (describe-function function))
(global-set-key [(control h) (j)] 'describe-builtin-function)
;; Use: (describe-builtin-function 'assoc)

(defun describe-symbol (symbol)
  "Describe an Emacs SYMBOL."
  (interactive (read-symbol-at-point-interactive
                "Describe symbol: "))
  (cond ((functionp symbol)
         (describe-function symbol))
        ((fboundp symbol)
         (describe-function symbol))
        ((facep symbol)
         (customize-face symbol))
        ((boundp symbol)
         (describe-variable symbol))
        (t
         (message "%s"(symbol-plist (intern-soft symbol))))))
(global-set-key [(control h) (s)] 'describe-symbol)
(global-set-key [(control h) (?,)] 'describe-syntax)
;; Use: (describe-builtin-function 'assoc)

(defun symbol-length (symbol)
  "Get Length of Emacs SYMBOL."
  (interactive (read-symbol-at-point-interactive
                "Length of symbol: "
                (lambda (x) (and (symbolp x)
                                   (sequencep (symbol-value x))))))
  (length (symbol-value symbol)))
(defalias 'length-of-symbol-value 'symbol-length)
(global-set-key [(control h) (?N)] 'symbol-length)

(defun list-largest-symbols ()
  "List the largest list, vector and string interned in obarray."
  (interactive "")
  (let (hashes
        lists
        vectors
        strings)
    (mapatoms (lambda (symbol)
                (when (boundp `,symbol) ;bound as a variable
                  (let ((value (symbol-value symbol)))
                    (when value
                      (cond ((hash-table-p value)
                             (when (or (not hashes)
                                       (> (hash-table-count value)
                                          (hash-table-count hashes)))
                               (setq hashes value)))
                            ((listp value)
                             (when (or (not lists)
                                       (> (length value)
                                          (length lists)))
                               (setq lists value)))
                            ((vectorp value)
                             (when (or (not vectors)
                                       (> (length value)
                                          (length vectors)))
                               (setq vectors value)))
                            ((stringp value)
                             (when (or (not strings)
                                       (> (length value)
                                          (length strings)))
                               (setq strings value)))
                            ))))))
    `(,lists
      ,vectors
      ,strings)))
;; Use: (list-largest-symbols)

;;; ---------------------------------------------------------------------------

(defun elisp-disassemble (function)
  (interactive (list (function-called-at-point)))
  (disassemble function))
;; Use: (elisp-disassemble 'elisp-disassemble)

(defun elisp-pp (sexp)
  (with-output-to-temp-buffer "*Pp Eval Output*"
    (pp sexp)
    (with-current-buffer standard-output
      (emacs-lisp-mode))))

(defun elisp-macroexpand (form)
  (interactive (list (form-at-point 'sexp)))
  (elisp-pp (macroexpand form)))

(defun elisp-macroexpand-all (form)
  (interactive (list (form-at-point 'sexp)))
  (elisp-pp (cl-macroexpand-all form)))

(defun elisp-push-point-marker ()
  (require 'etags)
  (cond ((featurep 'xemacs) (push-tag-mark))
        (t (ring-insert find-tag-marker-ring (point-marker)))))

(defun elisp-pop-found-function ()
  (interactive)
  (cond ((featurep 'xemacs) (pop-tag-mark nil))
        (t (pop-tag-mark))))

(defun elisp-find-definition (name)
  "Jump to the definition of the function (or variable) at point."
  (interactive
   (list
    (let ((default (thing-at-point 'symbol)))
      (completing-read (concat "Find symbol" (when default (concat " (default " default ")")) ": ")
                       obarray nil t nil nil default))))
  (cond (name
         (let ((symbol (intern-soft name))
               (search (lambda (fun sym)
                         (let* ((r (save-excursion (funcall fun sym)))
                                (buffer (car r))
                                (point (cdr r)))
                           (cond ((not point)
                                  (error "Found no definition for %s in %s"
                                         name buffer))
                                 (t
                                  (switch-to-buffer buffer t)
                                  (goto-char point)
                                  (recenter 1)))))))
           (cond ((fboundp symbol)      ;if function symbol
                  (elisp-push-point-marker)
                  (funcall search 'find-function-noselect symbol))
                 ((boundp symbol)       ;if other symbol
                  (elisp-push-point-marker)
                  (funcall search 'find-variable-noselect symbol))
                 (t
                  (message "Symbol not bound: %S" symbol)))))
        (t (message "No symbol at point"))))

(defun find-symbol-definition (symbol)
  "Find the definition of SYMBOL, defaults to the symbol at point.
Prefer functions over variables over faces."
  (interactive
   (list (let ((symbol (thing-at-point 'symbol)))
           (intern (completing-read
                    (concat "Find symbol"
                            (and symbol
                                 (format " (default %s)" symbol))
                            ": ") obarray
                            (lambda (sym)
                                (or (fboundp sym)
                                    (boundp sym)
                                    (facep sym))) t)))))
  (find-function-do-it
   symbol
   (cond
    ((fboundp symbol) nil)
    ((boundp symbol) 'defvar)
    (t 'defface)) (lambda (buffer-or-name)
                     (switch-to-buffer buffer-or-name t))))

(defun jump-to-form-definition ()
  "Alternative to `elisp-find-definition'?"
  (interactive)
  (if (featurep 'xemacs)
      (progn
        (forward-char 1)
        (let ((name (symbol-atpt))
              (file (progn (search-forward "\"" nil t 1)(thing-at-point
                                                         'filename))))
          (forward-char 1)
          (help-find-source-or-scroll-up (point))
          (switch-to-buffer (current-buffer) t)
          (kill-new name)
          (search-forward name)))
    (other-window 1)
    (forward-button 1)
    ;; (find-file (filename-atpt))
    (push-button)))

(defun elisp-bytecompile-and-load ()
  (interactive)
  (or buffer-file-name
      (error "The buffer must be saved in a file first"))
  (require 'bytecomp)
  ;; Recompile if file or buffer has changed since last compilation.
  (when  (and (buffer-modified-p)
              (y-or-n-p (format "Save buffer %s first? " (faze (buffer-name) 'buffer))))
    (save-buffer))
  (let ((filename (expand-file-name buffer-file-name)))
    (with-temp-buffer
      (byte-compile-file filename t))))

(defvar elisp-extra-keys
  '(
    ;;    ((kbd "C-c d")   'elisp-disassemble)
    ;;    ((kbd "C-c m")   'elisp-macroexpand)
    ;;    ((kbd "C-c M")   'elisp-macroexpand-all)
    ;;    ((kbd "C-c C-c") 'compile-defun)
    ;;    ((kbd "C-c C-k") 'elisp-bytecompile-and-load)
    ;;    ((kbd "C-c C-l") 'load-file)
    ;;    ((kbd "C-c p")   'pp-eval-last-sexp)
    ;;    ((kbd "M-.")     'elisp-find-definition)
    ;;    ((kbd "M-,")     'elisp-pop-found-function)
    ((kbd "C-c <")   'list-callers)
    ))

(dolist (binding elisp-extra-keys)
  (let ((key (eval (car binding)))
        (val (eval (cadr binding))))
    (define-key emacs-lisp-mode-map key val)
    (define-key lisp-interaction-mode-map key val)))

;; ---------------------------------------------------------------------------

;;; TODO: Merge or replace with `file-size-human-readable'.
(defun number-to-iso-postfixed-string (number &optional binary)
  "Convert NUMBER to ISO-postfixed string.
If BINARY is non-nil use bibytes prefixes KiB, MiB, GiB instead of
kB, MB, GB etc."
  (let ((scale (if binary 1024.0 1000.0))
        (postfix nil))
    (concat (if (< number scale)
                (if (zerop number) "0" (number-to-string number))
                (format "%.1f"
                        (cond ((< number (expt scale 2)) (setq postfix "k") (/ number (expt scale 1)))
                              ((< number (expt scale 3)) (setq postfix "M") (/ number (expt scale 2)))
                              ((< number (expt scale 4)) (setq postfix "G") (/ number (expt scale 3)))
                              ((< number (expt scale 5)) (setq postfix "T") (/ number (expt scale 4)))
                              ((< number (expt scale 6)) (setq postfix "P") (/ number (expt scale 5)))
                              ((< number (expt scale 7)) (setq postfix "E") (/ number (expt scale 6)))
                              (t
                               number)
                              )))
            postfix
            (when (and postfix binary) "i"))))
;; Use: (number-to-iso-postfixed-string 999 nil)
;; Use: (number-to-iso-postfixed-string 1001 nil)
;; Use: (number-to-iso-postfixed-string 1024)
;; Use: (number-to-iso-postfixed-string 1024 t)
;; Use: (number-to-iso-postfixed-string (* 1024 1024) t)
;; Use: (number-to-iso-postfixed-string (* 1024 1023) t)
;; Use: (number-to-iso-postfixed-string (* 1024 1025) t)
;; Use: (number-to-iso-postfixed-string (* 1024.0 1024 1025) t)

;; Use: (benchmark-run-compiled 100000 (file-size-human-readable 1e18))
;; Use: (file-size-human-readable 1e6)
;; Use: (file-size-human-readable 1e6 'si)
;; Use: (file-size-human-readable 1e6 'iec)

;; Use: (benchmark-run-compiled 100000 (number-to-iso-postfixed-string 1e18))
;; Use: (benchmark-run-compiled 100000 (number-to-iso-postfixed-string 1e18 t))

;; ---------------------------------------------------------------------------

(provide 'elisp-utils)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; elisp-utils.el ends here
