;;; symbol-face.el --- Store Symbol Specific Face as Symbol Property for use in
;;; for example font-locking.
;; Copyright (C) 2007 Per Nordlöw
;; Author: Per Nordlöw <per.nordlow@gmail.com>

(require 'font-lock-extras)

(defsubst elisp-symbol-face (sym &optional quoted def)
  "Return face name suitable for highlighting references of the symbol SYM.
Used typically in `emacs-lisp-mode'. If DEF is non-nil get
definition face instead of reference face."
  (cond
   ((fboundp sym)                       ;some kind of function
    (let ((fn (symbol-function sym)))   ;symbol's function definition
      (cond
       ((subrp fn) ;built-in function
        (if def 'font-lock-builtin-face
          (if quoted 'font-lock-quoted-builtin-ref-face 'font-lock-builtin-ref-face)))
       ((commandp fn) ;interactive function
        (if def 'font-lock-command-name-face
          (if quoted 'font-lock-quoted-command-call-face 'font-lock-command-call-face)))
       ((functionp fn) ;lisp (standard) function
        (if def 'font-lock-function-name-face
          (if quoted 'font-lock-quoted-function-name-face 'font-lock-function-call-face)))
       (t   ;macro. TODO Check in on Google Groups post http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/1a20b5a9228fdb8b# why this doesn't work.
        (if def 'font-lock-macro-name-face
          (if quoted 'font-lock-quoted-macro-name-face 'font-lock-macro-call-face)))
       )))
   ((internal-lisp-face-p sym) ;face reference
    (if quoted 'font-lock-quoted-face-name-face 'font-lock-face-name-face))
   ((boundp sym)            ;variable reference
    (if def 'font-lock-variable-name-face
      (if quoted 'font-lock-quoted-variable-ref-face 'font-lock-variable-ref-face)))
   (t (if quoted 'italic))  ;others. TODO In comments this should be `font-lock-symbol-ref-face'
   ))
;; Use: (elisp-symbol-face 'find-file)
;; Use: (elisp-symbol-face 'benchmark-run nil t)
;; Use: (elisp-symbol-face 'find-file t)
;; Use: (benchmark-run 10000 (elisp-symbol-face 'find-file))
;; Use: (elisp-symbol-face 'case)
;; Use: (named-macrop 'case)

(defun symbol-ref-face (name &optional quoted)
  "Return face used to highlighting the reference of symbol NAME.
Like `elisp-symbol-face' but caches that result in the symbol
NAME's property `:ref-face'."
  (let ((sym (intern-soft name)))       ;Note: `nil' and `t' are also symbols!
    (or (get sym :ref-face)          ;either reuse cached
        (put sym :ref-face (elisp-symbol-face sym quoted))))) ;or generate new
(defalias 'symbol-face 'symbol-ref-face)
;; Use: (symbol-ref-face nil)
;; Use: (symbol-ref-face "find-file")
;; Use: (symbol-ref-face 'find-file)
;; use: (symbol-plist 'find-file)
;; Use: (benchmark-run 300000 (symbol-ref-face "find-file"))
;; Use: (benchmark-run 300000 (symbol-ref-face 'find-file))

(defun symbol-def-face (name &optional quoted)
  "Return face used to highlighting the definition of symbol NAME.
Like `elisp-symbol-face' but caches that result in the symbol
NAME's property `:def-face'."
  (let ((sym (intern-soft name)))       ;Note: `nil' and `t' are also symbols!
    (or (get sym :def-face)          ;either reuse cached
        (put sym :def-face (elisp-symbol-face sym quoted t))))) ;or generate new
;; Use: (symbol-def-face nil)
;; Use: (symbol-def-face "find-file")
;; Use: (symbol-def-face 'find-file)
;; use: (symbol-plist 'find-file)
;; Use: (benchmark-run 300000 (symbol-def-face "find-file"))
;; Use: (benchmark-run 300000 (symbol-def-face 'find-file))

(provide 'symbol-face)
