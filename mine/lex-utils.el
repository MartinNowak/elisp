;;; lex-utils.el --- Lexical Utilities.
;; Author: Per Nordlöw

(ignore-errors
  (if cedet-dev (require 'semantic-lex nil t) (require 'semantic/lex nil t))
  (if cedet-dev (require 'semantic-c nil t) (require 'semantic/bovine/c nil t))
  (if cedet-dev (require 'semantic-java nil t) (require 'semantic/bovine/java nil t))
  (if cedet-dev (require 'semantic-erlang nil t) (require 'semantic/bovine/erlang nil t))
  (if cedet-dev (require 'semantic-el nil t) (require 'semantic/bovine/el nil t))
  (if cedet-dev (require 'semantic-make nil t) (require 'semantic/bovine/make nil t)))

;; See: http://groups.google.se/group/gnu.emacs.help/browse_thread/thread/178e901350723b90
(defmacro inhibit-messages (&rest body)
  "Disabled messages temporarily and evaluation BODY. "
  `(flet ((message (&rest _))) ;temporarily disabled behaviour behaviour of the function `message'
     ,@body))
;; Use: (inhibit-messages (message "This is not shown in minibuffer."))
;; Use: (inhibit-messages (semantic-flex (point-min) (point-max)))

(defun mode-lexer (&optional mode)
  "Lookup Semantic lexer from MODE.
Default to `semantic-lex' if no mode-specific lexer was found."
  (case mode
    ((c-mode c++-mode objc-mode csharp-mode)
     (when (and (if cedet-dev (require 'semantic-c nil t) (require 'semantic/bovine/c nil t))
                (semantic-default-c-setup))
       'semantic-c-lexer))
    (java-mode
     (when (and (if cedet-dev (require 'semantic-java nil t) (require 'semantic/bovine/java nil t))
                ;; (semantic-java-doc-setup)
                ;; (semantic-default-java-setup)
                )
       'semantic-java-lexer))
    ;; (csharp-mode
    ;;  (when (and (if cedet-dev (require 'semantic-csharp nil t) (require 'semantic/bovine/csharp nil t))
    ;;             (semantic-default-csharp-setup))
    ;;    'semantic-make-lexer))
    (f90-mode
     (when (and (if cedet-dev (require 'semantic-f90 nil t) (require 'semantic/bovine/f90 nil t))
                (semantic-default-f90-setup))
       'semantic-f90-lexer))
    (erlang-mode
     (when (and (if cedet-dev (require 'semantic-erlang nil t) (require 'semantic/bovine/erlang nil t))
                (semantic-erlang-default-setup))
       'semantic-erlang-lexer))
    (emacs-lisp-mode
     (when (and (if cedet-dev (require 'semantic-el nil t) (require 'semantic/bovine/el nil t))
                (semantic-default-elisp-setup))
       'semantic-emacs-lisp-lexer))
    (scheme-mode
     (when (and (if cedet-dev (require 'semantic-scm nil t) (require 'semantic/bovine/scm nil t))
                (semantic-default-scheme-setup))
       'semantic-scheme-lexer))
    (makefile-mode
     (when (and (if cedet-dev (require 'semantic-make nil t) (require 'semantic/bovine/make nil t))
                (semantic-default-make-setup))
       'semantic-make-lexer))
    ;; (python-mode
    ;;  (when (and (if cedet-dev (require 'wisent-python nil t) (require 'semantic/wisent/python nil t))
    ;;             (semantic-default-python-setup))
    ;;    'semantic-python-lexer))
    ;; (javascript-mode
    ;;  (when (and (if cedet-dev (require 'wisent-javascript nil t) (require 'semantic/wisent/javascript nil t))
    ;;             (semantic-default-javascript-setup))
    ;;    'semantic-javascript-lexer))
    (t
     'semantic-lex) ;default to general lexer. Note: Used to be `semantic-flex'.
    ))
;; Use: (mode-lexer)
;; Use: (mode-lexer 'c-mode)
;; Use: (mode-lexer 'c++-mode)
;; Use: (mode-lexer 'csharp-mode)
;; Use: (mode-lexer 'f90-mode)
;; Use: (mode-lexer 'emacs-lisp-mode)
;; Use: (mode-lexer 'erlang-mode)
;; Use: (mode-lexer 'java-mode)
;; Use: (mode-lexer 'scheme-mode)
;; Use: (mode-lexer 'makefile-mode)
;; Use: (mode-lexer 'python-mode)
;; Use: (mode-lexer 'javascript-mode)

(defun semantic-lex-or-flex (&optional mode start end depth length)
  "Lexically safe analyze text in the current buffer between START and END using MODE-syntax.
START defaults to `point-min' and END defaults to `point-max'.
Similar to `semantic-lex' but defaults to `semantic-flex' if an
error during MODE-specific lexing occured."
  (let ((tree (ignore-errors
                (semantic-lex-init)
                (if t
                    (funcall (mode-lexer (or mode major-mode)) start end depth length)
                  (semantic-lex start end depth length)))))
    (if tree                            ;upon sucess
        tree                            ;return it
      (ignore-errors
        (inhibit-messages ;prevent `semantic-flex' from printing deprecation warning
         (semantic-flex start end depth length)))))) ;otherwise default to general `semantic-flex'
;; Use: (semantic-lex-or-flex)

(defun lex-mode-buffer-name (mode)
  (concat " *lex-in-" (symbol-name (or mode major-mode)) "*"))
;; Use: (lex-mode-buffer-name 'c-mode)

(defun lex-buffer (buffer &optional mode start end depth length)
  "Scan BUFFER lexically using MODE from START to END at DEPTH of LENGTH."
  (set-buffer (or buffer (current-buffer)))
  (semantic-lex-or-flex mode
                        (or start (point-min))
                        (or end (point-max))
                        depth length))

(defun lex-string (string &optional mode start end depth length)
  "Scan STRING using the lexical elements described by the syntax
in MODE. MODE is the function name of an Emacs Mode such as
c-mode, emacs-lisp-mode, etc."
  (save-current-buffer
    (let* ((bname (lex-mode-buffer-name mode))
           (buf (get-buffer bname)))
      (if buf
          (progn
            (set-buffer buf)
            (erase-buffer))
        (setq buf (get-buffer-create bname))
        (set-buffer buf)
        (when (fboundp mode) (funcall `,mode)) ;enter mode (for first time)
        )
      (insert string)
      (unless start (setq start (point-min))) ;start defaults to point-min
      (unless end (setq end (point-max)))
      (semantic-lex-or-flex mode start end depth length)
      )))
;; Use: (lex-string "int x = 1;" 'c-mode nil nil 10)
;; Use: (lex-string "x == y" 'c-mode nil nil 10)
;; Use: (lex-string "int x = 1;" 'c-mode nil nil 10)
;; Use: (lex-string "int x = 1;" 'c++-mode nil nil 10)
;; Use: (lex-string "int x = 1;" 'csharp-mode nil nil 10)
;; Use: (benchmark-run 10 (lex-string "int x = 1;" 'c-mode nil nil 10))
;; Use: (benchmark-run 10 (lex-string "int x = 1;" 'c++-mode nil nil 10))
;; Use: (lex-string "(* 2 2)" 'emacs-lisp-mode nil nil 10)
;; Use: (lex-string "static int x = 12 + 0x12;" 'c-mode)
;; Use: (lex-string "int add(int x, int y);" 'c-mode)
;; Use: (lex-string "x*" 'c-mode)
;; Use: (lex-string "x=1" 'c-mode)
;; Use: (lex-string "x=1" 'c++-mode)
;; Use: (lex-string "ob->vis" 'c-mode)
;; Use: (lex-string "x_y* 1.2 x3" 'c-mode)
;; Use: (lex-string "x*" 'emacs-lisp-mode)
;; Use: (lex-string "(* 2 2)" 'emacs-lisp-mode)
;; Use: (lex-string "int * x = y;" 'c-mode)
;; Use: (lex-string "ob->vis" 'c-mode nil nil 10)

(defun lex-file (filename &optional start end depth length)
  "Scan FILE using the lexical elements described by the syntax
associated with MODE."
  (save-current-buffer
    (set-buffer (find-file-noselect filename)) ;Note: Use find-file because we want to reuse decodings if its been previously openeed.
    (unless start (setq start (point-min))) ;start defaults to point-min
    (unless end (setq end (point-max)))
    (semantic-lex start end depth length)))
;; Use: (lex-file "/usr/include/stdio.h" nil nil 10)
;; Use: (lex-file "~/justcxx/vec2f.h" nil nil 10)

;; ===========================================================================

(defun lexical-mapcar-buffer (buffer &optional mode start end depth length function separator)
  "Perform a (mapconcat FUNCTION sequence SEPARATOR) on the
MODE-specific lexical elements in BUFFER. FUNCTION must return a string."
  (mapconcat (if function function 'identity) ;default function to `identity'
             (lex-buffer buffer mode start end depth length)
             (if separator separator ""))) ;default separator to empty string

(defun lexical-mapcar-string (string &optional mode start end depth length function separator)
  "Perform a (mapconcat FUNCTION sequence SEPARATOR) on the
MODE-specific lexical elements in STRING. FUNCTION must return a string."
  (mapconcat (if function function 'identity) ;default function to `identity'
             (lex-string string mode start end depth length)
             (if separator separator ""))) ;default separator to empty string

(defun lexical-dolist-string (string &optional mode start end depth length function separator)
  "Perform a (mapconcat FUNCTION sequence SEPARATOR) on the
MODE-specific lexical elements in STRING. FUNCTION must return a string."
  (let ((result ""))
    (dolist (l (lex-string string mode start end depth length))
      (setq result
	    (concat result
		    (if function
			(funcall function l)
		      l))))))

(provide 'lex-utils)
