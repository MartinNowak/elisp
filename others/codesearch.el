;;; codesearch.el --- search for free software source code on the
;;; Internet from within Emacs via Google Code Search

;; Copyright (C) 2007  Juergen Hoetzel

;; Author: Juergen Hoetzel <juergen@hoetzel.info>
;; Keywords: languages, tools, comm, docs
;; Version: 1.1

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; codesearch.el is tested with GNU Emacs 22.1 on GNU/Linux and
;; Windows

;; The latest version of this package should be available from
;; <URL:http://www.hoetzel.info/Hacking/emacs/codesearch.el>.

;; To use this mode, put codesearch.el somewhere on your load-path.
;; Then add this to your .emacs:
;;
;;    (require 'codesearch)
;; 

;;; ChangeLog:

;; 1.1
;;   (codesearch): Fixed Error, when (current-word) returned nil
;;   (codesearch): Added autoload "magic" comment
;;   (codesearch-mode-to-lang): Code cleanup

;;; Code:

(provide 'codesearch)
(require 'cl)

(defvar codesearch-history nil "Google Code Search history.")

(defvar codesearch-valid-lang-list
  '("ada" "applescript" "asp" "assembly" "basic" "c" "c++" "c#" "cobol"
    "coldfusion" "d" "eiffel" "erlang" "fortran" "haskell" "java"
    "javascript" "jsp" "lex" "lex" "limbo" "lisp" "lua" "makefile"
    "mathematica" "matlab" "modula2" "modula3" "objectivec" "ocaml"
    "pascal" "perl" "php" "prolog" "python" "r" "rebol" "ruby" "scheme"
    "shell" "smalltalk" "sql" "sml" "tcl" "troff" "vhdl" "yacc")
  "valid language filters supported by Google Code Search")

(defvar codesearch-special-chars (string-to-list "$^\\\[\](){}*+")
  "Escape these character in querystring, because the have
  special meaning as regular expression")

(defvar codesearch-url-format-string 
  "http://www.google.com/codesearch?as_q=%s&as_lang=%s"
  "Format string for codesearch URL.")

(defun codesearch-mode-to-lang (mode)
  "map emacs mode to variable in Code Search querystring (list is
far from complete)."
  (case mode
    ((lisp-mode emacs-lisp-mode lisp-interaction-mode) "lisp")
    (objc-mode "objectivec")
    (sh-mode "shell")
    (otherwise 
     (let ((mode-name (symbol-name mode)))
       (if (and (string= (substring  mode-name -5) "-mode")
		(member (substring mode-name 0 -5) codesearch-valid-lang-list))
	   (substring mode-name 0 -5)
	 ;; cannot map to valid language filter
	 "")))))

(defun codesearch-re-escape (re)
  "Looks for Code Search special characters and escape them, i.e. \\"
  (replace-regexp-in-string
   (regexp-opt-charset codesearch-special-chars) "\\\\\\&" re))

;;;###autoload
(defun codesearch(searchstring)
  "Code Search current word, or with optional prefix arg, on
current region"
  (interactive 
   (let* ((default-entry
	    (codesearch-re-escape
	     (if current-prefix-arg 
		 (buffer-substring (region-beginning) (region-end))
	       (or (current-word) ""))))
	  (input 
	   (read-string 
	    "Code Search: " default-entry 'codesearch-history default-entry)))
     (if (string= input "")
	 (error "No search string specified"))
     (list input)))
  
  ;; identification of lang
  (let* ((lang (codesearch-mode-to-lang major-mode))
	 (url (format codesearch-url-format-string searchstring lang)))
    (require 'browse-url)
    (browse-url url)))

;;; codesearch.el ends here