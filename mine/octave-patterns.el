;;; octave-patterns.el --- language patterns for Octave

;; Copyright (C) 2007 Per Nordlöw

;; Author: Per Nordlöw <per.nordlow@gmail.com>
;; Keywords: unix files

;; This file is NOT part of GNU Emacs.

;; ============================================================================

;; Octave Programming Language Patterns

(defconst octave-op-separators-regexp ;statement separator
  (regexp-quote-alts '(";" ","))
  "Matches Octave Statement Separator Operators: , ;")

(defconst octave-op-colon-regexp	;color
  (regexp-quote-alts '(":"))
  "Matches Octave Colon Operator: :")

;;   '("+=" "-="				;Assignment Additive
;;     "*=" "/="				;Assignment Multiplicative
;;     "^="				;Assignment Exponentiation
;;     "&=" "|="				;Assignment ?
;;     "=")

(defconst octave-op-assignment-regexp ;assignment
  (concat "\\(?:" (regexp-quote-alts '("+" "-" "*" "/" "\\" "^" "&" "|"))
	  "\\)" "?"  "=")
  "Matches Octave Assignment Operators: = += -= *= /= \\ = ^= &= |=")

(defconst octave-op-inc-dec-regexp ;increase, decrease
  (regexp-quote-alts '("++" "--"))
  "Matches Octave Assignment Operators Inc Dec: ++ --")

(defconst octave-op-additive-regexp ;additive
  (regexp-quote-alts '("+" "-"))
  "Matches Octave Additive Operators: + -")

(defconst octave-op-multiplicative-regexp ;multiplicative
  (concat "\\.?" "[\\*/\\\\]")
  "Matches Octave Multiplicative Operators: * / \\ .* ./ .\\")

(defconst octave-op-exp-regexp	;exponentiation
  (concat "\\.?"
	  "\\(?:" (regexp-quote-alts '("^" "**")) "\\)")
  "Matches Octave Exponentiation Operators: ^ ** .^ .**")

(defconst octave-op-transpose-regexp ;transpose
  '("'" ".'")
  "Matches Octave Transpose Operators: ' .'")

(defconst octave-op-comparison-regexp ;comparison
  (concat "[<>]" "=?" )
  "Matches Octave Comparison Operators: < > <= >=")

(defconst octave-op-equality-regexp ;equality
  (regexp-quote-alts '("" "" "" ""))
  "Matches Octave Logical Equality Operators: == != ~= <>")

(defconst octave-op-logical-regexp ;logical, elementwise logical
  (regexp-quote-alts '("&&" "||"	;Logical AND, OR
			   "&" "|"))	;Elementwise Logical AND, OR
  "Matches Octave Logical Equality Operators: == != ~= <>")

(defconst octave-op-braces-regexp
  (regexp-quote-alts
   '("[" "]"				;Array Indexing
     "{" "}"				;Curly Braces
     ))
  "Matches Octave Braces: [ ] { }")

(defconst octave-string-literal-regexp
  (concat "'" ".*" "'")
  "Matches String Literals: 'literal'")

(defconst octave-special-math-constants-regexp
  (concat "\\<" "\\(?:" (regexp-opt '("pi" "e" "NaN")) "\\)" "\\>")
  "Matches Special Match Constants: pi e NaN")

(defconst octave-common-functions-regexp
      (concat "\\<" "\\(?:"
	      (regexp-opt
	       '("min" "max"		;dynamically-linked
		 "mean"			;user-defined
		 "subplot" "plot" "figure " "title" "axis" ;user-defined
		 "zeros" "ones"			 ;built-in
		 "length" "size" "reshape"	 ;built-in
		 "real" "imag" "angle" "conj"	 ;built-in
		 "sum" "cumsum"			 ;built-in
		 "disp"
		 "xor" "xcorr"		;user-defined
		 "abs" "ceil" "floor"	;built-in
		 "fprintf"		;built-in
		 "mod" "rem" "round"	;built-in
		 "dot" "cross" "prod" "conv" ;built-in
		 "resample"		     ;user-defined
		 "fir1"
		 "fopen" "fclose"
		 "fread" "fwrite"
		 "usage"		;built-in
		 "nargchk"		;user-defined
		 ))
	      "\\)" "\\>")
      "Matches Octave Common Functions.")

(provide 'octave-patterns)
