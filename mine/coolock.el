;;; coolock.el - Ultra fancy extensions to font locking. Could need some performance love, if possible.
;; Author: Per Nordlöw

;;; TODO: Change order of D highlighting: 1: (comment t), 2: (opBinary() append), 3: (function call append)
;;; TODO: Add overlay .length to .$ in d-mode
;;; TODO: Add support for c++11 lambda expressions.
;;; TODO: Support hexadecimal floating point literals: 0x1.fffffffffffffp1023
;;; TODO: 0x800fffffffffffffull
;;; TODO: Highlight template type arguments using bold font-lock-type-face template WeightedNode(Value, Label = string, Weight = double)

(require 'pnw-regexps)
(require 'obarray-utils)
(require 'power-utils)
(require 'sh-script)
(require 'syntax)
(require 'font-lock)
(require 'executable)
(require 'rx)
(require 'font-lock-extras)
(require 'cc-assist)
(require 'cc-utils)
(eval-when-compile (require 'cl))

;;; D
(when nil
  ;; (font-lock-remove-keywords 'd-mode '("\\([0-9]+#[0-9a-fA-F_]+#\\)" '(1 font-lock-constant-face t)))
  (font-lock-replace-keywords 'd-mode
                              '("\\([0-9]+#[0-9a-fA-F_]+#\\)" '(1 font-lock-constant-face t))
                              '("\\([0-9]+#[0-9a-fA-F_]+#\\)" '(1 font-lock-number-face t))))


(defun coolock/d-asm ()
  "Return D-Mode Assembler Highlighting."
  (list
   (cons
    "\\_<\\(asm\\)[[:space:]\n]*{\\([^}]*\\)}"
    ;; (rx (: symbol-start
    ;;        (group "asm")
    ;;        (* (| space "\n"))
    ;;        "{"
    ;;        (group (* anything))
    ;;        "}")
    ;;     )
    '((1 'font-lock-keyword-face keep)
      (2 'shadow t)
      ))))
(defun coolock/d-private-member-variable ()
  "Return D-Mode Private Member Highlighting."
  (list
   (cons
    (rx symbol-start
        (group ?_ (1+ (regex "[[:alnum:]]")))
        symbol-end)
    '((1 'font-lock-private-variable-face append)
      ))))
(defun coolock/d-scope-or-version-constant ()
  "Return D-Mode Constant given as argument to scope or version keyword."
  (list
   (cons
    (rx symbol-start
        (| "scope"
           "version")
        (* space)
        "("
        (* space)
        (group (+ (syntax word)))
        (* space)
        ")"
        )
    '((1 'font-lock-constant-face append)
      ))))

(defun coolock/d-alias ()
  "D-Mode alias definition."
  (list
   (cons
    (rx symbol-start
        "alias"
        (+ space)
        (group (+ (syntax word)))
        (* space)
        "="
        )
    '((1 'font-lock-alias-definition-face t)
      ))))

(defun coolock/d-const-or-immutable ()
  "D-Mode const or immutable definition."
  (list
   (cons
    (rx symbol-start
        (| "const"
           "immutable"
           "enum")
        (+ space)
        (group (+ (syntax word)))
        (* space)
        "="
        )
    '((1 'font-lock-constant-face t)
      ))))

(defun coolock/d-dollar ()
  (list
   (cons (concat $< (regexp-quote "$") $>)
         '((1 'font-lock-constant-face append)
           ))))
(defun coolock/d-operators ()
  (list
   (cons (concat (rx symbol-start
                     (regexp "[!~]")
                     symbol-end
                     (regexp "[^=]")))
         '((1 'font-lock-operator-concat-face append)
           ))))

(defun coolock/hash-bang ()
  (list
   (cons "\\`\\(#!.*/\\([^ 	\n]+\\)\\)"
         '((1 'font-lock-comment-face t)
           (2 'font-lock-operator-face keep)))))
;; (car (car (coolock/hash-bang)))

;;; C Number
;;; TODO: Merge these into one regexp with 3+3+3 matchers.
(defun coolock/c-number (&optional mode)
  "Return Basic C-Style Number Literal Syntax Highlighting."
  (list
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (c-number-float-regexp mode)
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (c-number-dec-regexp mode)
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))
   ;; NOTE: needs to be before matching C operator '.' below
      (cons (c-number-hex-regexp mode)
         '((1 'font-lock-number-passive-face keep)
           (2 'font-lock-number-face keep)
           (3 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))
   ))

(defun coolock/d-number (&optional mode)
  "Return Basic D-Style Number Literal Syntax Highlighting."
  (list
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (number-bin-regexp mode)
         '((1 'font-lock-number-passive-face keep)
           (2 'font-lock-number-face keep)
           ))))

;;; TODO: Merge these into one regexp.
(defun coolock/advanced-number (&optional mode)
  "Return Advanced C-Style Number Literal Syntax Highlighting."
  (list
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (c-number-float-regexp mode)
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))

   ;; number literal decimal - 4 to 6 digits
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (c-number-dec-4to6-regexp mode)
         '((1 'font-lock-number-alt-face keep)
           (2 'font-lock-number-face keep)
           (3 'font-lock-number-passive-face keep)
           ))

   ;; number literal decimal - 7 to 9 digits
   ;; NOTE: needs to be before matching C operator '.' below
   (cons c-number-dec-7to9-regexp
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-alt-face keep)
           (3 'font-lock-number-face keep)
           (4 'font-lock-number-passive-face keep)
           ))

   ;; number literal decimal - 10 to 12 digits
   ;; NOTE: needs to be before matching C operator '.' below
   (cons c-number-dec-10to12-regexp
         '((1 'font-lock-number-alt-face keep)
           (2 'font-lock-number-face keep)
           (3 'font-lock-number-alt-face keep)
           (4 'font-lock-number-face keep)
           (5 'font-lock-number-passive-face keep)
           ))

   ;; number literal decimal - 13 to 15 digits
   ;; NOTE: needs to be before matching C operator '.' below
   (cons c-number-dec-13to15-regexp
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-alt-face keep)
           (3 'font-lock-number-face keep)
           (4 'font-lock-number-alt-face keep)
           (5 'font-lock-number-face keep)
           (6 'font-lock-number-passive-face keep)
           ))

   ;; number literal decimal - 16 to 18 digits
   ;; NOTE: needs to be before matching C operator '.' below
   (cons c-number-dec-16to18-regexp
         '((1 'font-lock-number-alt-face keep)
           (2 'font-lock-number-face keep)
           (3 'font-lock-number-alt-face keep)
           (4 'font-lock-number-face keep)
           (5 'font-lock-number-alt-face keep)
           (6 'font-lock-number-face keep)
           (7 'font-lock-number-passive-face keep)
           ))

   ;; number literal decimal - 19 to 21 digits
   ;; NOTE: needs to be before matching C operator '.' below
   (cons c-number-dec-19to21-regexp
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-alt-face keep)
           (3 'font-lock-number-face keep)
           (4 'font-lock-number-alt-face keep)
           (5 'font-lock-number-face keep)
           (6 'font-lock-number-alt-face keep)
           (7 'font-lock-number-face keep)
           (8 'font-lock-number-passive-face keep)
           ))

   ;; number literal decimal - ordinary
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (c-number-dec-regexp mode)
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))

   ;; number literal hexadecimal (byte-group-colored)
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (c-number-hex-fancy-regexp mode)
         '((1 'font-lock-number-passive-face keep)
           (2 'font-lock-number-face keep)
           (3 'font-lock-number-alt-face keep)
           (4 'font-lock-number-face keep)
           (5 'font-lock-number-alt-face keep)
           (6 'font-lock-number-face keep)
           (7 'font-lock-number-alt-face keep)
           (8 'font-lock-number-face keep)
           (9 'font-lock-number-alt-face keep)
           (10 'font-lock-number-passive-face keep)
           ))
   ))

;;; TODO: Merge these into one regexp with 2+2+3 matchers.
(defun coolock/haskell-number ()
  "Return Basic Haskell-Style Number Literal Syntax Highlighting."
  (list
   ;; NOTE: needs to be before matching C operator '.' below
   (cons haskell-number-float-regexp
         '((1 'font-lock-number-face keep)
           ))
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (number-dec-regexp 'haskell-mode)
         '((1 'font-lock-number-face keep)
           ))
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (number-hex-regexp 'haskell-mode)
         '((1 'font-lock-number-passive-face keep)
           (2 'font-lock-number-face keep)
           ))
   ))

(defun coolock/c-switch-case-regexp ()
  "C/C++ switch case."
  (cons (concat Y< "case" "[[:blank:]]+"
                $< "[[:word:]_]+" $> _*
                $< ":"    $>)
        '((1 'font-lock-constant-face keep)
          (2 'font-lock-operator-face keep)
          )))

(defconst coolock/c-character-literal-regexp
  (concat "'" $< ".+?" $> "'")
  "C/C++ character literal 'a', 'b', etc."
  )

(defconst coolock/c-printf
  (concat $<

          "%"                           ;initiator

          "[\\+-]?"                     ;flag characters

          "[0-9\\*]*"                   ;field width
          "\\.?" "[0-9\\*]*"            ;precision

          ;;length modifier
          "\\(?:"
          "[hl]" "\\{" "0,2" "\\}" "\\|"
          "[Lqjzt]?"
          $>

          $>

          $<
          "[diouxXeEfFgGaAcsCSpnm]"     ;conversion specifier
          $>
          )
  "C printf()), fprintf(), sprintf(), snprintf(), vprintf(), vfprintf(), vsprintf(). See printf(3) manual page."
  )

;;; ===========================================================================

(defconst coolock/c-function-call
  (concat Y< $< "[[:word:]_]+" $> Y> L* "(")
  "C function call 1 matcher regexp.")

(defconst coolock/c++-function-call
  (concat Y< $< "[[:word:]_]+" $> Y> "\\(?:<.+>\\)?" L* "(")
  "C++ (possibly template) function call 0 matcher regexp.")

(defconst coolock/d-function-call
  (concat Y< $< "[[:word:]_]+" "!?" $> Y> L* "(")
  "D function call 1 matcher regexp.")

;;; ===========================================================================

(defconst coolock/c-sizeof-expression
  (concat Y< "sizeof" _*
          "(" _*
          $< "[[:word:]_]+" $>    ;argument
          _* ")")
  "C/C++ sizeof() expression. Not that relevant as the argument
  can be both a variable and a type" )

;;; TODO: To replace in|out entry in ada-mode.el
(defconst coolock/ada-variable-or-parameter
  (rx symbol-start
      (group-n 1
               (regexp "[[:word:]_]+")
               (0+
                (* space)
                ","
                (* space)
                (regexp "[[:word:]_]+")))
      (* space)
      ":"
      (* space)
      (group-n 2 (regexp "[[:word:]_]+"))
      )
  "Ada Named Parameter Assignment")

(defconst coolock/ada-named-parameter-assignment
  (concat Y< $< "[[:word:]_]+" $> Y>
          L*
          $< "=>" $>
          ) "Ada Named Parameter Assignment")

(defconst c++11-auto-variable-definition
  (concat Y< "auto" L+ $< CID $> L*
          "[^(]" ;skips expressions such as: auto calculate(FuncType&& func) -> decltype(func())
          ) "C++11 Variable Name and Operator in Assignment.")

(defconst c++11-nullptr
  (concat Y< $< "nullptr" $> Y>)
  "C++11 nullptr.")

(defconst c++11-dots
  (concat $< "\\.\\.\\." $>)
  "C/C++ dots.")

(defun coolock/c-op-member (&optional match)
  "Return C member operator regexp."
  (concat $< (unless match "?:")
          (regexp-quote-alts c-op-member)
          $>))

(defun coolock/c-op-assignment (&optional match)
  "Return C/C++ assignment operator regexp."
  (concat $< (unless match "?:")
          (regexp-quote-alts (c-op-assignment))
          $>))

(defun coolock/c++-op-member (&optional match)
  "Return C++ member operator regexp."
  (concat $< (unless match "?:")
          (regexp-quote-alts c++-op-member)
          $>))

(defun coolock/python-op-member (&optional match)
  "Return Python member operator regexp."
  (concat $< (unless match "?:")
          (regexp-quote-alts '("."))
          $>))

(defconst coolock/c++-template-instance
  (concat Y< $< "\w+" $> Y>
          L*
          "<"
          L*
          Y< $< "[[:word:]_]+" $> Y>
          L*
          ">")
  "C++-only Template Instance.")

(defconst coolock/op-postfix
  (concat Y< $< "[[:word:]_]+" $> Y>
          L*
          $< (regexp-quote-alts c-op-inc-dec) $>)
  "C/C++ Postfix Operators ++, --.")

(defconst coolock/op-prefix
  (concat $< (regexp-quote-alts c-op-inc-dec) $>
          L*
          Y< $< "[[:word:]_]+" $> Y>)
  "C/C++ Prefix Operators ++, --."
  )

(defun coolock/parens (&optional match)
  "Return C/C++ parens regexp."
  (concat $< (unless match "?:")
          (regexp-quote-alts c-parenthesises)
          $>))

(defun coolock/braces (&optional match)
  "Return C/C++ braces regexp."
  (concat $< (unless match "?:")
          (regexp-quote-alts c-braces)
          $>))

(defun coolock/separators (&optional match)
  "Return C/C++ separators regexp."
  (concat $< (unless match "?:")
          (regexp-quote-alts c-separators)
          $>))

(defun coolock/operators-others (&optional match)
  "Return C/C++ other operators regexp."
  (concat $< (unless match "?:")
          (regexp-quote-alts c-op-others)
          $>))

(defun coolock/c-common-function-call ()
  (list
   (cons coolock/c-function-call
         '(1 'font-lock-function-call-face keep))))

(defun coolock/c++-common-function-call ()
  (list
   (cons coolock/c++-function-call
         '(1 'font-lock-function-call-face keep))))

(defun coolock/d-common-function-call ()
  (list
   (cons coolock/d-function-call
         '(1 'font-lock-function-call-face keep))))

(defun coolock/d-template-definition ()
  (list
   (cons (concat Y< "template" L* $< ID $>)
         '((1 'font-lock-template-definition-face t)))))

(defun coolock/d-traits-call ()
  (list
   (cons (concat Y< "__traits" L* "(" L* $< ID $>)
         '((1 'font-lock-builtin-ref-face append)))))

(defun coolock/d-variadic-argument ()
  (list
   (cons (eval `(rx (group (regexp ,ID)) (* space) (group "...")))
         '((1 'font-lock-type-definition-face t)
           (2 'font-lock-operator-dots-face append)))))

(defun coolock/d-member-base ()
  (list
   (cons (eval `(rx (group (regexp ,ID)) (* space)
                    (group (| "."
                              "["))
                    (regexp ,ID)))
         '((1 'font-lock-variable-ref-face append)
           (2 'font-lock-operator-dots-face append)))))

(defun coolock/d-range-dots ()
  (list
   (cons (eval `(rx (not (any "."))
                    (group "..")
                    (not (any "."))
                    ;; (group "[]")
                    ))
         '((1 'font-lock-operator-dots-face append)))))

(defun coolock/d-template-instance ()
  ;; (when nil
  ;;   (list
  ;;    `( ;; MATCHER: (LET
  ;;      ,(concat Y< $< "[[:word:]_]+" $> L*
  ;;               $< "!" $> L*)
  ;;      ;; SUBEXP-HIGHLIGHTER
  ;;      (1 'font-lock-keyword-face keep)
  ;;      ;; ANCHORED-HIGHLIGHTER: (let VARLIST)
  ;;      ( ;; ANCHORED-MATCHER
  ;;       coolock/d-template-instance-args-matcher
  ;;       nil                                       ; PRE-FORM
  ;;       nil                                       ; POST-FORM
  ;;       (1 'font-lock-variable-name-face prepend) ; SUBEXP-HIGHLIGHTERS
  ;;       ))
  ;;    ))
  (list
   (cons (concat Y< $< "[[:word:]_]+" $> L*
                 $< "!" $> L*
                 "(?" L*
                 $< "\"?" ID $>)
         '((1 'font-lock-template-instance-face prepend)
           (2 'font-lock-operator-face append)
           (3 'font-lock-type-face append)))))

(defconst d-builtin-type-properties
  '("init" "sizeof" "alignof" "stringof" "mangleof" ;all

    "dup"                               ;Arrays Associative Arrays

    "keys" "values" "byValue" "byKey" "rehash" "get" ;Associative Arrays. See also: http://dlang.org/hash-map.html

    "length" "ptr"                      ;Array

    "min" "max"                         ;Integral

    "infinity" "nan" "dig" "epsilon" "mant_dig" "max_10_exp" "min_exp" "min_normal" ;floating-point
    "re" "im"                           ;Complex
    "classinfo"                         ;Classes
    )
  "D Builtin Type Properties.
See: http://dlang.org/property.html")

(defconst d-builtin-operators
  '("toString"
    "toHash"

    "opEquals"
    "opCmp"

    "opCast" "opImplicitCast" "opExplicitCast"

    "opIndex" "opIndexUnary" "opIndexAssign" "opIndexOpAssign"
    "opSlice" "opSliceUnary" "opSliceAssign" "opSliceOpAssign"

    "opUnary" "opBinary" "opBinaryRight"

    "opAssign" "opOpAssign"
    "opDispatch"
    "opCall"
    "opDollar"

    "opAdd" "opAddAssign"
    "opSub" "opSubAssign"
    "opMul" "opMulAssign"
    "opDiv" "opDivAssign"

    "opOr" "opOrAssign"
    "opAnd" "opAndAssign"
    "opXor" "opXorAssign"
    "opCat" "opCat_r" "opCatAssign"
    "opCom" "opComAssign"               ;complement

    "__vector"                          ;SIMD vector instrincis from core.simd
    )
  "D Builtin Operators.")
;; Use: (regexp-opt d-builtin-operators)

(defun coolock/d-builtin-properties ()
  (list
   (cons (eval `(rx "."
                    (group (| ,@d-builtin-type-properties))
                    symbol-end))
         '((1 'font-lock-builtin-ref-face append)
           ))))

(defun coolock/d-lambda ()
  (list
   (cons (eval
          `(rx (group (regexp ,ID))
               (* space)
               (opt ")")
               (* space)
               (group "=>"))
          )
         '((1 'font-lock-variable-name-face append)
           (2 'font-lock-function-name-face append)
           ))))

;;; TODO: Put this before function matcher in keywords and change `prepend' to `append'.
(defun coolock/d-template-builtin-operators ()
  "See http://dlang.org/operatoroverloading.html"
  (list
   (cons (eval `(rx symbol-start
                    (group (| ,@d-builtin-operators))
                    symbol-end))
         '((1 'font-lock-builtin-face prepend)
           ))))
;; Use: (coolock/d-template-builtin-operators)

(defun coolock/d-special-constants ()
  "D special keywords used in debugging.
See also: http://dlang.org/traits.html"
  (list
   (cons (rx (group (| "__FILE__"
                       "__MODULE__"
                       "__LINE__"
                       "__FUNCTION__"
                       "__PRETTY_FUNCTION__")))
         '((1 'font-lock-constant-face prepend)
           ))))

(defun coolock/d-foreach ()
  (list
   (cons (concat Y<
                 "foreach" _*
                 "(" _*
                 "\\(?:" "const" Y> _* "\\)?"
                 "\\(?:" "ref" Y> _* "\\)?"
                 $< "[[:word:]_]+" $> _* ;element
                 ",?" _*
                 $< "[[:word:]_]*" $> _* ;optional index
                 ";")
         '((1 'font-lock-variable-name-face prepend)
           (2 'font-lock-variable-name-face prepend)))))

(defconst coolock/ada-variable-assignment
  (concat Y< $< "[[:word:]_]+" $> Y>
          L*
          $< ":=" $>
          ) "Ada Variable Name and Operator in Assignment.")
;; ToDo: Don't highlight for C++ Constructor member variable initalizers:
;; JobQueue1() : waiting_for_god_(false), active_threads_(0) {}
(defun coolock/variable-assignment (&optional mode)
  "C-Style Variable Name and Operator in Assignment."
  (list
   (cons (c-op-assignment-regexp mode t)
         '(;; (1 'font-lock-variable-alteration-face keep)
           (1 'font-lock-operator-assignment-face keep)
           ))))

(defun coolock/c++11-auto-variable-definition ()
  (list
   (cons c++11-auto-variable-definition
         '((1 'font-lock-variable-name-face prepend)))))

(defun coolock/c++11-nullptr ()
  (list
   (cons c++11-nullptr
         '((1 'font-lock-constant-face keep)))))
(defun coolock/gcc-pure ()
  (list
   (cons (concat Y< "\\(s?pure\\)" Y>)
         '((1 'font-lock-keyword-face keep)))))
(defun coolock/c++11-keywords ()
  (list
   (cons (concat Y< (regexp-opt (remove "nullptr" c++11-new-keywords-list) t) Y>)
         '((1 'font-lock-keyword-face keep)))))

(defun coolock/c++-dots ()
  (list
   (cons c++11-dots
         '((1 'font-lock-operator-dots-face append)))))

(defun coolock/c-printf-directives ()
  "C-style formatting directives."
  (list
   ;; ToDo: Use only inside C string contexts using `at-syntax-string-p'
   (cons coolock/c-printf
         '((1 'font-lock-printf-directives-face append)
           ;;NOTE: intuitive to associate conversion directive with types
           (2 'font-lock-printf-directive-conversion-face prepend)
           ))
   ))

;; Adds fontification patterns for C mode and NOTE: modes derived from C mode
(defun coolock/c-common (&optional mode)
  "Fancy C/C++/ObjC/Java Syntax Highlighting."
  (list

   ;; other operators
   ;; NOTE: Deactivated this because this will be very inefficient.
   ;;     (cons (concat "#" _* "if" "[ \t]+" "0"
   ;; 		  $< "[.\n]*" $>
   ;; 		  "#" _*  "endif")
   ;; 	  '(1 'font-lock-warning-face t))

   (coolock/c-switch-case-regexp)

;;;     (cons coolock/c-character-literal-regexp
;;; 	  '(1 'font-lock-special-literal-face prepend)
;;; 	  )

   ;; TODO: Make it work for statements such as: free(bufA[i])
   (cons (concat Y< "\\(?:" "[[:alnum:]_]*" "_" "\\)?"
                 "\\(?:" "free" "\\|" "delete" $>
                 "(" _* $< "[[:word:]_]+" $> _* ")")
         '((1 'font-lock-variable-deletion-face keep)
           ))

   (coolock/variable-assignment mode)

   (cons coolock/op-postfix
         '((1 'font-lock-variable-alteration-face keep)
           (2 'font-lock-operator-assignment-face keep)
           ))

   (cons coolock/op-prefix
         '((1 'font-lock-operator-assignment-face keep)
           (2 'font-lock-variable-alteration-face keep)
           ))

   (cons (concat $< (coolock/c-op-member) "?" $>
                 $< (coolock/c-op-assignment) "?" $>
                 $< (coolock/parens) "?" $>
                 $< (coolock/braces) "?" $>
                 $< (coolock/separators) "?" $>
                 $< (coolock/operators-others) "?" $>
                 )
         '((1 'font-lock-operator-member-face keep)
           (2 'font-lock-operator-assignment-face keep)
           (3 'font-lock-parens-face keep)
           (4 'font-lock-braces-face keep)
           (5 'font-lock-separator-face keep)
           (6 'font-lock-operator-face keep)))
   ))

(defun coolock/ada ()
  "Fancy Ada Syntax Highlighting."
  (list
   (cons coolock/ada-variable-assignment
         '((1 'font-lock-variable-alteration-face keep)
           (2 'font-lock-operator-assignment-face keep)
           ))
   (cons coolock/ada-named-parameter-assignment
         '((1 'font-lock-variable-alteration-face keep)
           (2 'font-lock-operator-assignment-face keep)
           ))
   (cons coolock/ada-variable-or-parameter
         '((1 'font-lock-variable-name-face keep)
           (2 'font-lock-type-face keep)
           ))
   ))

;; ============================================================================

(defun coolock/c++ ()
  "Fancy C++ Syntax Highlighting."
  (list
   (cons c++11-auto-variable-definition
         '((1 'font-lock-variable-name-face keep)
           ))

   (cons coolock/c++-template-instance
         '(1 'font-lock-template-instance-face
             append))           ;keep: only dots in language statements

   (cons (coolock/c++-op-member t)
         '(1 'font-lock-operator-member-face
             keep))           ;keep: only dots in language statements

   (cons (concat "\\_<delete" _* $< "[[:word:]_]+" $>)
         '((1 'font-lock-variable-deletion-face keep)
           ))))

;;; ===========================================================================

(defun coolock/gcc-attribute ()
  "Highlight GCC Attribute Argument."
  (list
   (cons (concat Y< "__attribute__"
                 _* "(" _* "(" _*
                 "\\([[:word:]]+\\)"
                 _* ")" _* ")"
                 )
         '(1 'font-lock-constant-face t))
   ))

(defun coolock/gcc-attribute-aliases ()
  "Highlight My Alises for GCC Attributes."
  (list
   (cons (concat (regexp-opt '("__always_inline__"
                               "__pure__"
                               "__const__"
                               "__noreturn__"
                               "__malloc__"
                               "__must_check__"
                               "__deprecated__"
                               "__used__"
                               "__unused__"
                               "__packed__"
                               "__likely__"
                               "__unlikely__") t))
         '(1 'c-annotation-face keep))
   ))

;; ============================================================================

(defconst coolock/python-for-intro
  (concat Y< "for" "[[:blank:]]+"
          $< "[[:word:]_]+" $> "[[:blank:]]+"
          "in" "[[:blank:]]+"
          )
  "Python for statement.")

(defconst coolock/python-def-intro
  (concat Y< "def" "[[:blank:]]+"
          $< "[[:word:]_]+" $> _* "("
          )
  "Python def statement.")

(defconst coolock/python-variable-assignment
  (concat Y< $< "[[:word:]_]+" $> Y>
          L*              ;blanks and newlines
          $< (regexp-quote-alts (c-op-assignment)) $>
          "[^=]"                        ;dont' match ==
          )
  "Python variable name and operator in assignment.")

;; ToDo: Support variable alterations here.
(defun coolock/python-def-args (limit)
  "Match the arguments of Python def-statements up to LIMIT."
  (if (at-syntax-code-p)
      (if (looking-at (concat L* ",?" _* "\\**" _* ;leading spaces, commas and stars
                              $< "[[:word:]_]+" $> ;variable name
                              "\\(?:" _* "=" _* "[[:word:]_]+" "\\)?" ;default initializer
                              )) ; One more SYM?
          (progn (goto-char (match-end 1))
                 t)); signal hit
    ))

(defun coolock/python-assignment-args (limit)
  "Match the arguments of Python assignment arguments up to LIMIT."
  (if (at-syntax-code-p)
      (if (looking-forward (concat L* ",?")) ; One more SYM?
          (progn (goto-char (match-end 1))
                 t)); signal hit
    ))

(defun coolock/python ()
  "Fancy Python Syntax Highlighting."
  (list
   ;; def Statements

   `(;; MATCHER:
     ,coolock/python-def-intro
     ;; SUBEXP-HIGHLIGHTER
     (1 'font-lock-function-name-face keep)
     ;; ANCHORED-HIGHLIGHTER: (setq SYM VAL ...)
     (;; ANCHORED-MATCHER
      coolock/python-def-args
      nil ; PRE-FORM
      nil ; POST-FORM
      (1 'font-lock-variable-alteration-face keep) ; SUBEXP-HIGHLIGHTERS
      ))

   ;; For Statement Operators
   (cons coolock/python-for-intro
         '(1 'font-lock-variable-name-face keep))

   ;; Function Calls
   (cons coolock/c-function-call
         '(1 'font-lock-function-call-face keep))

   ;; Variable Assignment.
   ;;
   ;; ToDo: Go to beginning of symbol list x,y,z,... = then highlight
   ;; these symbols using `coolock/python-assignment-args'.
   (cons coolock/python-variable-assignment
         '((1 'font-lock-variable-name-face keep) ;Every assignment may be an initialization
           (2 'font-lock-operator-assignment-face keep)
           ))

   ;; Postfix Operators
   (cons coolock/op-postfix
         '((1 'font-lock-variable-alteration-face keep)
           (2 'font-lock-operator-assignment-face keep)
           ))

   ;; Prefix Operators
   (cons coolock/op-prefix
         '((1 'font-lock-operator-assignment-face keep)
           (2 'font-lock-variable-alteration-face keep)
           ))

   ;; Namespace Qualifier
   (cons (concat $< ID+ $> "\\.")
         '((1 'font-lock-constant-face keep)
           ))

   ;; NOTE: Higher priority than operators-others
   (cons (concat $< (coolock/python-op-member) "?" $>
                 $< (coolock/parens) "?" $>
                 $< (coolock/braces) "?" $>
                 $< (coolock/separators) "?" $>
                 $< (coolock/operators-others) "?" $>
                 )
         '((1 'font-lock-operator-member-face keep)
           (2 'font-lock-parens-face keep)
           (3 'font-lock-braces-face keep)
           (4 'font-lock-separator-face keep)
           (5 'font-lock-operator-face keep)))

   ;; other operators
   ))

;;; ===========================================================================

(defconst coolock/julia-number
  (list
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (c-number-float-regexp)
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (c-number-dec-regexp 'julia-mode)
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))
   ;; NOTE: needs to be before matching C operator '.' below
   (cons (c-number-hex-regexp 'julia-mode)
         '((1 'font-lock-number-passive-face keep)
           (2 'font-lock-number-face keep)
           (3 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))
   )
  "Basic C-Style Number Literal Syntax Highlighting.")

(defconst julia-function-name-rx
  '(|
    ;; arithmetic
    "+" "-" "*" "/" "\\"
    ".+" ".-" ".*" "./" ".\\"
    ;; comparison
    "<" ">" "<=" ">=" "==" "!="
    ".<" ".>" ".<=" ".>=" ".==" ".!="
    (: (in word ?$ ?_)
       (*
        (in word ?$ ?_ digit))))
  "Julia Indentifier `rx' pattern.")

(defconst julia-id-rx
  '(: (in word ?$ ?_)
      (*
       (in word ?$ ?_ digit)))
  "Julia Indentifier `rx' pattern.")

(defconst coolock/julia-function-signature
  (cons (eval `(rx (: (group-n 1 symbol-start "function") (+ space) ;function keyword
                      (group-n 2 ,julia-function-name-rx) (* space) ;function name

                      ;; optional template type arguments
                      (group-n 3 (? "{")) (* space) (* nonl) (* space)
                      (group-n 4 (? "}"))
                      (* space)

                      ;; function call variables
                      (group-n 5 "(") (* space) (* nonl) (* space)
                      (group-n 6 ")")
                      (* space)
                      )))
        '((1 'font-lock-keyword-face keep)
          (2 'font-lock-function-name-face t)
          (5 'font-lock-parens-face t)
          (6 'font-lock-parens-face t)
          ;; (3 'font-lock-braces-face t)
          ;; (4 'font-lock-braces-face t)
          ))
  "Julia Function Signature.")

(defconst coolock/julia-function-specialization
  (cons (eval `(rx (: (group-n 1 line-start)
                      (group-n 2 ,julia-function-name-rx) (* space) ;function name

                      ;; optional template type arguments
                      (? (: (group-n 3 "{") (* space) (* nonl) (* space)
                            (group-n 4 "}")))
                      (* space)

                      ;; function call variables
                      (group-n 5 "(") (* space) (* nonl) (* space)
                      (group-n 6 ")")
                      (* space)

                      (group-n 7 "=")
                      )))
        '((1 'font-lock-keyword-face keep)
          (2 'font-lock-function-name-face t)
          (5 'font-lock-parens-face t)
          (6 'font-lock-parens-face t)
          (7 'font-lock-operator-assignment-face t)
          ;; (3 'font-lock-braces-face t)
          ;; (4 'font-lock-braces-face t)
          ))
  "Julia Function Specialization.")

(defconst coolock/julia-type-definition
  (cons (eval `(rx (: symbol-start
                      (group-n 1 "type") (+ space)   ;function keyword
                      (group-n 2 ,julia-id-rx) (* space) ;type name

                      ;; optional template type arguments
                      (? (: (group-n 3 "{") (* space) (* nonl) (* space)
                            (group-n 4 "}")))
                      (* space)
                      )))
        '((1 'font-lock-keyword-face keep)
          (2 'font-lock-type-definition-face t)
          ;; (3 'font-lock-braces-face t)
          ;; (4 'font-lock-braces-face t)
          ))
  "Julia Type Definition.")

(defconst coolock/julia-function-call
  (cons (eval `(rx (: symbol-start
                      (* space)
                      (group-n 1 ,julia-function-name-rx)
                      symbol-end
                      (* space)
                      "(")))
        '(1 'font-lock-function-call-face keep))
  "Julia Function Call.")

(defconst coolock/julia-variable-declaration
  (cons (eval `(rx symbol-start
                   (group-n 1 ,julia-id-rx) (* space)
                   (| "::" "<:") (* space)
                   (group-n 2 ,julia-id-rx) symbol-end
                   ))
        '((1 'font-lock-variable-name-face keep) ;Every assignment may be an initialization
          (2 'font-lock-type-face keep)
          ))
  "Julia variable name and operator in assignment.")

(defconst coolock/julia-variable-assignment
  (cons (eval `(rx symbol-start
                   (group-n 1 ,julia-id-rx) (* space)
                   (group-n 2 (| ,@(c-op-assignment)))
                   (* space)
                   (not (any ?=))       ;dont' match ==
                   ))
        '((1 'font-lock-variable-name-face keep) ;Every assignment may be an initialization
          (2 'font-lock-operator-assignment-face keep)
          ))
  "Julia variable name and operator in assignment.")

(defconst coolock/julia-dots
  (cons (rx (group "\\.\\.\\."))
        '(1 'font-lock-keyword-face keep))
  "Julia dots.")

(defun coolock/julia ()
  "Fancy Julia Syntax Highlighting."
  (append
   coolock/julia-number
   (list
    coolock/julia-function-signature
    coolock/julia-function-specialization
    coolock/julia-function-call
    coolock/julia-variable-declaration
    coolock/julia-variable-assignment
    coolock/julia-type-definition
    coolock/julia-dots
    )))

;;; ===========================================================================

(defconst coolock/ruby-variable-assignment
  (concat Y< $< "[[:word:]_]+" $> Y>
          L*              ;blanks and newlines
          $< (regexp-quote-alts (c-op-assignment)) $>
          "[^=]"                        ;dont' match ==
          )
  "Ruby variable name and operator in assignment."
  )

(defun coolock/ruby ()
  "Fancy Ruby Syntax Highlighting."
  (list

   ;; NOTE: needs to be before matching operator '.' below
   (cons (c-number-dec-regexp 'ruby-mode)
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))

   ;; NOTE: needs to be before matching operator '.' below
   (cons (c-number-hex-regexp 'ruby-mode)
         '((1 'font-lock-number-passive-face keep)
           (2 'font-lock-number-face keep)
           (3 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))

   ;; NOTE: needs to be before matching operator '.' below
   (cons (c-number-float-regexp 'ruby-mode)
         '((1 'font-lock-number-face keep)
           (2 'font-lock-number-passive-face keep)
           (3 'font-lock-type-face keep)
           ))

   (cons coolock/ruby-variable-assignment
         '((1 'font-lock-variable-name-face keep) ;Every assignment may be an initialization
           (2 'font-lock-operator-assignment-face keep)
           ))
   ))

;;; ===========================================================================
;;; Emacs LISP Extra Font Locking

(defconst emacs-lisp-special-constant
  (concat Y< (regexp-opt '("nil" "t")) Y>)
  "Emacs Lisp Special Constants.")

(defun coolock/elisp-comment-symbol (name)
  "Emacs Lisp In-Comment Symbol Reference Highlighter of symbol
name string NAME."
  (when name
    (let ((face (symbol-ref-face name)))
      (if face
          (when (at-syntax-comment-p) face) ;check syntax last because most costly
        (if (string-match  "\\.el$" name) 'font-lock-file-name-face 'bold)))))

;; (when nil
;;   (list
;;    (benchmark-run 300000 (at-syntax-code-p))
;;    (benchmark-run 300000 (at-syntax-string-p))
;;    (benchmark-run 300000 (at-syntax-comment-p))
;;    (benchmark-run 300000 (intern-soft nil))
;;    (benchmark-run 300000 (intern-soft 'find-file))
;;    (benchmark-run 300000 (symbol-plist (intern-soft 'find-file)))
;;    (benchmark-run 300000 (make-symbol "find-file"))
;;    (benchmark-run 300000 (fboundp 'find-file))
;;    (benchmark-run 300000 (boundp 'find-file))
;;    ))
;;()

(defun coolock/elisp-symbol (name pchar)
  "Emacs Lisp Symbol Highlighter using prefix PCHAR and symbol
name string NAME."
  (when name
    (let* ((prefix (and pchar (string-to-char pchar)))
           (quoted (memq prefix '(?\` ?\'))) ;if its quoted or not
           (face (or (symbol-ref-face name)      ;TODO: Don't care about quoted for now!
                     (if (and name (string-match emacs-lisp-special-constant name))
                         'font-lock-special-constant-face
                       ))))
      face
      ;; (when (and face (at-syntax-code-p))
      ;;   face)
      )))
;; Use: (coolock/elisp-symbol nil "find-file")
;; Use: (coolock/elisp-symbol t "find-file")

;; TODO: Use overlays instead!
(defun coolock/elisp-comma (limit)
  "Emacs Lisp Comma Evaluation Highlighter up to LIMIT.
Return t if `forward-sexp' otherwise nil."
  (let ((p (point)))
    (when (and (ignore-errors (forward-sexp) t)
               (at-syntax-code-p)) ;check syntax last because most costly
      (set-match-data (list p (point))) t)))

(defun coolock/elisp-setq-args (limit)
  "Match the argument [SYM VAL]... to `setq'-statements up to LIMIT."
  (when (at-syntax-code-p)
    (when (looking-at (concat L* "[,`']?\\(" "[[:word:]_]+" $>)) ; One more SYM?
      (progn (goto-char (match-end 1))
             (ignore-errors (forward-sexp) t) ;skip VAL. Note: No error, but instead nil if no more sexps.
             t)); signal hit
    ))

;; Use:
(when nil
  (setq a 1 b 2 cccc 3)
  (setq a 1 b 2 cccc)

  (setq a 1
        b 2
        c 3)

  (setq x-1 '(1 1)
        x-2 '(2 2)
        x-3 '(3 3))
  )

(defun coolock/elisp-let-args-matcher (limit)
  "Match the argument [SYM VAL]... to `let'-statements."
  (when (at-syntax-code-p)
    (cond ((looking-at (concat "[[:space:]\n]*" $< "[[:word:]_]+" $>)) ;looking-at SYM
           (progn
             (goto-char (match-end 1)) ;goto past hit
             t))                      ;signal hit
          ((looking-at (concat "[[:space:]\n]*" "[,`']?" "(" $< "[[:word:]_]+" $>)) ;looking-at (SYM VALUE-SEXP)
           (progn (ignore-errors (forward-sexp) t) ;skip VAL. Note: No error, but instead nil if no more sexps.
                  t)); signal hit
          )))
;; Use:
(when nil
  (let (dum1 dum2)
    dum1)
  (let ((dum1 'a) (dum2 'b))
    `(,dum1 ,dum2))
  (let (n-1 n-2 n-3
            (alpha 'ALPHA)
            (beta 'GAMMA)))
  (let ((alpha 'ALPHA) (beta 'GAMMA)
        n-1 n-2 n-3))
  (let* ((alpha 'ALPHA) (beta 'BETA) (gamma 'GAMMA)))
  (let* ((alpha 'ALPHA)
         (beta 'BETA)
         (gamma 'GAMMA)))
  )

(defun coolock/elisp-def-args-matcher (limit)
  "Match each argument of `defun' and `defmacro' statements."
  (when (and (at-syntax-code-p)
             (looking-at (concat L* "'?\\(" "[[:word:]_]+" $>))) ; One more SYM?
    (progn (goto-char (match-end 1))
           t)); signal hit
  )

(defun coolock/elisp ()
  "Fancy Emacs Lisp Syntax Highlighting."
  (list
   ;; parenthesis
   (cons (coolock/parens t)
         '(1 'font-lock-parens-face keep))

   ;; character literal
   (cons "?[^[:space:]]+"
         '(0 'font-lock-string-face keep))

   ;; binary number literal
   (cons emacs-lisp-number-bin-regexp
         '((1 'font-lock-number-passive-face keep)
           (2 'font-lock-number-face keep)
           ))

   ;; octal number literal
   (cons emacs-lisp-number-oct-regexp
         '((1 'font-lock-number-passive-face keep)
           (2 'font-lock-number-face keep)
           ))

   ;; decimal number literal
   (cons (number-dec-regexp 'elisp-mode)
         '(1 'font-lock-number-face keep))

   ;; hexadecimal number literal
   (cons emacs-lisp-number-hex-regexp
         '((1 'font-lock-number-passive-face keep)
           (2 'font-lock-number-face keep)
           ))

   ;; float number literal
   (cons emacs-lisp-number-float-regexp
         '(1 'font-lock-number-face keep))

   ;; quotes
   (cons (concat "'\\|`\\|,\\|@")
         '(0 'font-lock-quote-face keep))

   ;; regexp classes
   (cons (concat "\\[:" (regexp-opt emacs-lisp-char-class-list) ":\\]")
         '(0 'font-lock-variable-name-face append))

   ;; setq-statements: (setq SYM VAL ...)
   `(;; MATCHER: (SETQ
     ,(concat "(" (regexp-opt '("set" "setq" "setq-default" "setq-mode-local") t)
              Y>
              L+)
     ;; SUBEXP-HIGHLIGHTER
     (1 'font-lock-builtin-face keep)
     ;; ANCHORED-HIGHLIGHTER: (setq SYM VAL ...)
     (;; ANCHORED-MATCHER
      coolock/elisp-setq-args
      nil ; PRE-FORM
      nil ; POST-FORM
      (1 'font-lock-variable-alteration-face prepend) ; SUBEXP-HIGHLIGHTERS
      ))

   ;; let-like statements: (let VARLIST BODY)
   ;; Note: Must be before `coolock/elisp-symbol'
   `(;; MATCHER: (LET
     ,(concat "(" (regexp-opt emacs-lisp-let-forms-list t) L* "(")
     ;; SUBEXP-HIGHLIGHTER
     (1 'font-lock-keyword-face keep)
     ;; ANCHORED-HIGHLIGHTER: (let VARLIST)
     (;; ANCHORED-MATCHER
      coolock/elisp-let-args-matcher
      nil ; PRE-FORM
      nil ; POST-FORM
      (1 'font-lock-variable-name-face prepend) ; SUBEXP-HIGHLIGHTERS
      ))

   ;; defun-like statements
   ;; Note: Must be before `coolock/elisp-symbol'
   `(;; MATCHER: (defun name arglist [docstring] body...)
     ,(concat "(" (regexp-opt emacs-lisp-defs-list t) Y>
              L+
              $< "[[:word:]_]+" $>
              L*
              "("
              )
     ;; SUBEXP-HIGHLIGHTER
     (1 'font-lock-keyword-face keep)
     ;; ANCHORED-HIGHLIGHTER: (setq SYM VAL ...)
     (;; ANCHORED-MATCHER
      coolock/elisp-def-args-matcher
      nil ; PRE-FORM
      nil ; POST-FORM
      (1 'font-lock-variable-name-face keep) ; SUBEXP-HIGHLIGHTERS
      ))

   ;; defcustom :type
   (cons (concat ":type" _* "'" $< "[[:word:]_]+" $> Y>)
         '(1 'font-lock-type-face keep))
   ;; defcustom :group
   (cons (concat ":group" _* "'" $< "[[:word:]_]+" $> Y>)
         '(1 'font-lock-variable-ref-face keep))

   ;; function/macro calls, (quoted) references to functions/macros/variables
   `(,(concat
       "^"                              ;beginning of line
       "[^" comment-start "\n]*?"         ;not in comment

       $<
       "(" _*               ;function call prefix
       "\\|"                            ;or
       "#?"
       "[,'`\"]"                        ;quoted, backquoted, evaluated
       "\\|"                            ;or
       "^[[:blank:]]*"                  ;beginning of line and space
       "\\|"                            ;or
       "[[:blank:]]+"                   ;at least space
       $>

       Y< $< ".+?" $> Y>
       )
     ;; SUBEXP-HIGHLIGHTER
     (2 (coolock/elisp-symbol (match-string-no-properties 2) (match-string-no-properties 1)) keep)
     ;; ANCHORED-HIGHLIGHTER: (setq SYM VAL ...)
     (;; ANCHORED-MATCHER'
      ,(concat
        "[^" comment-start "\n]*?"        ;no comment before next symbol

        $<
        "(" _*              ;function call prefix
        "\\|"                           ;or
        "#?"
        "[,'`\"]"                       ;quoted, backquoted, evaluated
        "\\|"                           ;or
        "^[[:blank:]]*"                 ;beginning of line and space
        "\\|"                           ;or
        "[[:blank:]]+"                  ;at least space
        $>

        Y< $< ".+?" $> Y>
        )
      nil ; PRE-FORM
      nil ; POST-FORM
      (2 (coolock/elisp-symbol (match-string-no-properties 2) (match-string-no-properties 1)) keep) ; SUBEXP-HIGHLIGHTERS
      )
     )

   ;; in-comment symbols highlighter
   ;; (cons (concat
   ;;        "`"
   ;;        Y< $< ".+?" $> Y>
   ;;        "'"
   ;;        )
   ;;       '(1 (coolock/elisp-comment-symbol
   ;;            (match-string-no-properties 1))
   ;;           prepend)
   ;;       )

   ;; comma evaluation underlining
   ;; `(;; MATCHER:
   ;;   ,(concat "\\(,\\)")
   ;;   ;; SUBEXP-HIGHLIGHTER
   ;;   (1 'font-lock-operator-face append)
   ;;   ;; ANCHORED-HIGHLIGHTER:
   ;;   (;; ANCHORED-MATCHER
   ;;    coolock/elisp-comma
   ;;    nil ; PRE-FORM
   ;;    nil ; POST-FORM
   ;;    (0 'underline append) ; SUBEXP-HIGHLIGHTERS
   ;;    ))

   ;; Make Emacs-Lisp mode fontify definitions of Icicles commands.
   ;; `((,(concat "(" (regexp-opt '("icicle-define-add-to-alist-command" "icicle-define-command"
   ;;                               "icicle-define-file-command" "icicle-define-sort-command")
   ;;                             t)
   ;;             ;; $$ "\\s-+\\(\\sw\\(\\sw\\|\\s_\\)+\\)") ;Note: We must use \s_ here: Syntax class: symbol constituent
   ;;             "\\>[ \t'\(]*\\(\\sw+\\)?")
   ;;    (1 font-lock-keyword-face)
   ;;    ;; Index (2 or 3) depends on whether or not shy groups are supported.
   ;;    ,(list (if (string-match "\\(?:\\)" "") 2 3) font-lock-function-name-face nil t)))
   ))

;; ============================================================================

(require 'octave-patterns nil t)

(defun coolock/octave-mode-extra ()
  "Fancy Octave Syntax Highlighting."
  (list
   ;; special constants
   (cons (concat $< octave-special-math-constants-regexp $>)
         '(1 'font-lock-constant-face t))

   ;; Matlab-style string literals
   ;; NOTE: Uncommented because ' are used as string literals. Really stupid!
   ;;     (cons (concat $< octave-string-literal-regexp $>)
   ;;        '(1 'font-lock-string-face prepend))

   (cons coolock/c-function-call
         '(1 'font-lock-function-call-face keep))

   ;; Matlab-style special function
;;;    (cons (concat $< octave-common-functions-regexp $>
;;;                  L* "(")
;;;          '(1 'font-lock-function-call-face keep))

   ;; variable name and operator in assignment operators
   (cons (concat "\\(?:"
                 "^" "\\|" "[^[[:alnum:]]_]"
                 $>
                 L*
                 "\\<" $< "[[:word:]_]+" $> "\\>"
                 L*
                 $<
                 octave-op-assignment-regexp
                 $>
                 "[^=]"
                 ;; "[\\*([:blank:]\n]*" "[\\+-\\[]?" "[[:word:]_]+"
                 )
         ;;L* ";")
         '((1 'font-lock-variable-alteration-face keep)
           (2 'font-lock-operator-assignment-face keep)
           ))

   ;; postfix operators ++ and --
   (cons (concat "\\<" $< "[[:word:]_]+" $> "\\>"
                 L*
                 $< octave-op-inc-dec-regexp $>)
         '((1 'font-lock-variable-alteration-face keep)
           (2 'font-lock-operator-assignment-face keep)
           ))

   ;; prefix operators ++ and --
   (cons (concat $< octave-op-inc-dec-regexp $>
                 L*
                 "\\<" $< "[[:word:]_]+" $> "\\>")
         '((1 'font-lock-operator-assignment-face keep)
           (2 'font-lock-variable-alteration-face keep)
           ))

   ;; braces
   (cons (concat $< octave-op-braces-regexp $>)
         '((1 'font-lock-braces-face keep)
           ))

   ))

;; ============================================================================

;; decimal	→	digit{digit}
;; octal	→	octit{octit}
;; hexadecimal	→	hexit{hexit}
;; integer	→	decimal
;; |	0o octal | 0O octal
;; |	0x hexadecimal | 0X hexadecimal
;; float	→	decimal . decimal [exponent]
;; |	decimal exponent
;; exponent	→	(e | E) [+ | -] decimal

(defun coolock/haskell ()
  "Fancy Haskell Syntax Highlighting."
  (list
   ))

;; ============================================================================

(defun coolock/opengl ()
  "Fancy OpenGL Syntax Highlighting."
  (list
   ;; gl.h
   (cons (concat $< "\\<GL[[:lower:]]+\\>" $>) '(1 font-lock-type-face append))
   (cons (concat $< "\\<gl[[:lower:]][^.(]+\\>" $>) '(1 font-lock-function-call-face append))
   (cons (concat $< "\\<GL_[[:upper:][:digit:]_]+\\>" $>) '(1 font-lock-constant-face append))
   ;; glu.h
   (cons (concat $< "\\<GLU[[:alpha:]]+\\>" $>) '(1 font-lock-type-face append))
   (cons (concat $< "\\<glu[[:lower:]][^.(]+\\>" $>) '(1 font-lock-function-call-face append))
   (cons (concat $< "\\<GLU_[[:upper:][:digit:]_]+\\>" $>) '(1 font-lock-constant-face append))
   ;; glx.h
   (cons (concat $< "\\<GLX[[:alpha:]]+\\>" $>) '(1 font-lock-type-face append))
   (cons (concat $< "\\<glX[[:lower:]][^.(]+\\>" $>) '(1 font-lock-function-call-face append))
   (cons (concat $< "\\<GLX_[[:upper:][:digit:]_]+\\>" $>) '(1 font-lock-constant-face append))
   ;; glut.h
   (cons (concat $< "\\<GLUT[[:alpha:]]+\\>" $>) '(1 font-lock-type-face append))
   (cons (concat $< "\\<glut[[:lower:]][^.(]+\\>" $>) '(1 font-lock-function-call-face append))
   (cons (concat $< "\\<GLUT_[[:upper:][:digit:]_]+\\>" $>) '(1 font-lock-constant-face append))))

;;; ===========================================================================

(defconst coolock/autoconf-variable-assignment
  (concat $< W+ $> ;variable
          _*               ;blanks and newlines
          $< (regexp-quote-alts (c-op-assignment)) $>
          "[\[`'\"\\*([:blank:]]*" ;left-bracket,single/double-quotes, stars, lparens, blanks or newlines
          "[\\+-]?"                 ;sign
          _*            ;blanks
          "[[:word:]_]*")
  "Autoconf variable name and operator in assignment."
  )

(defconst coolock/autoconf-variable-ref-1
  (concat "\\$\\({#?\\)?\\([[:alpha:]_][[:alnum:]_]*\\|[-#?@!]\\)" ;Borrowed from sh-mode
          )
  "Autoconf variable name reference 1."
  )

(defconst coolock/autoconf-variable-ref-2
  (concat "\\$[({]?\\([[:alpha:]_][[:alnum:]_]*\\|[0-9]+\\|[$*_]\\)" ;Borrowed from sh-mode
          )
  "Autoconf variable name reference 2."
  )

(defconst coolock/autoconf-ac_define
  (concat (regexp-opt '("AC_DEFINE"
                        "AC_DEFINE_UNQUOTED"))
          _*               ;blanks and newlines
          "("

          $< W+ $>
          L*               ;blanks and newlines
          ","

          L*               ;blanks and newlines
          $< ".*" $>
          ","

          L*               ;blanks and newlines
          "\\[?"
          $< ".*" $>
          "\\]?"
          )
  "Autoconf AC_DEFINE statement matcher regxp."
  )

(defconst coolock/autoconf-ac_defun
  (concat "AC_DEFUN"
          L*               ;blanks and newlines
          "("
          L*               ;blanks and newlines
          "\\["
          L*               ;blanks and newlines
          $< W+ $>
          )
  "Autoconf AC_DEFUN statement matcher regxp."
  )

(defconst coolock/autoconf-ac_arg_with
  (concat "AC_ARG_WITH"
          _*               ;blanks and newlines
          "("
          _*               ;blanks and newlines
          "\\[?" $< W+ $> "\\]?"
          )
  "Autoconf AC_ARG_WITH statement matcher regxp."
  )

(defconst coolock/autoconf-ac_arg_enable
  (concat "AC_ARG_ENABLE"
          _*               ;blanks and newlines
          "(" $< W+ $>
          L*               ;blanks and newlines
          ","
          L*               ;blanks and newlines
          "\\[?" $< ".*" $> "\\]?"
          )
  "Autoconf AC_ARG_ENABLE statement matcher regxp."
  )

(defconst coolock/autoconf-ac_msg_checking
  (concat "AC_MSG_CHECKING"
          _*               ;blanks and newlines
          "(" "\\[?" $< ".*?" $> "\\]?" ")"
          )
  "Autoconf AC_MSG_CHECKING statement matcher regxp."
  )

(defconst coolock/autoconf-ac_msg_result
  (concat "AC_MSG_RESULT"
          _*               ;blanks and newlines
          "(" "\\[?" $< ".*?" $> "\\]?" ")"
          )
  "Autoconf AC_MSG_RESULT statement matcher regxp."
  )

(defconst coolock/autoconf-ac_msg_error
  (concat "AC_MSG_ERROR"
          _*               ;blanks and newlines
          "(" "\\[?" $< ".*?" $> "\\]?" ")"
          )
  "Autoconf AC_MSG_ERROR statement matcher regxp."
  )

(defconst coolock/autoconf-am_conditional
  (concat "AM_CONDITIONAL"
          _*               ;blanks and newlines
          "(" "\\[?" $< ".*?" $> "\\]?" ")"
          )
  "Autoconf AM_CONDITIONAL statement matcher regxp."
  )

(defconst coolock/autoconf-ac_check_types
  (concat "AC_CHECK_TYPE[S]?"
          _*               ;blanks and newlines
          "("
          _*               ;blanks and newlines
          "\\[?"
          _*               ;blanks and newlines
          $< ".*" $>
          _*               ;blanks and newlines
          "\\]?"
          _*               ;blanks and newlines
          ")"
          )
  "Autoconf AC_CHECK_TYPE and AC_CHECK_TYPES statement matcher regxp."
  )

(defconst coolock/autoconf-ac_check_sizeof
  (concat "AC_CHECK_SIZEOF"
          _*               ;blanks and newlines
          "("
          _*               ;blanks and newlines
          "\\[?"
          _*               ;blanks and newlines
          $< ".*" $>
          _*               ;blanks and newlines
          "\\]?"
          _*               ;blanks and newlines
          ")"
          )
  "Autoconf AC_CHECK_SIZEOF statement matcher regxp."
  )

(defconst coolock/autoconf-ac_check_funcs
  (concat "AC_CHECK_FUNC[S]?"
          _*               ;blanks and newlines
          "("
          _*               ;blanks and newlines
          "\\[?"
          _*               ;blanks and newlines
          $< ".*" $>
          _*               ;blanks and newlines
          "\\]?"
          _*               ;blanks and newlines
          ")"
          )
  "Autoconf AC_CHECK_FUNCS statement matcher regxp."
  )

(defconst coolock/autoconf-ac_config_srcdir_or_header
  (concat "AC_CONFIG_\\(?:SRCDIR\\|HEADER\\)"
          _*               ;blanks and newlines
          "("
          _*               ;blanks and newlines
          "\\[?"
          _*               ;blanks and newlines
          $< ".*" $>
          _*               ;blanks and newlines
          "\\]?"
          _*               ;blanks and newlines
          ")"
          )
  "Autoconf AC_CONFIG_SRCDIR and AC_CONFIG_HEADER statement matcher regxp."
  )

(defconst coolock/autoconf-ac_check_headers
  (concat "AC_CHECK_HEADERS?"
          _*               ;blanks and newlines
          "("
          _*               ;blanks and newlines
          "\\[?"
          _*               ;blanks and newlines
          $< ".*" $>
          _*               ;blanks and newlines
          "\\]?"
          _*               ;blanks and newlines
          ")"
          )
  "Autoconf AC_CHECK_HEADERS statement matcher regxp."
  )

(defconst coolock/autoconf-ac_check_lib
  (concat "AC_CHECK_LIB"
          _*               ;blanks and newlines
          "("

          _*               ;blanks and newlines
          "\\[?"
          _*               ;blanks and newlines
          $< ".*" $>
          _*               ;blanks and newlines
          "\\]?"

          ","

          _*               ;blanks and newlines
          "\\[?"
          _*               ;blanks and newlines
          $< ".*" $>
          _*               ;blanks and newlines
          "\\]?"

          _*               ;blanks and newlines
          ")"
          )
  "Autoconf AC_CHECK_LIB statement matcher regxp."
  )

(defconst coolock/autoconf-shell-keywords
  (concat Y< (regexp-opt '("for" "do" "done" "break" "case" "esac" "in"
                           "if" "else" "elif" "fi" "then") t) Y>)
  "Autoconf shell script keywords."
  )

'("\\([;(){}`|&]\\|^\\)[ 	]*\\(\\(\\(!\\|do\\|el\\(?:if\\|se\\)\\|if\\|t\\(?:hen\\|ime\\|rap\\|ype\\)\\|until\\|while\\)[ 	]+\\)?\\(!\\|b\\(?:reak\\|ye\\)\\|c\\(?:\\(?:as\\|ontinu\\)e\\)\\|do\\(?:ne\\)?\\|e\\(?:l\\(?:if\\|se\\)\\|sac\\|x\\(?:ec\\|it\\)\\)\\|f\\(?:i\\|or\\|unction\\)\\|i[fn]\\|logout\\|return\\|select\\|t\\(?:hen\\|ime\\|rap\\|ype\\)\\|until\\|while\\)[ 	]+\\)?\\(\\.\\|alias\\|b\\(?:g\\|ind\\|uiltin\\)\\|c\\(?:aller\\|d\\|om\\(?:mand\\|p\\(?:gen\\|lete\\)\\)\\)\\|d\\(?:eclare\\|i\\(?:rs\\|sown\\)\\)\\|e\\(?:cho\\|nable\\|val\\|xport\\)\\|f[cg]\\|getopts\\|h\\(?:ash\\|elp\\|istory\\)\\|jobs\\|kill\\|l\\(?:et\\|ocal\\)\\|newgrp\\|p\\(?:opd\\|rintf\\|\\(?:ush\\|w\\)d\\)\\|read\\(?:only\\)?\\|s\\(?:et\\|h\\(?:\\(?:if\\|op\\)t\\)\\|ource\\|uspend\\)\\|t\\(?:est\\|imes\\|ype\\(?:set\\)?\\)\\|u\\(?:limit\\|mask\\|n\\(?:alias\\|set\\)\\)\\|wait\\)\\>"
  (2 font-lock-keyword-face nil t)
  (6 font-lock-builtin-face))

(defconst coolock/autoconf-shell-builtin-functions
  (concat Y< (regexp-opt (sh-feature sh-builtins) t) Y>)
  "Autoconf shell script builting functions."
  )

'("\\([;(){}`|&]\\|^\\)[ 	]*\\(\\(\\(!\\|do\\|el\\(?:if\\|se\\)\\|if\\|t\\(?:hen\\|ime\\|rap\\|ype\\)\\|until\\|while\\)[ 	]+\\)?\\(!\\|b\\(?:reak\\|ye\\)\\|c\\(?:\\(?:as\\|ontinu\\)e\\)\\|do\\(?:ne\\)?\\|e\\(?:l\\(?:if\\|se\\)\\|sac\\|x\\(?:ec\\|it\\)\\)\\|f\\(?:i\\|or\\|unction\\)\\|i[fn]\\|logout\\|return\\|select\\|t\\(?:hen\\|ime\\|rap\\|ype\\)\\|until\\|while\\)\\)\\>"
  (2 font-lock-keyword-face))

(defconst coolock/autoconf-shell-functions
  (concat Y< (regexp-opt '("grep" "egrep"
                           "sed"
                           "bison" "yacc" "byacc"
                           "gm4" "m4" "gnum4"
                           "lex" "flex" "make"
                           "makeinfo" "texinfo"
                           "gcc" "g++") t) Y>)
  "Autoconf shell functions."
  )

;; Highlight my aliases for GCC Function Attributes.
(defun coolock/autoconf-mode ()
  "Fancy Autoconf Syntax Highlighting."
  (list

   ;; macro specific matchers
   (cons coolock/autoconf-ac_define
         '((1 'font-lock-variable-name-face prepend)
           (3 'font-lock-warning-face keep)
           ))
   (cons coolock/autoconf-ac_defun
         '((1 'font-lock-function-name-face t) ;Note: Override keyword-face for AC_foo in AC_DEFUN([AC_foo...
           ))
   (cons coolock/autoconf-ac_arg_with
         '((1 'font-lock-variable-name-face keep)
           ))
   (cons coolock/autoconf-ac_arg_enable
         '((1 'font-lock-variable-name-face keep)
           (2 'font-lock-warning-face keep)
           ))
   (cons coolock/autoconf-ac_msg_checking
         '((1 'font-lock-warning-face keep)
           ))
   (cons coolock/autoconf-ac_msg_result
         '((1 'font-lock-note-face keep)
           ))
   (cons coolock/autoconf-ac_msg_error
         '((1 'font-lock-warning-face keep)
           ))
   (cons coolock/autoconf-am_conditional
         '((1 'font-lock-constant-face keep)
           ))
   (cons coolock/autoconf-ac_check_types
         '((1 'font-lock-type-face keep)
           ))
   (cons coolock/autoconf-ac_check_sizeof
         '((1 'font-lock-type-face keep)
           ))
   (cons coolock/autoconf-ac_check_funcs
         '((1 'font-lock-function-name-face keep)
           ))
   (cons coolock/autoconf-ac_config_srcdir_or_header
         '((1 'font-lock-file-name-face keep)
           ))
   (cons coolock/autoconf-ac_check_headers
         '((1 'font-lock-file-name-face keep)
           ))
   (cons coolock/autoconf-ac_check_lib
         '((1 'font-lock-file-name-face keep)
           (2 'font-lock-function-name-face keep)
           ))

   ;; generic matchers
   (cons coolock/autoconf-variable-assignment
         '((1 'font-lock-variable-name-face keep)
           (2 'font-lock-operator-assignment-face keep)
           ))
   (cons coolock/autoconf-variable-ref-1
         '((2 'font-lock-variable-name-face keep)
           ))
   (cons coolock/autoconf-variable-ref-2
         '((1 'font-lock-variable-name-face keep)
           ))

   (cons coolock/autoconf-shell-keywords
         '((1 'font-lock-keyword-face keep)
           ))

   (cons coolock/autoconf-shell-builtin-functions
         '((1 'font-lock-builtin-face keep)
           ))

   (cons coolock/autoconf-shell-functions
         '((1 'font-lock-function-call-face keep)
           ))

   ;; operator matchers
   (cons (concat $< (coolock/parens) "?" $>
                 $< (coolock/braces) "?" $>
                 $< (coolock/separators) "?" $>)
         '((1 'font-lock-parens-face keep)
           (2 'font-lock-braces-face keep)
           (3 'font-lock-separator-face keep)))
   ))

;; Note: Emacs 22 sh-mode has lost font-locking of function-names so fix it.
(defun coolock/sh-function-name ()
  (list
   (cons (concat "^\\(" W+ $>
                 "[ \t]*"
                 "(")
         '(1 font-lock-function-name-face append))
   (cons (concat "\\<\\(function\\)\\>"
                 "[ \t]*"
                 $< W+ "\\)?")
         '((1 font-lock-keyword-face)
           (2 font-lock-function-name-face nil t)))
   ))

;; ToDo: Replace the previous variable highlighter with this.
(defun coolock/sh-variable-ref ()
  (list
   (cons (concat "\\$" "{#?"
                 "\\([[:alpha:]_][[:alnum:]_]*\\|[-#?@!]\\)" ;Borrowed from sh-mode
                 )
         '((1 'font-lock-variable-ref-face t)
           ))))

(defun coolock/sh-for-in ()
  (list
   (cons (concat "\\<\\(for\\)" "[ \t]*"
                 $< W+ $> "[ \t]*"
                 "\\(in\\)\\>"
                 )
         '((1 font-lock-keyword-face keep)
           (2 font-lock-variable-name-face keep)
           (3 font-lock-keyword-face keep)
           ))))

(defun coolock/sh-select-in ()
  (list
   (cons (concat "\\<\\(select\\)" "[ \t]*"
                 $< W+ $> "[ \t]*"
                 "\\(in\\)\\>"
                 )
         '((1 font-lock-keyword-face keep)
           (2 font-lock-variable-name-face keep)
           (3 font-lock-keyword-face keep)
           ))))

(defun coolock/sh-op (&optional match)
  (concat $< (unless match "?:")
          (regexp-quote-alts sh-operators)
          $>))

(defun coolock/sh-mode ()
  "Fancy Shell Script Syntax Highlighting."
  (list
   (cons (concat $< (coolock/parens) "?" $>
                 $< (coolock/braces) "?" $>
                 $< (coolock/separators) "?" $>
                 $< (coolock/sh-op) "?" $>
                 )
         '((1 'font-lock-parens-face keep)
           (2 'font-lock-braces-face keep)
           (3 'font-lock-separator-face keep)
           (4 'font-lock-operator-face keep)
           ))
   (cons (concat Y< "source" _+
                 $< CID $>
                 )
         '((1 'font-lock-file-name-face keep) ;TODO: Highlight only if \1 lies in current directory.
           ))))

(defun coolock/sh-cmd-call-not-matcher (limit)
  (null (member (match-string 2)
               '("if" "then" "do"))))   ;if not keyword
(defun coolock/sh-cmd-call ()
  "Highlighting Shell Command Call."
  (list (cons (rx (: (| (: ";"
                           (* (| space "\n")))
                        (: (not (any "\\"))
                           "\n"
                           (* (| space "\n")))
                        (: (| "if" "then" "do" "which" "type") symbol-end
                           (+ (| space "\n"))))
                     (group-n 1 (? (| "gksudo"
                                      "gksu"
                                      "sudo"
                                      "su")
                                   (+ space)))
                     (group-n 2 (: (+ (in word ?_))))
                     ))
	      '((1 'font-lock-superuser-face keep)
                (2 'font-lock-exe-name-face keep)
                )
              ;; '( ;; ANCHORED-MATCHER
              ;;   coolock/sh-cmd-call-not-matcher
              ;;   nil                     ;PRE-FORM
              ;;   nil                     ;POST-FORM
              ;;   (1 'font-lock-superuser-face keep) ; SUBEXP-HIGHLIGHTERS
              ;;   (2 'font-lock-exe-name-face keep)
              ;;   )
	      )))

(defun coolock/d-mode (&optional mode)
  (append (coolock/c-number mode)
          (coolock/d-number mode)
          (coolock/d-template-instance)
          (coolock/d-asm)
          (coolock/d-private-member-variable)
          (coolock/d-scope-or-version-constant)
          (coolock/d-const-or-immutable)
          (coolock/d-alias)
          (coolock/d-dollar)
          (coolock/d-operators)
          (coolock/hash-bang)
          (coolock/d-template-definition)
          (coolock/d-traits-call)
          (coolock/d-template-builtin-operators)
          (coolock/d-builtin-properties)
          (coolock/d-common-function-call)
          (coolock/d-lambda)
          (coolock/d-variadic-argument)
          (coolock/d-range-dots)
          (coolock/d-special-constants)
          (coolock/d-foreach)
          (coolock/variable-assignment mode)
          ))

(defun coolock/url ()
  "Fancy Shell Script Syntax Highlighting."
  (list
   (cons thing-at-point-url-regexp
         '((1 'font-lock-url-face keep)
           ))
   ))

(defun coolock/proced ()
  "Fancy Shell Script Syntax Highlighting."
  (when (require 'eshell nil t)
    (list
     (cons (concat "^" ".*" "[0-9][0-9]:[0-9][0-9]" " " $< "[^ ]+" $>)
           '((1 'eshell-ls-executable keep)
             ))
     )))

(define-minor-mode cool-light-lock-mode
  "Cool Light Font Locking Mode."
  :global nil
  :lighter " Cooler"
  ;;:group 'coolock
  (let ((activate cool-light-lock-mode))
    ;; Most
    (when (memq major-mode (append cc-derived-modes
                                   '(python-mode scons-mode)
                                   '(matlab-mode octave-mode)
                                   '(go-mode)))
      (font-lock-switch-keywords nil (append (coolock/c-common-function-call)
                                             (coolock/c-number major-mode)) activate t))
    (when (memq major-mode '(c++-mode))
      (font-lock-switch-keywords nil (append (coolock/c++11-auto-variable-definition)
                                             (coolock/c++11-nullptr)
                                             (coolock/gcc-pure)
                                             (coolock/c++11-keywords)
                                             (coolock/c++-dots)) activate t))
    (when (memq major-mode '(c-mode c++-mode objc-mode))
      (font-lock-switch-keywords nil (append (coolock/c-printf-directives)
                                             (coolock/gcc-pure)
                                             (coolock/gcc-attribute)
                                             (coolock/variable-assignment major-mode))
                                 activate t))
    (when (memq major-mode '(d-mode))
      (font-lock-switch-keywords nil (coolock/d-mode 'd-mode) activate t))

    (when (called-interactively-p 'interactive) ;Warning: If not this case things gets really slow when opening large files!
      (font-lock-fontify-buffer))
    ))

(define-minor-mode coolock-mode
  "Cool Font Locking Mode."
  :global nil
  :lighter " Coolest"
  ;;:group 'coolock
  (let ((activate coolock-mode))
    (when (memq major-mode '(c++-mode)) (font-lock-switch-keywords nil (coolock/c++) activate t))
    (when (memq major-mode '(proced-mode)) (font-lock-switch-keywords nil (coolock/proced) activate t))
    (when (memq major-mode '(python-mode scons-mode)) (font-lock-switch-keywords nil (coolock/python) activate t))
    (when (memq major-mode '(julia-mode)) (font-lock-switch-keywords nil (coolock/julia) activate t))
    (when (memq major-mode '(scons-mode)) (font-lock-switch-keywords nil (coolock/python) activate t))
    (when (memq major-mode '(ruby-mode)) (font-lock-switch-keywords nil (coolock/ruby) activate t))
    (when (memq major-mode '(emacs-lisp-mode)) (font-lock-switch-keywords nil (coolock/elisp) activate t))
    (when (memq major-mode '(octave-mode matlab-mode)) (font-lock-switch-keywords nil (coolock/octave-mode-extra) activate t))
    (when (memq major-mode '(haskell-mode)) (font-lock-switch-keywords nil (append (coolock/haskell)
                                                                                   (coolock/haskell-number)) activate t))
    (when (memq major-mode '(autoconf-mode)) (font-lock-switch-keywords nil (coolock/autoconf-mode) activate t))
    ;; (when (memq major-mode '(sh-mode)) (font-lock-switch-keywords nil (append (coolock/sh-function-name)
    ;;                                                                           (coolock/sh-variable-ref)
    ;;                                                                           (coolock/sh-for-in)
    ;;                                                                           (coolock/sh-select-in)
    ;;                                                                           (coolock/sh-cmd-call)
    ;;                                                                           (coolock/sh-mode)
    ;;     								      ) activate t))
    (when (memq major-mode '(ada-mode)) (font-lock-switch-keywords nil (coolock/ada) activate t))
    (when (memq major-mode '(c-mode c++-mode objc-mode java-mode csharp-mode
                                    python-mode scons-mode autoconf-mode ;; sh-mode
				    ))
      (font-lock-switch-keywords nil (coolock/c-printf-directives) activate t))
    (when (memq major-mode '(c-mode c++-mode objc-mode java-mode csharp-mode
                                    python-mode scons-mode octave-mode matlab-mode autoconf-mode ;; sh-mode
                                    ada-mode))
      (font-lock-switch-keywords nil (coolock/c-number) activate t))
    (when (memq major-mode '(c-mode c++-mode objc-mode java-mode csharp-mode ada-mode))
      (font-lock-switch-keywords nil (coolock/c-common-function-call) activate t))
    (when (memq major-mode '(c-mode c++-mode objc-mode java-mode csharp-mode))
      (font-lock-switch-keywords nil (append (coolock/gcc-attribute)
                                             (coolock/gcc-attribute-aliases)
                                             (coolock/c-common-function-call)
                                             (coolock/c-common major-mode)
                                             ) activate t))

    (when (memq major-mode '(d-mode))
      (font-lock-switch-keywords nil (coolock/d-mode) activate t))

    (when (called-interactively-p 'interactive) ;Warning: If not this case things gets really slow when opening large files!
      (font-lock-fontify-buffer))
    ))

(defun coolock-load-in-specific-modes ()
  (add-hook 'c-mode-hook 'cool-light-lock-mode t)
  (add-hook 'c++-mode-hook 'cool-light-lock-mode t)
  (add-hook 'objc-mode-hook 'cool-light-lock-mode t)
  (add-hook 'd-mode-hook 'cool-light-lock-mode t)
  (add-hook 'glsl-mode-hook 'cool-light-lock-mode t)
  (add-hook 'go-mode-hook 'cool-light-lock-mode t)
  (add-hook 'matlab-mode-hook 'cool-light-lock-mode t)
  (add-hook 'octave-mode-hook 'cool-light-lock-mode t)
  (add-hook 'python-mode-hook 'cool-light-lock-mode t)
  (add-hook 'scons-mode-hook 'cool-light-lock-mode t)
  (add-hook 'ada-mode-hook 'cool-light-lock-mode t)
  ;;(add-hook 'sh-mode-hook 'coolock-mode t)
  (add-hook 'ruby-mode-hook 'coolock-mode t)
  (add-hook 'emacs-lisp-mode-hook 'coolock-mode t)
  (add-hook 'elk-test-mode-hook 'coolock-mode t)
  (add-hook 'lisp-mode-hook 'coolock-mode t)
  (add-hook 'autoconf-mode-hook 'coolock-mode t)
  (add-hook 'octave-mode-hook 'coolock-mode t)
  (add-hook 'haskell-mode-hook 'coolock-mode t)
  ;;(add-hook 'lisp-interaction-mode-hook 'coolock-mode t)
  (add-hook 'julia-mode-hook 'coolock-mode t)
  )

(provide 'coolock)
;;; coolock.el ends here
