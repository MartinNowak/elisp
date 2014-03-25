;;; operators-mode.el --- GNU Emacs major mode for Language Operator Tables

;; Copyright (C) 2007 by Per Nordlöw

;; Author: Per Nordlöw <per.nordlow@gmail.com>
;; Version 0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;;; Code:

(defgroup operators-mode nil
  "Operators mode."
  :group 'wp
  :prefix "operators-")

(defun operators-quit ()
  "Restart the same scan in the same tree."
  (interactive)
  (quit-window)                         ;but don't delete it
  ;;(kill-buffer-and-window)
  )

(defvar operators-mode-map nil
  "Major mode keymap for `operators-mode'.")
(setq operators-mode-map
      (let ((map (make-sparse-keymap)))
        (define-key map "\es" 'center-line)
        (define-key map "\es" 'center-line)
        (define-key map [(?q)] 'operators-quit)
        map))

(defconst operators-precedence
  (list "Highest Precedence" "Lowest Precedence")
  "Patterns for Precedence")

(defconst operators-comments
  (list "Operator" "Description" "Associates" "Languages")
  "Patterns for comments")

(defconst operators-ops
  (list (regexp-quote "++")
	(regexp-quote "--")

	(regexp-quote "()")
	(regexp-quote "[]")

	(regexp-quote "!=")
	(regexp-quote "!")
	(regexp-quote "~")

	(regexp-quote "&=")
	(regexp-quote "&&")
	(regexp-quote "&")

	(regexp-quote "|=")
	(regexp-quote "||")
	(regexp-quote "|")

	(regexp-quote "^=")
	(regexp-quote "^")

	(regexp-quote "sizeof")

	(regexp-quote "new")
	(regexp-quote "delete")

	(regexp-quote "(type)")

	(regexp-quote ".*")
	(regexp-quote "->*")

	(regexp-quote "->")
	(regexp-quote ".")

	(regexp-quote "-=")
	(regexp-quote "+=")

	(regexp-quote "-")
	(regexp-quote "+")

	(regexp-quote "*=")
	(regexp-quote "/=")
	(regexp-quote "%=")

	(regexp-quote "*")
	(regexp-quote "/")
	(regexp-quote "%")

	(regexp-quote "+")
	(regexp-quote "-")

	(regexp-quote "<<=")
	(regexp-quote ">>=")

	(regexp-quote "<<")
	(regexp-quote ">>")

	(regexp-quote "<=")
	(regexp-quote "<")
	(regexp-quote ">=")
	(regexp-quote ">")

	(regexp-quote "==")
	(regexp-quote "=")

	(regexp-quote "? :")

	(regexp-quote ",")
	)
  "Operators to highlight in Operators mode.")

(defconst operators-l2r
  (list "Left to right" "Right to left")
  "Patterns for comments")

;; NOTE: The one in 1 'font-lock-comment-face means that the regular
;; expression is actually a function that returns one category.
(defconst operators-font-lock-keywords
  (progn
    (require 'font-lock)
    (list
     ;; Precedence
     (list (concat
	    "\\("
	    (mapconcat 'identity operators-precedence "\\|")
	    "\\)")
	   1 font-lock-type-face)
     ;; Comments
     (list (concat
	    "\\("
	    (mapconcat 'identity operators-comments "\\|") "\\)")
	   1 'font-lock-comment-face)
     ;; Relations
     (list (concat
	    "\\s-+"			;at least one white space
	    "\\("
	    (mapconcat 'identity operators-ops "\\|")
	    "\\)")
	   1 font-lock-keyword-face)
     ;; Left-to-right
     (list (concat
	    "\\("
	    (mapconcat 'identity operators-l2r "\\|")
	    "\\)")
	   1 font-lock-constant-face)
     ))
  "Expressions to font-lock in Operators mode.")

(defcustom operators-mode-hook nil
  "Hook run by function `operators-mode'."
  :type 'hook
  :group 'operators-mode)

;;;###autoload
(define-derived-mode operators-mode text-mode "Operators"
  "Major mode for editing text intended for Operators to format.
\\{operators-mode-map}
Turning on Operators mode runs `text-mode-hook', then `operators-mode-hook'."
  (set
   (make-local-variable 'font-lock-defaults)
   '((operators-font-lock-keywords)))
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-start-skip) "\\\\\"[ \t]*")
  (set (make-local-variable 'comment-column) 40)
  )

(provide 'operators-mode)

;;; operators-mode.el ends here
