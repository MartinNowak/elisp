;;; altgr.el --- PC keyboard AltGr C- and M- replacement keys

;; Copyright (C) 2004 by Lennart Borgman

;; Author:     Lennart Borgman
;; Maintainer: EmacsWiki
;; Created: 2004-10-02
;; Version: 0.5
;; Keywords: keyboard pc language

;; This file is not part of Emacs

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Some keyboard keys in Emacs can not be used on non-english
;; keyboards on a PC because AltGr modified keys can not be modified
;; with C- or M- on a PC keyboard.  This file puts in language
;; specific replacement keys for what should have been AltGr keys
;; modified with C- or M-.
;;
;; This file is put up on EmacsWiki so that different persons can
;; enter new language specific modifiers.  Enter new languages in
;; `altgr-language-keyboard-table' and `altgr-language-keyboard'.
;;
;;
;; To use this file put it in your emacs load-path and put in your
;; .emacs this line:
;;
;; (require 'altgr)
;;
;; Then `customize' the variable `altgr-language-keyboard'.
;; To see your current replacement keys use C-M-f1.



;; Maybe this should be called from setup-function in
;; language-info-alist?  This is modified by set-language-info
;; (lang-env key info).

;;This is just for testing convenience:
;; (define-key global-map [f2] 'eval-buffer)
;; (define-key global-map [f3] 'altgr-help) 



(defvar altgr-help nil
  "Holds the help string for `altgr-help'."
  )

(defun altgr-help()
  "Shows current replacements for AltGr C- and M-keys."
  (interactive)
  (message altgr-help))

(define-key global-map [C-M-f1] 'altgr-help)


(defun altgr-setup-language-keyboard(lang)
  "For moving keys bound to C-<some altgr-key>."
  ;;(save-excursion (set-buffer "*Messages*") (erase-buffer))
  (let ((tbl (cdr (assoc lang altgr-language-keyboard-table))))
    (setq altgr-help
	  (format "AltGr C- and M- Replacements (%s keyboard layout):\n"
		  (car tbl)))
    (setq tbl (cdr tbl))
    (while tbl
      (let* ((row (car (cdr (car tbl))))
	     (to (car row))
	     (from (car (cdr row)))
	     (strto (car (cdr (cdr row)))))
	(define-key function-key-map (vector to) (vector from))
	(setq altgr-help (concat altgr-help
				 (format "  %s%s  ->  %s%s\n"
					 (event-modifiers from)
					 (char-to-string (event-basic-type from))
					 (event-modifiers to)
					 ;;(char-to-string (event-basic-type to ))
					 strto
					 )))
	(setq altgr-help (replace-regexp-in-string "(control)" "C-" altgr-help))
	(setq altgr-help (replace-regexp-in-string "(meta)"    "M-" altgr-help))
	(if (interactive-p) (altgr-help))
	)
      (setq tbl (cdr tbl)))))


;; I do not know how to bind M-char to the used lang specific
;; characters. Workaround if needed: use ESC key
;;
;; -[ (unused)
;; -$ (unused)
;; -{ (unused)
;; -} (unused)
(defconst altgr-language-keyboard-table
  '(
    ;; Lennart Borgman entered:
    (se . ("Swedish"
	   '(150 ?\C-@  "ö")    ; C-@ C-o ..   150 is o226
	   '(132 ?\C-\\ "ä")    ; C-\ C-a ..   132 is o204
	   '(133 ?\C-\] "å")	; C-] C-a ring 133 is o205
	   )
	)
    )
  "Alist of language specific keys bound to AltGr that should be moved.
Please use SI symbols for language (se=swedish)."
  )



(defcustom altgr-language-keyboard 'se
  "Language specific keyboard layout for AltGr keys replacement.

Keys that are bound to AltGr on a PC keyboard can not be modified with
C- or M-.  This function moves those C- and M- combinations to some
other keys (probably specific to the used language keyboard layout).

To see current bindings use C-M-f1.

"
  :tag "AltGr Replacements for Language Specific Keyboard"
  :type '(choice :tag "Language Specific Keyboard Layout"
		 ;; Lennart Borgman entered:
		 (const :tag "Swedish" :value se)
		 (const :tag "Danish" :value dk)
		 )
  :set (lambda (symbol value)
	 (set-default symbol value)
	 (altgr-setup-language-keyboard value))
  :group 'keyboard
  )



(provide 'altgr)

;;; altgr.el ends here
