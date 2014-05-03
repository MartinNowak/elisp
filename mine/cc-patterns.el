;;; cc-patterns.el --- language patterns for C, C++, etc.
;; Copyright (C) 2007 Per Nordlöw <per.nordlow@gmail.com>
2
;; ============================================================================

;; C PreProcessor Patterns

(defconst cpp-prefix-regexp
  (concat
   "^[ \\t]*" "#" "[ \\t]*")
  "Matches C PreProcessor (CPP) start pattern.")

(defconst cpp-include-regexp
  (concat
   "\\(include\\))" "[ \\t]*" "[<\"]" "\\([^>\"]+\\)" "[>\"]")
  "Matches C PreProcessor (CPP) #include statement.")

(defconst cpp-ifdef-regexp
  (concat
   cpp-prefix-regexp "\\(ifdef\\)" "[ \\t]*" "\\([^ \\t]+\\)")
  "Matches C PreProcessor (CPP) #ifdef statement.")

(defconst cpp-ifndef-regexp
  (concat
   cpp-prefix-regexp "\\(ifndef\\)" "[ \\t]*" "\\([^ \\t]+\\)")
  "Matches C PreProcessor (CPP) #ifndef statement.")

(defconst cpp-define-regexp
  (concat
   cpp-prefix-regexp "\\(define\\)" "[ \\t]*" "\\([^ \\t]+\\)")
  "Matches C PreProcessor (CPP) #define statement.")

(defconst cpp-endif-regexp
  (concat
   cpp-prefix-regexp "\\(endif\\)")
  "Matches C PreProcessor (CPP) #endif statement.")

(defconst cpp-statement-regexp
  (regexp-from-alts (list cpp-include-regexp
                          cpp-ifdef-regexp
                          cpp-ifndef-regexp
                          cpp-define-regexp
                          cpp-endif-regexp) t)
  "Matches any C PreProcessor (CPP) statements.")

;; ============================================================================

;; C Programming Language Patterns

(defun c-op-assignment (&optional mode)
  "C-Like Language Assignment Operators."
  (let ((mode (or mode major-mode)))
    (append (list "+=" "-="             ;Assignment Additive
                  "*=" "/=" "%="        ;Assignment Multiplicative
                  "^=" "&="             ;Assignment Bitwise Logic
                  "<<=" ">>="           ;Assignment Bitwise Shift
                  "=")                  ;Assignment
            (when (eq mode 'd-mode)
              (list "^^="
                    "~=")))))

(defconst c-op-inc-dec
  '("++"                            ;Increase
    "--"                            ;Decrease
    )
  "C Language Assignment Operators Inc Dec.")

(defun c-op-assignment-regexp (&optional mode paren)
  "C-Like Language Assignment Operators."
  (let ((mode (or mode major-mode)))
    (concat
     "[^!=<>]"                 ;dont' match ==, <=, >=
     (when paren "\\(")
     (rx (| ;; (: (not (any ?= ?! ?> ?<))
          ;;    (group "=")
          ;;    (not (any ?> ?=)))
          "++" "--"
          "+=" "-="                     ;Assignment Additive
          "*=" "/=" "%="                ;Assignment Multiplicative
          "^=" "&="                     ;Assignment Bitwise Logic
          "<<=" ">>="                   ;Assignment Bitwise Shift
          "^^=" "~="                    ;d-mode only
          "="
          ;; (: (regexp "\\(?<![=!<>]\\)") ;negative look-behind
          ;;    "="
          ;;    (regexp "\\(?![=>]\\)") ;negative look-ahead
          ;;    )
          ))
     (when paren "\\)")
     "[^=<>]"                 ;dont' match ==, <=, >=
     )))
;; Use: (c-op-assignment-regexp)
;; Use: (c-op-assignment-regexp 'd-mode)
;; Use: (c-op-assignment-regexp 'd-mode t)

(defconst c-op-member
  (list "->" "."			;Member
	)
  "C Language Member Operators.")

(defconst c-op-others
  (list "-" "+"				;Add, Subtract
	"&&" "||" "!"			;Logical AND, OR, NOT
	"&" "|" "~"			;Bitwise AND, OR, NOT
	"^"				;Bitwise XOR

	"<<" ">>"			;Bitwise Shift

	"*" "/" "%"			;Multiplicative

	"<" ">"				;Less/Great Than Comparison
	"==" "!="			;Comparison: Equal or Not Equal
	"<=" ">="	       ;Less/Great Then or Equal To Comparison

	;;","				;Skip Comma
	)
  "C Language Other Operators.")

(defconst sh-operators
  (list "&&" "||"                      ;Logic
        "==" "!="			;Comparison: Equal or Not Equal
        "="
        "&"
	)
  "Shell Operators.")

(defun c-op-all (&optional mode)
  "C Language All Operators."
  (append (c-op-assignment mode)
	  c-op-inc-dec
	  c-op-member
	  c-op-others
	  ))

(defconst c-parenthesises
  (list "(" ")"
	)
  "C Language Parenthesises.")

(defconst c-braces
  (list "[" "]"				;Array Indexing
	"{" "}"				;Curly Braces
	)
  "C Language Braces.")

(defconst c-separators
  (list "," ";"				;Statement Separator
	)
  "C Language Statement Separators.")

;; The reserved words of C++ may be conveniently placed into several groups. In the first group we put those that were also present in the C programming language and have been carried over into C++. There are 32 of these, and here they are:
(defconst c-keywords-list
  (list
   "auto" "const" "double" "float" "int" "short" "struct" "unsigned"
   "break" "continue" "else" "for" "long" "signed" "switch" "void"
   "case" "default" "enum" "goto" "register" "sizeof" "typedef" "volatile"
   "char" "do" "extern" "if" "return" "static" "union" "while")
  "C Language Keywords.")

(defconst c-builtin-types
  (list
   "float" "double"
   "char" "int" "short"
   "unsigned" "signed"
   "long"
   "long long"
   "size_t"
   "uint8_t" "uint16_t" "uint32_t" "uint64_t"
   "int8_t" "int16_t" "int32_t" "int64_t"
   )
  "C Builtin Types.")

;; ============================================================================

;; C++ Programming Language Patterns

;; There are another 30 reserved words that were not in C, are therefore new to C++, and here they are:
(defconst c++-new-keywords-list
  (list
   "asm" "dynamic_cast" "namespace" "reinterpret_cast" "try"
   "bool" "explicit" "new" "static_cast" "typeid"
   "catch" "false" "operator" "template" "typename"
   "class" "friend" "private" "this" "using"
   "const_cast" "inline" "public" "throw" "virtual"
   "delete" "mutable" "protected" "true" "wchar_t"
   )
  "C++ Language Only Reserved Words.")

;; The following 11 C++ reserved words are not essential when the standard ASCII character set is being used, but they have been added to provide more readable alternatives for some of the C++ operators, and also to facilitate programming with character sets that lack characters needed by C++.
(defconst c++-extra-keywords-list
  (list
   "and" "bitand" "compl" "not_eq" "or_eq" "xor_eq"
   "and_eq" "bitor" "not" "or" "xor"
   )
  "C++ Language Extra Reserved Words.")

(defconst c++-keywords-list
  `(,@c-keywords-list
    ,@c++-new-keywords-list
    ,@c++-extra-keywords-list)
  "C++ Language Reserved Words."
  )

(defconst c++11-new-keywords-list
  (list
   "alignas" "alignof"
   "char16_t" "char32_t"
   "constexpr"
   "decltype"

   "override" "final"

   "noexcept" "nullptr"
   "auto"
   "thread_local"
   "static_assert"
   )
  "C++11 Language Extra Reserved Words.")

(defconst c++11-keywords-list
  `(
    c++-keywords-list
    ,@c++11-new-keywords-list)
  "C++11 Language Reserved Words."
  )

(defconst c++-op-member
  '(".*" "->*" "::")
  "C++ Language Member Operators (not in C).")

(defconst c++-op-bitwise
  '("and" "or" "not" "bitand" "bitor" "bitnot")
  "C/C++ Language Logic and Bitwise Operators.")

(provide 'cc-patterns)
