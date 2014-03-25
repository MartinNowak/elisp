;;; cc-php-js-cs.el --- CC-derived modes for JavaScript, PHP, C#

;; Copyright (C) 2006, 2009  Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>
;; Keywords: languages
;; URL: http://www.loveshack.ukfsn.org/emacs/
;; Created: 2009-10
;; $Revision: 2$

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This add-on to CC mode provides add PHP, JavaScript, and C#
;; support.  The support is preliminary and probably needs attention
;; from people more interested in support for those languages.  See
;; some `fixme's below.  One of the problems with PHP is that I
;; couldn't find a proper definition of the language.  Note that only
;; the C-like block syntax is supported for PHP.

;; I originally did the work (initially for PHP) a few years ago as a
;; patch to CC mode, which was harder to deal with, but I couldn't
;; make the add-on work with the then-current CC mode.  I don't
;; currently have much use for it (and never had any use for C-hash).
;; The CC mode/Emacs maintainers aren't interested in this support,
;; unfortunately.

;; There are various other modes supporting these languages which
;; don't attempt to integrate properly with CC mode and apparently
;; have various lexical problems with comments, regexp notation, &c
;; which this mode doesn't (apart from PHP here-docs).  It's probably
;; best to look under http://www.emacswiki.org for references to other
;; modes, but take commentary there with a pinch of salt.

;; The CC mode structure is a nightmare, which makes this difficult to
;; compile -- and it doesn't work interpreted.  (The `derived mode'
;; example referred to in the CC mode source doesn't work, at least
;; with recent source, and isn't actually a derived mode.)  This has
;; to be compiled in a directory containing the CC mode cc-*.el files,
;; since some of hem are loaded explicitly.  It has only been tested
;; with the CC mode from Emacs 22.2.  It doesn't work with Emacs 21,
;; but see http://www.loveshack.ukfsn.org/emacs/index.html#cc-php-js
;; for Emacs 21 support, and maybe a byte-compiled version of this
;; file.

;; Note that this only deals with raw PHP code, not PHP embedded in
;; HTML, so it may not make sense to associate .php files with
;; php-mode.  multi-mode.el can cope with such embedding (see
;; http://www.loveshack.ukfsn.org/emacs/html-php.el) but not currently
;; with nXML mode, though I'll probably fix that.

;;; Code:

(eval-when-compile
  (require 'cl)
  (let ((load-path
	 (if (and (boundp 'byte-compile-dest-file)
		  (stringp byte-compile-dest-file))
	     (cons (file-name-directory byte-compile-dest-file) load-path)
	   load-path)))
    (load "cc-bytecomp" nil t)))

(require 'cc-mode)

(put 'php-mode 'c-mode-prefix "php-")
(put 'js-mode 'c-mode-prefix "js-")
(put 'csharp-mode 'c-mode-prefix "csharp-")

(eval-when-compile
  (c-add-language 'js-mode 'c-mode)
  (c-add-language 'php-mode 'c-mode)
  (c-add-language 'csharp-mode 'c-mode))


;; cc-langs.el-type stuff

(c-lang-defconst c-symbol-start
  (php js) (concat "[" c-alpha "_$]")
  csharp (concat "[" c-alpha "@_]"))

(c-lang-defconst c-symbol-chars
  csharp (concat c-alnum "_"))

(c-lang-defconst c-identifier-ops
  php '((left-assoc "::")
	(prefix "::")))

(c-lang-defconst c-multiline-string-start-char
  (php js) t)

(c-lang-defconst c-opt-cpp-prefix
  ;; Fixme: probably has to go in cc-fonts
  php "\\s-*\\(?:<\\?php\\|\\?>\\|<%=?\\|%>\\)")

(c-lang-defconst c-opt-cpp-start
  php (c-lang-const c-opt-cpp-prefix))

(c-lang-defconst c-assignment-operators
  php (append (c-lang-const c-assignment-operators) '(".="))
  js  (append (c-lang-const c-assignment-operators) '(">>>=")))

(c-lang-defconst c-operators
  (php js csharp) `(;; Preprocessor.
      ,@(when (c-lang-const c-opt-cpp-prefix)
	  `((prefix "#")
	    (left-assoc "##")))
      ;; Primary.
      ,@(c-lang-const c-identifier-ops)
      (left-assoc "." "->")
      (postfix "++" "--" "[" "]" "(" ")")
      ;; Unary.
      (prefix "++" "--" "+" "-" "!" "~"
	      ,@(cond ((c-major-mode-is 'php-mode)
		       '("new"))
		      ((c-major-mode-is 'js-mode)
		       '("new" "typeof" "void" "delete" "clone"))
		      ((c-major-mode-is 'csharp)
		       ((prefix "base" "ref" "out" "typeof" "checked"
				"unchecked" "default" "sizeof"))))
	      ,@(when (c-major-mode-is 'php-mode) '("&" "@"))
	      "(" ")"			; Cast.
	      )
      ;; Multiplicative.
      (left-assoc "*" "/" "%")
      ;; Additive.
      (left-assoc "+" "-")
      ;; Shift.
      (left-assoc "<<" ">>" ,@(when (c-major-mode-is 'js-mode)
				'(">>>")))
      ;; Relational.
      (left-assoc "<" ">" "<=" ">="
		  ,@(when (c-major-mode-is 'js-mode)
		      '("instanceof" "in"))
		  ,@(when (c-major-mode-is 'csharp-mode)
		      '("is" "as" "in")))
      ;; Equality.
      (left-assoc "==" "!="
		  ,@(when (c-major-mode-is 'js-mode) '("===" "!==")))
      ;; Bitwise and.
      (left-assoc "&")
      ;; Bitwise exclusive or.
      (left-assoc "^" ,@(when (c-major-mode-is 'php-mode) '("xor")))
      ;; Bitwise or.
      (left-assoc "|")
      ;; Logical and.
      (left-assoc "&&" ,@(when (c-major-mode-is 'php-mode) '("and")))
      ;; Logical or.
      (left-assoc "||" ,@(when (c-major-mode-is 'php-mode) '("or")))
      ;; Conditional.
      (right-assoc-sequence "?" ":")
      ;; Assignment.
      (right-assoc ,@(c-lang-const c-assignment-operators))
      ;; Sequence.
      (left-assoc ",")))

(c-lang-defconst c-other-op-syntax-tokens
  php (append '("&") (c-lang-const c-other-op-syntax-tokens)))

(c-lang-defconst c-paragraph-start
  php "\\(@[a-zA-Z]+\\>\\|$\\)")

(c-lang-defconst c-primitive-type-kwds
  php '("int" "integer" "double" "real" "float" "bool" "boolean"
	"string" "object" "char" "mixed")
  csharp '("bool" "decimal" "sbyte" "byte" "short" "ushort"  "int" "uint"
	   "long" "ulong" "char" "float" "double" "object" "string" "void"))

(c-lang-defconst c-primitive-type-prefix-kwds
  (js php csharp) nil)

(c-lang-defconst c-type-prefix-kwds
  csharp '("enum" "struct"))

(c-lang-defconst c-type-modifier-kwds
  csharp '("const" "volatile" "readonly"))

(c-lang-defconst c-class-decl-kwds
  csharp '("struct"))

(c-lang-defconst c-brace-list-decl-kwds
  (php js) nil)

(c-lang-defconst c-other-block-decl-kwds
  csharp '("namespace"))

(c-lang-defconst c-typeless-decl-kwds
  php (append (c-lang-const c-class-decl-kwds) '("function"))
  js (append (c-lang-const c-class-decl-kwds)
	     '("const"			; Mozilla extension
	       "var" "function")))

(c-lang-defconst c-modifier-kwds
  php '("static" "const" "private" "protected" "public" "final" "global"
	"abstract")
  csharp '("using" "new" "public" "protected" "internal" "private" "abstract"
	   "sealed" "static" "event" "const" "params" "override"))

(c-lang-defconst c-block-decls-with-vars
  csharp '("enum" "struct"))

(c-lang-defconst c-postfix-decl-spec-kwds
  php '("extends" "implements"))

(c-lang-defconst c-type-list-kwds
  php '("extends" "interface" "implements")
  js '("import" "export"))		; Mozilla extensions

;; Fixme: This doesn't work.
;; (c-lang-defconst c-colon-type-list-kwds
;;   csharp '("enum"))

(c-lang-defconst c-block-stmt-1-kwds
  js '("do" "else" "finally" "try")
  php '("do" "else" "elseif" "try" "finally")
  csharp '("do" "else" "try" "finally" "checked" "unchecked"))

(c-lang-defconst c-block-stmt-2-kwds
  php '("for" "if" "switch" "while" "declare" "foreach"
	;; Fixme: check catch/catch all
	"catch")
  js '("for" "if" "switch" "while" "catch" "with")
  csharp '("if" "switch" "while" "for" "foreach" "catch" "with" "lock"
	   "using"))

(c-lang-defconst c-simple-stmt-kwds
  php '("break" "continue" "return" "echo" "die" "exit" "include"
	"include_once" "print" "require" "require_once" "define" "throw")
  js '("include"			; Mozilla extension
       "break" "continue" "goto" "return" "throw")
  csharp '("break" "continue" "goto" "return" "throw" "yield break"
	   "yield return"))

(c-lang-defconst c-before-label-kwds
  (java pike js) '("goto" "break" "continue"))

(c-lang-defconst c-constant-kwds
  ;; Fixme:  There should probably be more.
  php '("__LINE__" "__FILE__" "__FUNCTION__" "__CLASS__" "__METHOD__" "NULL")
  (js csharp) '("true" "false" "null"))

(c-lang-defconst c-primary-expr-kwds
  js '("this") ; Not really a keyword, but practically works as one.
  csharp '("this" "base"))

(c-lang-defconst c-lambda-kwds
   ;; Fixme:  This breaks normal functions.
   js '("function"))

(c-lang-defconst c-other-kwds
  php '("isset" "list" "array" "unset" "exception" "eval" "as"
	"endfor" "endforeach" "endif" "endswitch" "endwhile")
  ;; Reserved for future use (ECMA):
  js '("abstract" "enum" "int" "short" "boolean" "export" "interface"
       "static" "byte" "extends" "long" "super" "char" "final" "native"
       "synchronized" "class" "float" "package" "throws"
       ;; "const"
       "goto" "private" "transient" "debugger" "implements" "protected"
       "volatile" "double"
       ;; "import"
       "public"))

(c-lang-defconst c-type-decl-prefix-key
  php "&")

(c-lang-defconst c-recognize-colon-labels
  (js csharp) t)

(c-lang-defconst c-label-prefix-re
  js "\\([{},]+\\)")

(c-lang-defconst c-doc-comment-start-regexp
  "Regexp to match the start of documentation comments."
  php "{@[a-z]+")

;; Support for PHP

;; Fixme:  Is there anything useful we can do with the Algol-ish
;; syntax?
;; Fixme:  PEAR codings standards support.

(defvar php-mode-abbrev-table nil
  "Abbreviation table used in PHP mode buffers.")
(c-define-abbrev-table 'php-mode-abbrev-table
  '(("else" "else" c-electric-continued-statement 0)
    ("while" "while" c-electric-continued-statement 0)))

;; Fixme: Deal with here-docs -- copy stuff from sh-script.el
(defconst php-mode-syntactic-keywords
  '(
    ;; (Pseudo-)processing instructions
    ("\\(<\\)\\?\\(?:\\-*php\\)?\\([[:space:]\n]\\)" (1 "!") (2 "!"))
    ("[?%]>" (0 "!"))
    ("\\(<\\)%=?\\([[:space:]\n]\\)" (1 "!") (2 "!"))))

(defconst php-font-lock-keywords-1 (c-lang-const c-matchers-1 php))
(defconst php-font-lock-keywords-2 (c-lang-const c-matchers-2 php))
(defconst php-font-lock-keywords-3 (c-lang-const c-matchers-3 php))
(defvar php-font-lock-keywords php-font-lock-keywords-3)

(defun php-font-lock-keywords-2 ()
  (c-compose-keywords-list php-font-lock-keywords-2))
(defun php-font-lock-keywords-3 ()
  (c-compose-keywords-list php-font-lock-keywords-3))
(defun php-font-lock-keywords ()
  (c-compose-keywords-list php-font-lock-keywords))

(defvar cc-imenu-php-generic-expression
 '(("Functions"
    "^\\s-*function\\s-+&?\\([[:alnum:]_]+\\)\\s-*(" 1)
   ("Classes"
    "^\\s-*class\\s-+\\([[:alnum:]_]+\\)\\s-*" 1)))

;; Fixme:  This isn't working to get javadoc highlighting in php-mode.
(let ((style (cdr (assq 'c-doc-comment-style c-fallback-style))))
  (unless (assq 'php-mode style)
    (c-set-stylevar-fallback 'c-doc-comment-style
			     (cons '(php-mode . javadoc) style))))

(defvar php-mode-syntax-table
  (let ((table (copy-syntax-table c-mode-syntax-table)))
    (modify-syntax-entry ?# "< b" table)
    (modify-syntax-entry ?` "\"" table)
    table))

(defvar php-mode-map (c-make-inherited-keymap))
(easy-menu-define c-php-menu php-mode-map "PHP Mode Commands"
		  (cons "PHP"(c-lang-const c-mode-menu php)))

;; Fixme: Add manual lookup stuff (what manual?).
;; Fixme: Should probably have inferior JavaScript mode.

;;;###autoload
(define-derived-mode php-mode c-mode "PHP"
  "Major mode for editing PHP code.
It doesn't cope with the `alternative' (Algol-ish) syntax, only
the C-like one.

Note that this is specifically for actual PHP code and doesn't cope
with it being embedded in HTML -- that requires a multiple-major-modes
package.

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `php-mode-hook'.

\\{php-mode-map}"
  :group 'c				; following other CC modes
  (c-initialize-cc-mode t)
  (c-init-language-vars php-mode)
  (c-common-init 'php-mode)
  (easy-menu-add c-php-menu)
  (cc-imenu-init cc-imenu-php-generic-expression)
  (set (make-local-variable 'font-lock-syntactic-keywords)
       php-mode-syntactic-keywords)
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  (c-update-modeline))

;; Support for JavaScript

(defconst js-mode-syntax-table (copy-syntax-table c-mode-syntax-table))

(defconst js-mode-syntactic-keywords
  `((,(concat "[=\(,]\\s-*"		; only assignment or arg list
	      "\\(/\\)"			; initial slash
	      "\\(?:\\\\.\\|[^*/]\\)"	; initially either escaped
					; char or char which isn't
					; part of comment start
	      "\\(?:\\\\.\\|[^/]\\)*" ; repeated escaped char or non-slash
	      "\\(?:/[gim]*\\([gim]\\)\\|\\(/\\)\\)")	; final slash with
						; optional qualifier
     (1 "|") (2 "|" nil t) (3 "|" nil t)))
  "`font-lock-syntactic-keywords' for JavaScript.
Deals with /.../ regexp patterns.")

(defconst js-font-lock-keywords-1 (c-lang-const c-matchers-1 js))
(defconst js-font-lock-keywords-2 (c-lang-const c-matchers-2 js))
(defconst js-font-lock-keywords-3 (c-lang-const c-matchers-3 js))
(defvar js-font-lock-keywords js-font-lock-keywords-3)

(defun js-font-lock-keywords-2 ()
  (c-compose-keywords-list js-font-lock-keywords-2))
(defun js-font-lock-keywords-3 ()
  (c-compose-keywords-list js-font-lock-keywords-3))
(defun js-font-lock-keywords ()
  (c-compose-keywords-list js-font-lock-keywords))

;; Top-level functions only (fixme?) .
(defvar cc-imenu-js-generic-expression
  `((nil ,(concat "^function\\s-+\\([" c-alnum "_]+\\)") 1)))

(defvar js-mode-map (c-make-inherited-keymap))
(easy-menu-define c-js-menu js-mode-map "JavaScript Mode Commands"
		  (cons "JavaScript" (c-lang-const c-mode-menu js)))

;; Fixme: Should probably have inferior JavaScript mode.

;;;###autoload
(define-derived-mode js-mode c-mode "JS"
  "Major mode for editing JavaScript/ECMAScript code.

This is intended to support the definition in ECMA standard 262
<URL:http://www.ecma-international.org/publications/standards/ECMA-262.HTM>
with Mozilla extensions
<URL:http://developer.mozilla.org/en/docs/Core_JavaScript_1.5_Reference>.

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `js-mode-hook'.

\\{js-mode-map}"
  (c-initialize-cc-mode t)
  (c-init-language-vars js-mode)
  (c-common-init 'js-mode)
  (easy-menu-add c-js-menu)
  (cc-imenu-init cc-imenu-js-generic-expression)
  (set (make-local-variable 'font-lock-syntactic-keywords)
       js-mode-syntactic-keywords)
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  (c-run-mode-hooks 'c-mode-common-hook)
  (c-update-modeline))

(defalias 'javascript-mode 'js-mode)

;; Support for C#

(defconst csharp-font-lock-keywords-1 (c-lang-const c-matchers-1 csharp))
(defconst csharp-font-lock-keywords-2 (c-lang-const c-matchers-2 csharp))
(defconst csharp-font-lock-keywords-3 (c-lang-const c-matchers-3 csharp))
(defvar csharp-font-lock-keywords csharp-font-lock-keywords-3)

(defun csharp-font-lock-keywords-2 ()
  (c-compose-keywords-list csharp-font-lock-keywords-2))
(defun csharp-font-lock-keywords-3 ()
  (c-compose-keywords-list csharp-font-lock-keywords-3))
(defun csharp-font-lock-keywords ()
  (c-compose-keywords-list csharp-font-lock-keywords))

(defvar csharp-mode-syntax-table
  (funcall (c-lang-const c-make-mode-syntax-table csharp))
  "Syntax table used in C# mode buffers.")

(defvar csharp-mode-abbrev-table nil
  "Abbreviation table used in C# mode buffers.")
(c-define-abbrev-table 'js-mode-abbrev-table
  '(("else" "else" c-electric-continued-statement 0)
    ("while" "while" c-electric-continued-statement 0)
    ("catch" "catch" c-electric-continued-statement 0)
    ("finally" "finally" c-electric-continued-statement 0)))

(defvar csharp-mode-map (c-make-inherited-keymap))

(defconst csharp-mode-syntactic-keywords
  '(("\\(@\\)\"\\(?:\"\"\\|[^\"]\\)+\\(\"\\)"
    (1 "|") (2 "|")))
  "`font-lock-syntactic-keywords' for C#.
Deals with @\"...\" literals.")

(defvar csharp-mode-map (c-make-inherited-keymap))
(easy-menu-define c-csharp-menu csharp-mode-map "C# Mode Commands"
		  (cons "C#" (c-lang-const c-mode-menu csharp)))
;;;###autoload
(defun csharp-mode ()
  "Major mode for editing C# code.

This is intended to support the definition in ECMA standard 334
<URL:http://www.ecma-international.org/publications/standards/ECMA-334.HTM>.

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `csharp-mode-hook'.

Key bindings:
\\{csharp-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (c-initialize-cc-mode t)
  (set-syntax-table csharp-mode-syntax-table)
  (setq major-mode 'csharp-mode
 	mode-name "C#"
 	local-abbrev-table csharp-mode-abbrev-table
	comment-start "// "
	comment-end "")
  (use-local-map csharp-mode-map)
  (c-init-language-vars csharp-mode)
  (c-common-init 'csharp-mode)
  (easy-menu-add c-csharp-menu)
  (cc-imenu-init cc-imenu-java-generic-expression) ; fixme
  (set (make-local-variable 'font-lock-syntactic-keywords)
       csharp-mode-syntactic-keywords)
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  (c-run-mode-hooks 'c-mode-common-hook 'csharp-mode-hook)
  (c-update-modeline))

(add-to-list 'auto-mode-alist '("\\.php\\'" . php-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js-mode))
(add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-mode))

(provide 'cc-php-js-cs)
;;; cc-php-js-cs.el ends here
