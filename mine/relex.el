;;; relex.el --- Relax Lexical Whitespace String.
;; Author: Per Nordlöw

(require 'lex-utils)

(defun relax-lexical-whitespace-in-string (string &optional mode multi-line format)
  "Relax whitespace between the MODE-specific lexical elements in STRING.
Return a regexp that matches the STRING
lexical-whitespace-relaxed. If MULTI-LINE is non-nil whitespace
may span multiple lines. FORMAT can be either `grep', `emacs' or t."
  (let (prev-t-type force-space)
    (save-current-buffer
      (set-buffer (get-buffer-create (lex-mode-buffer-name mode)))
      (erase-buffer)
      (insert string)
      (lexical-mapcar-buffer
       nil mode nil nil 10 nil
       (lambda (token)
         (let* ((t-type (car token))
                (t-start (cadr token))
                (t-end (cddr token))
                (t-str (regexp-quote (buffer-substring t-start t-end))) ;lookup
                ;; symbols and numbers must be separated by at least one space
                (force-space (and (memq prev-t-type '(symbol number))
                                  (memq t-type '(symbol number))))
                )
           (let ((sep (when prev-t-type ;when not first token
                        (if multi-line
                            (case format
                              ('grep (concat "[[:space:]\\n]" (if force-space "+" "*")))
                              ('emacs (concat "[[:space:]\n]" (if force-space "+" "*")))
                              (t (concat "[[:space:]\n]*" (if force-space "+" "*")))
                              )
                          (concat "[[:space:]]" (if force-space "+" "*"))))))
             (setq prev-t-type t-type)
             (concat sep (if (and (eq format 'grep)
                                  (and
                                   (= (length t-str) 1)
                                   (memq (string-to-char t-str) '(?\( ?\) ?\-))
                                   ))
                             (concat "\\" t-str)
                           t-str))
             )))))))
(defalias 'relex-string-ws 'relax-lexical-whitespace-in-string)
;; TODO Fix this!
;; Use: (relax-lexical-whitespace-in-string "ob->vis" 'c-mode t)
;; Use: (relax-lexical-whitespace-in-string "f" 'c-mode)
;; Use: (relax-lexical-whitespace-in-string "f" 'c++-mode)
;; Use: (relax-lexical-whitespace-in-string "f(x)" 'text-mode)
;; Use: (relax-lexical-whitespace-in-string "f(x)" 'c-mode nil 'grep)

;; Use: (relax-lexical-whitespace-in-string "\"m.h\"" 'c-mode)
;; Use: (relax-lexical-whitespace-in-string "\"m.h\"" 'c-mode nil 'grep)

;; Use: (relax-lexical-whitespace-in-string "x += y" 'c-mode)
;; Use: (relax-lexical-whitespace-in-string "x 12" 'c-mode)
;; Use: (relax-lexical-whitespace-in-string "x=12" 'c-mode)
;; Use: (relax-lexical-whitespace-in-string "x_y* = 0;" 'c-mode)
;; Use: (relax-lexical-whitespace-in-string "x_y* = 0;" 'c-mode t 'emacs)
;; Use: (relax-lexical-whitespace-in-string "x_y* = 0;" 'c-mode t 'grep)
;; Use: (relax-lexical-whitespace-in-string "x_y* = 0;" 'c-mode t 'other)
;; Use: (relax-lexical-whitespace-in-string "(1+ x-y 1)" 'emacs-lisp-mode)

(defun relax-whitespace-in-string (string &optional multi-line)
  "Replace all isolated non-empty occurrencies of whitespace in
the string STRING with a regular expression that matches one or
more whitespace characters and return a regexp(for use in either
Emacs or GNU grep)."
  (replace-regexp-in-string "[[:space:]]+"
                            (if multi-line
                                "[[:space:]\\\\n]+"
                              "[[:space:]]+")
                            string))
;; Use: (relax-whitespace-in-string "int* x = y;")
;; Use: (relax-whitespace-in-string "int* x = y;" t)

(provide 'relex)
