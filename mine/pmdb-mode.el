;;; pmdb-mode.el --- GNU Emacs major mode for editing PMDB source

;; Copyright (C) 2007 by Per Nordlöw

;; Author: Per Nordlöw <per.nordlow@gmail.com>
;; Version 0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;;; Commentary:

;; This package is a major mode for editing PMDB patterns.

;;; Code:

(defgroup pmdb-mode nil
  "PMDB mode."
  :group 'wp
  :prefix "pmdb-")

(defvar pmdb-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\es" 'center-line)
    map)
  "Major mode keymap for `pmdb-mode'.")

(defvar pmdb-mode-syntax-table
  (let ((st (copy-syntax-table text-mode-syntax-table)))
    ;; " isn't given string quote syntax in text-mode but it
    ;; (arguably) should be for use round pmdb arguments (with ` and
    ;; ' used otherwise).
    ;;(modify-syntax-entry ?\" "\"  2" st)
    ;; Comments are delimited by \" and newline.
    ;;(modify-syntax-entry ?\\ "\\  1" st)
    ;;(modify-syntax-entry ?\n ">  1" st)
    st)
  "Syntax table used while in `pmdb-mode'.")

(defconst pmdb-relations
  (list "dat" "alt"  "man"  "opt"  "any"  "not" "dup"  "rng"  "sup"
	"sub"  "par"  "chi"  "grp"  "beg"  "end"  "bof"  "eof" "abb"
	"use" "see")
  "Relations to highlight in PMDB mode.")

(defconst pmdb-comment-start "#"
  "Start pattern for comments")

;; NOTE: The one in 1 'font-lock-comment-face means that the regular expression ;; is actually a function that returns one 1 category
(defconst pmdb-font-lock-keywords
  (progn
    (require 'font-lock)
    (list
     ;; Comments
     (list (concat
	    "\\([ \t]*"
	    pmdb-comment-start
	    ".*\\)$")
	   1 'font-lock-comment-face)
     ;; Hex Literals
     (list "0x[0-9a-fA-F]+" 0 font-lock-constant-face)
     ;; Relations
     (list (concat
	    "<\\<\\("
	    (mapconcat 'identity pmdb-relations "\\|")
	    "\\)\\>>")
	   1 font-lock-keyword-face)
     ;; String Literals
     (list "\\(\".*\"\\)" 1 font-lock-string-face)
     ;; Dotted quads
     (list (mapconcat 'identity (make-list 4 "[[:digit:]]+") "\\.")
	   0 font-lock-variable-name-face)
     ))
  "Expressions to font-lock in PMDB mode.")

(defcustom pmdb-mode-hook nil
  "Hook run by function `pmdb-mode'."
  :type 'hook
  :group 'pmdb-mode)

;;;###autoload
(define-derived-mode pmdb-mode text-mode "PMDB"
  "Major mode for editing text intended for PMDB to format.
\\{pmdb-mode-map}
Turning on PMDB mode runs `text-mode-hook', then `pmdb-mode-hook'."
  (set
   (make-local-variable 'font-lock-defaults)
   '((pmdb-font-lock-keywords)))
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-start-skip) "\\\\\"[ \t]*")
  (set (make-local-variable 'comment-column) 40)
  )

(provide 'pmdb-mode)

;;; pmdb-mode.el ends here
