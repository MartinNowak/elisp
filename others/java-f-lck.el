;;:  @(#)java-f-lck.el	1.1 28 Mar 1995
;;
;; Modified by Clemens Lahme (Clemens.Lahme@mailexcite.com)
;; 1996-08-14
;; Intended just for private use. Undocumented behavior, slow,
;; and some hardcoded preferences (tabs == 3)! For your own
;; purposes go look around for something more up to date.
;;
;; Font Lock Keywords for java-mode
;; Copyright (C) 1994 Mitch Chapman

;; Author: Mitch Chapman
;;         This module was derived from the c-mode font-lock
;;         keywords provided with GNU emacs 19.22.  As font-lock.el
;;         is distributed under the terms of the GNU General Public
;;         License, so is this code.  (See below.)

;; Maintainer: none
;; Keywords: languages, faces

;; This file is *NOT* part of GNU Emacs.

;; java-f-lck.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; java-f-lck.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with java-f-lck.el; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.


;;; Commentary:

;; This module defines font-lock keywords and regular expressions for
;; java-mode buffers.  You can use these definitions in
;; conjunction with font-lock.el to "fontify" Java buffers.

;; To automatically use the definitions in this module you need to
;; "plug in" the java font-lock keywords when entering
;; font-lock mode in an java-mode buffer.  Here's how:
;;       (add-hook 'font-lock-mode-hook
;;                 (function
;;                  (lambda ()
;;                    (if (eq major-mode 'java-mode)
;;                        (setq font-lock-keywords java-font-lock-keywords)))))

;; This is done for you at the end of this module.  If you don't
;; want this behavior, just comment out the relevant code.

;; clemens
;;(defvar my-font-lock-operator-face 'java-font-lock-operator-face
;;  "Face to use for Java Operators.")
;;(defvar my-font-lock-separator-face 'java-font-lock-operator-face
;;  "Face to use for Java Seperators like (){},.;")

(defconst java-font-lock-keywords-1 nil
  "For consideration as a value of `java-font-lock-keywords'.
This does fairly subdued highlighting.")

(defconst java-font-lock-keywords-2 nil
  "For consideration as a value of `java-font-lock-keywords'.
This does a lot more highlighting.")

(let ((storage (concat "static\\|abstract\\|const\\|final\\|"
							  "synchronized\\|threadsafe\\|transient\\|"
							  "private\\|\\protected\\|public"))
      (prefixes "short\\|long")
      ;; Clemens
		(operator "=\\|\\+\\|-\\|\\*\\|?\\|:\\||\\|&\\|~\\|/\\|%\\|&\\|\\^\\|<\\|>\\|!")
      (separator "\\.\\|;\\|{\\|}\\|(\\|)\\|,\\|\\[\\|\\]")
		;; weiter
      (types (concat
				  "class\\|boolean\\|int\\|char\\|byte\\|float\\|double\\|void\\|short\\|long"))
      (reserved-words
       '("private" "protected" "public" "break" "byvalue"
			"case" "catch" "class"
			"continue" "default" "do" "else if"
			"else" "extends" "false" "finally"
			"for" "if" "implements" "import"
			"instanceof" "interface"
			"new" "null" "package" "return"
			"super" "switch"
			"this" "throw"
			"true" "try" "while"
			"throws" ; Clemens
			))

      (ctoken "[a-zA-Z0-9_:~*]+")
      )
  (setq java-font-lock-keywords-1
		  (list
			;;
			;; fontify C++-style comments as comments.
			'("//.*" . font-lock-comment-face)
			;;
			;; seperator (clemens)
			(cons (concat "\\("
							  separator
							  "\\)")
					'font-lock-reference-face)
			;;
			;; operator (clemens)
			(cons (concat "\\("
							  operator
							  "\\)")
					1)
			;;
			;; zahlen
			(cons "[^a-zA-Z_]\\([0123456789]+\\)" 1)
			;;
			;; class or interface names (Clemens)
			(list (concat "\\(^\\|[ \t]\\)\\(class\\|interface\\)[ \t]+\\("
							  ctoken
							  "\\)\\([ \t{]\\|$\\)")
					3
					'font-lock-function-name-face)
			;;
			;; method names (Clemens)
			;; leider nur f�r mich brauchbar, da entfernung von ^
			;;    genau drei Zeichen betragen mu�.
			;;
			;; Konstruktor
			(list (concat "^\\(   \\|\t\\)\\("
							  ctoken
							  "\\)[ \t]*(")
					2
					'font-lock-function-name-face)
			;; normal
			(list (concat "^\\(   \\|\t\\)\\("
							  ctoken
							  "[ \t]+\\)*\\("
							  ctoken
							  "\\)[ \t]*(")
					3
					'font-lock-function-name-face)
			;;
			;; fontify the names of functions being defined.
			(list (concat
					 "^\\(" ctoken "[ \t]+\\)?"	; type specs; there can be no
					 "\\(" ctoken "[ \t]+\\)?"	; more than 3 tokens, right?
					 "\\(" ctoken "[ \t]+\\)?"
					 "\\([*&]+[ \t]*\\)?"		; pointer
					 "\\(" ctoken "\\)[ \t]*(")		; name
					5 'font-lock-function-name-face)
			;;
			;; fontify the (first word of) names of methods being defined.
			(list (concat
					 "^[+-][ \t]+"
					 "\\(("                          ;; typecasts are inside parens
					 "\\(" ctoken "[ \t]+\\)?"       ;; as above, <= 3, right?
					 "\\(" ctoken "[ \t]+\\)?"
					 "\\(" ctoken "[ \t]*\\)?"
					 "\\(\*+[ \t]*\\)?"              ;; pointer
					 ")[ \t]*\\)?"                   ;; end of typecast
					 "\\(" ctoken "\\):?[ \t]*")
					6 'font-lock-function-name-face)
			;;
			;; Fontify case clauses.  This is fast because its anchored on the left.
			'("case[ \t]+\\(\\(\\sw\\|\\s_\\)+\\):". 1)
			'("\\<\\(default\\):". 1)
			))

  (setq java-font-lock-keywords-2
		  (append java-font-lock-keywords-1
					 (list
					  ;;
					  ;; fontify all storage classes and type specifiers
					  (cons (concat "\\<\\(" storage "\\)\\>") 'font-lock-type-face)
					  (cons (concat "\\<\\(" types "\\)\\>") 'font-lock-type-face)
					  (cons (concat "\\<\\(" prefixes "[ \t]+" types "\\)\\>")
							  'font-lock-type-face)

					  ;;
					  ;; fontify all builtin tokens
					  (cons (concat
								"[ \t(){}=]\\("
								(mapconcat 'identity reserved-words "\\|")
								"\\)[ \t\n(){};,\\.]")
							  1)
					  (cons (concat
								ctoken
								"[ \t(){}=]\\("
								(mapconcat 'identity reserved-words "\\|")
								"\\)[ \t\n(){};,\\.]")
							  1)
					  (cons (concat
								"^\\("
								(mapconcat 'identity reserved-words "\\|")
								"\\)[ \t\n(){};,\\.]")
							  1)
					  )))
  )

													 ; default to the gaudier variety:
(defvar java-font-lock-keywords java-font-lock-keywords-2
  "Additional expressions to highlight in Java mode.")


;; Plug in the Java font-lock keywords, so they'll be used
;; automatically when you're in java-mode.
(add-hook 'font-lock-mode-hook
			 (function
			  (lambda ()
				 (if (eq major-mode 'java-mode)
					  (setq font-lock-keywords java-font-lock-keywords)))))


(provide 'java-f-lck)

