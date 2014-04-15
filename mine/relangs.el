;;; relangs.el --- Relations/Associations between (Programming) Languages and their associated modules/library APIs.
;; Author: Per Nordlöw

;;; NOTE: Underscores in patterns means at least one underscore.

;;; TODO: Represent variadics arguments as arg (0+ "," arg) or extend rx with csl1+ (Comma-Separated-List)
;;; TODO: Represent variadics arguments as (? arg (0+ "," arg)) or extend rx with csl0+ (Comma-Separated-List)

;; TODO: Integrate `relangs-ada-c-types' and D-C-C++ aswell at http://dlang.org/ctod.html

;; TODO: http://www.dsource.org/projects/visuald/wiki/Tour/CppConversion
;; TODO: Merge in patterns from coolock.el and pnw-regexps.el and use as eldoc hints.
;; TODO: http://en.literateprograms.org/
;; TODO: http://www.algorithmist.com/
;; TODO: http://www.wikivs.com/wiki/Main_Page
;; TODO: http://rosettacode.org/wiki/Rosetta_Code
;; TODO: git://github.com/stefanhusmann/emacs-else.git
;; TODO: feval(@(x)x+1,1) and \see http://www.mathworks.com/matlabcentral/newsreader/view_thread/280225
;; TODO: Extend eldoc to provide mark-sensitive documentation for code.
;; TODO: Last Element: C++ *x.rbegin(), D x[$-1]
;; TODO: http://wiki.glfw.org/wiki/Moving_from_GLFW_2_to_3

(defconst relangs-Shell-to-D-regexp-replacements
  '(
    ("^\\([[:space:]]*\\)#" "\\1//")
    ((concat "[[:space:]]*" "\\(" ID "\\)" "[[:space:]]*" "=") "\\1auto\\2")
    ((concat "^\\([[:space:]]*\\)function[[space]]*" "(" "\\(" SHELL_ID "\\)" ")") "\1auto") ;TODO: Make function name a D ID
    ("\\([^$]\\)#" "\\1")
    )
  "Mappings from Shell to D.")

(require 'case-utils)
(require 'pnw-regexps)

;;;###autoload
(defgroup relangs nil
  "Relations between between different languages (and their APIs)."
  :group 'tools)

(defun define-relation (a x b)
  "Define a relation X from A to B."
  (cond ((symbolp a)
         (put a x b))
        (t
         (plist-put a x b))))

(defun homo-relate (a x b)
  "Relate A and B to each other as X.
X defaults to :related"
  (define-relation a x b)
  (define-relation b x a))

(defun hetro-relate (a x b y)
  "Relate A as AR to B and B as BR to A."
  (define-relation a x b)
  (define-relation b y a))

(defun define-translation-2 (a b)
  "Define translations between A and B."
  (homo-relate a 'translation b))

(defun define-translation-3 (a b c)
  "Define translations between A, B and C."
  (define-translation-2 a `(,b ,c))
  (define-translation-2 b `(,c ,a))
  (define-translation-2 c `(,a ,b)))

(define-translation-3
  'c++-tbb-containers
  'c++-amp-containers
  'c++-ppl-containers)

(defun define-opposites (a b)
  "Define A and B to be opposites of each other."
  (homo-relate a 'opposite b))

(defconst relangs-string-synonyms
  (make-hash-table :test 'equal))

(defun relangs-define-synonomys (a b &optional mode)
  "Define A and B to be synonyms of each other."
  (cond ((and (stringp a)
              (stringp b))
         (puthash a b relangs-string-synonyms)
         (puthash b a relangs-string-synonyms))
        ((and (symbolp a)
              (symbolp b))
         (homo-relate a 'synonym b))
        ))
(relangs-define-synonomys "C++0x" "C++11")
(relangs-define-synonomys "visual-studio" "vc")
(relangs-define-synonomys "version control system" "vcs")
(relangs-define-synonomys "emacs-lisp" "elisp")
(relangs-define-synonomys '(| " 2> {{X}}  > {{X}}"
                              "  > {{X}} 2> {{X}}")
                          "&> /dev/null")
(relangs-define-synonomys "if[[:space:]]+which\>"
                          "if[[:space:]]+type"
                          'sh-mode)

(defun relatesp (a x b)
  "Check if A has an X-relation to B."
  (eq (plist-get a x) b))

(defun relangs-are-opposites (a b)
  "Return non-nil if A and B are opposites of each other."
  (and (relatesp a 'opposite b)
       (relatesp b 'opposite a)))
(defalias 'relangs-opposites-p 'relangs-are-opposites)

(defconst relangs-get-current-directory
  (lambda ()
    `((:lang Python :expr "getcwd()" :import "os")
      (:lang D :expr "getcwd()" :import "std.file")
      (:lang Emacs :expr "default-directory")
      )) "Get current time")

(defconst relangs-make-directory
  (lambda (dir)
    `((:lang Python :expr (: "makedir" _ "(" _ ,dir _ ")") :import "os")
      (:lang Shell  :expr (: "mkdir" _ ,dir "..."))
      (:lang Emacs  :expr (: "(make-directory" _ ,dir ")"))
      (:lang D      :expr (: "std.file.mkdir" _ "(" ,dir _ ")") :import "std.file")
      )) "Make directory DIR.")
(defconst relangs-make-directories
  (lambda (dir)
    `((:lang Python :expr (: "makedirs" _ "(" _ ,dir _ ")") :import "os")
      (:lang Shell  :expr (: "mkdir" _ "-p" _ ,dir "..."))
      (:lang Emacs  :expr (: "(make-directory" _ ,dir _ "t" _ ")"))
      (:lang D      :expr (: "std.file.mkdirRecursive" _ "(" ,dir _ ")") :import "std.file")
      )) "Make directory DIR including its parents.")

(defconst relangs-convert-to-string
  (lambda (expr)
    `((:lang C++ :expr (: "boost:lexical_cast<std::string>(" expr ")"))
      (:lang D :expr (: "to!string(" expr ")"))
      (:lang Python-2 :expr (: "str(" expr ")"))
      )) "Convert EXPR to a string.")

(defconst relangs-print
  (lambda (expr)
    `((:lang C :expr (: "puts(" expr ")") :if ("isstring(expr)"))
      (:lang C++ :expr (: "std::cout << " expr))
      (:lang D :expr (: "write(" (+ expr) ")"))
      (:lang Python-2 :expr (: "print" _ expr))
      (:lang Python-2.6 :expr (: "PrettyPrinter(indent=1, depth=None, with=80).pprint(" expr ")") :import "pprint")
      (:lang Python :expr (: "print(" expr ")") ) ;to make it easier to redirect prints in servers
      (:lang Java :expr (: "System.out.println(" expr ")"))
      (:lang Lisp :expr (| ("(message " expr ")")
                           ("(error " expr ")")))
      (:lang Matlab :expr (: "display(" expr ")"))
      (:lang Shell :expr (: "echo " expr))
      )) "Print Expression EXPR.")

(defconst relangs-print-line
  (lambda (expr)
    `((:lang C++ :expr (: "std::cout << " expr " << std::endl"))
      (:lang D :expr (: "writeln(" (+ expr) ")"))
      )) "Print EXPR on a separate line.")

(defconst relangs-get-current-time
  (lambda (x)
    `((:lang C :expr (: (| (| "gmtime"
                              "gmtime_r")
                           (| "localtime"
                              "localtime_r")) "(" ,x ")"))
      (:lang Emacs :expr ("(current-time)" "(float-time)"))
      (:lang Matlab :expr ("now" "()"))
      )) "Get Current Time")

(defconst relangs-format-time
  (lambda (x)
    `((:lang C :expr ((| "ctime"
                         "ctime_r") "(" ,x ")"))
      (:lang Emacs :expr ("(format-time-string " ,x ")"))
      (:lang Matlab :expr ("datestr(" ,x ")"))
      ))
  "Format timer")

(defconst relangs-binary-number
  (lambda ()
    `((:lang (Ada) :regexp "[^[:digit:]]2#[[01]]+#")
      (:lang (D) :regexp "binary![:digit:]")
      (:lang (D Java Python C++14) :pre-regexp "[^0-9a-zA-Z]" :regexp "0[bB][01_]+" :post-regexp "[^2-9a-zA-Z]" :see "https://en.wikipedia.org/wiki/C%2B%2B14#Binary_literals")
      (:lang (Emacs-Lisp) :regexp "#b[[01]]+")
      ))
  "Binary Number")

(defconst relangs-octal-number
  (lambda ()
    `((:lang (C C++ D) :regexp "[^[:digit:]]0[0-7]+")
      (:lang (Ada) :regexp "[^[:digit:]]8#[[:xdigit:]]+#")
      (:lang (D) :regexp "octal![:digit:]")
      ))
  "Octal Number")

(defconst relangs-hexadecimal-number
  (lambda ()
    `((:lang (C C++ D) :regexp "[^[:digit:]]0x[[:xdigit:]]+")
      (:lang (Ada) :regexp "[^[:digit:]]16#[[:xdigit:]]+#")
      (:lang (Emacs-Lisp) :regexp "#x[[:xdigit:]]+")
      ))
  "Hexadecimal Number")

(defconst relangs-scan-formatted
  (lambda ()
    `((:lang C :expr (| "scanf"
                        "fscanf"
                        "sscanf"))
      (:lang C++-STL)
      (:lang Emacs :expr ("search-forward"
                          "search-backward"
                          "re-search-forward"
                          "re-search-backward"))
      (:lang Matlab :expr "textscan")
      )) "Formatted Scanning")

(defconst relangs-channels
  (lambda ()
    `((:lang C++11 :expr "Future-Promise")
      (:lang D :expr "")
      (:lang Go :expr "Channels")
      )) "Empty (Undefined) Constant Literal Value")

(defconst relangs-future
  (lambda (type)
    `((:lang C++11 :expr (: (| "future"
                               "shared_future") "<" ,type ">"))
      (:lang Java :expr (: "Future" "<" ,type ">"))
      (:lang C\# :expr (: "Task" "<" ,type ">"))
      (:lang D :expr nil)
      )) "Wrap TYPE into a Future.")

(defconst relangs-undefined
  (lambda ()
    `((:lang (C C++) :expr (| "NULL" "0" "(void*)0")) ;in order of preference
      (:lang C++11 :expr "nullptr")
      (:lang D :expr "null")
      (:lang Go :expr "nil")
      (:lang Java :expr "0")
      (:lang Lisp :expr "nil")
      (:lang Ruby :expr "nil")
      (:lang Python :expr "None")
      (:lang Haskell :expr "Nothing")
      (:lang Matlab :expr (| "[]" "{}") :comment "Empty Matrix or Cell Array")
      )) "Empty/Undefined/Null Literal Constant Value")

(defconst relangs-nonnull
  (lambda ()
    `((:lang D :expr (not "@nullable")) ;TODO: Support inverse logic
      (:lang Ada2005 :expr (: "not" "null"))
      )) "Empty/Undefined/Null Literal Constant Value")

(defconst relangs-nothrow
  (lambda ()
    `((:lang C++11 :expr "noexcept")
      (:lang D :expr "nothrow")
      )) "Empty/Undefined/Null Literal Constant Value")

(defconst relangs-currying
  (lambda ()
    `((:lang (C C++) :expr "bind")
      (:lang Haskell :expr "Currying")
      )) "Currying.")

(defconst relangs-type-limit-min-or-max
  (lambda ()
    `((:lang C++ :expr "std::numeric_limits<" type-id ">::" (| "min" "max") "()" :import "limits")
      (:lang D :expr (: type-id "." (| "min" "max")))
      )) "")

(defconst relangs-void
  (lambda ()
    `((:lang (C C++ Java C\# D) :expr "void")
      )) "Void Type.")

(defconst relangs-char-array-type
  (lambda ()
    `((:lang (C C++) :expr (: "char" "*"))
      (:lang Ada :expr (| "Interfaces.C.char_array"))
      )) "Character Array Type.")

(defconst relangs-char
  (lambda ()
    `((:lang (C C++ D) :expr "char")
      )) "Character Type.")

(defconst relangs-signed-char
  (lambda ()
    `((:lang (C C++) :expr "signed char")
      (:lang C\# :expr "sbyte")
      (:lang D :expr "byte")
      (:lang Ada :expr (| "Character"
                          "Interfaces.C.char"
                          "Interfaces.C.signed_char"
                          "Interfaces.C.plain_char"
                          "Byte_Integer"
                          "Short_Short_Integer"))
      )) "Signed Character Type.")

(defconst relangs-unsigned-char
  (lambda ()
    `((:lang (C C++) :expr (: "unsigned" "char"))
      (:lang D :expr (: "ubyte"))
      (:lang Ada :expr (| "Interfaces.C.unsigned_char"))
      )) "Unsigned Character Type.")

(defconst relangs-wide-char
  (lambda ()
    `((:lang (C C++) :expr "wchar_t")
      (:lang D :expr "wchar")
      (:lang Ada :expr "Interfaces.C.wchar_t")
      )) "Wide Character Type.")

(defconst relangs-integer-type
  (lambda ()
    `((:lang (C C++ Java C\# D) :expr "int")
      (:lang Ada :expr (| "Integer"
                          "Interfaces.C.C_int"))
      (:lang Modelica :expr "Integer")
      )) "Integer Type with Default Machine Precision.")

(defconst relangs-unsigned-integer-type
  (lambda ()
    `((:lang (C C++) :expr (| "unsigned"
                              "unsigned int"))
      (:lang (Java) :expr nil)          ;not supported
      (:lang (C\# D) :expr "uint")
      (:lang Ada :expr (| "Integer"
                          "Interfaces.C.unsigned"))
      )) "Unsigned Integer Type with Default Machine Precision.")

(defconst relangs-short-integer-type
  (lambda ()
    `((:lang (C C++ Java C\# D) :expr "short")
      (:lang Ada :expr (| "Short_Integer"
                          "Interfaces.C.short"))
      )) "Short Integer Type.")

(defconst relangs-unsigned-short-integer-type
  (lambda ()
    `((:lang (C C++ Java) :expr "unsigned short")
      (:lang (D C\#) :expr "ushort")
      (:lang Ada :expr "Interfaces.C.unsigned_short")
      )) "Unsigned Short Integer Type.")

(defconst relangs-long
  (lambda ()
    `((:lang (C C++) :expr "long")    ;TODO: case on architecure type
      (:lang D :expr "int")
      (:lang Ada :expr (| "Long_Integer"
                          "Interfaces.C.long"))
      )) "Signed 32-Bit Integer Type.")

(defconst relangs-unsigned-long
  (lambda ()
    `((:lang (C C++ Java) :expr "unsigned long") ;TODO: case on architecure type
      (:lang (D C\#) :expr "uint")
      (:lang Ada :expr "Interfaces.C.unsigned_long")
      )) "Unsigned 32-bit Integer Type.")

(defconst relangs-long-long
  (lambda ()
    `((:lang (C C++) :expr "long long")
      (:lang (C\# D) :expr "long")
      (:lang Ada :expr "Long_Long_Integer")
      )) "Signed 64-bit Integer Type.")
(defconst relangs-unsigned-long-long
  (lambda ()
    `((:lang (C C++) :expr (: "unsigned" "long" "long"))
      (:lang (C\# D) :expr "ulong")
      )) "Unsigned 64-bit Integer Type.")

(defconst relangs-single-precision-float
  (lambda ()
    `((:lang (C C++ Java C\# D) :expr "float")
      (:lang Ada :expr (| "Float"
                          "Interfaces.C.C_float"))
      (:lang Matlab :expr "single")
      )) "Floating Point Type with 32-bits precision.")

(defconst relangs-single-precision-double
  (lambda ()
    `((:lang (C C++ Java C\# D) :expr "double")
      (:lang Ada :expr (| "Long_Float"
                          "Interfaces.C.double"
                          "Interfaces.C.long_double"))
      (:lang Matlab :expr "double")
      )) "Floating Point Type with 64-bits precision.")

(defconst relangs-long-double
  (lambda ()
    `((:lang (C C++) :expr "long double")
      (:lang D :expr "real")
      )) "Floating Point Type with 80-bits precision.")

(defconst relangs-utf8-string-type
  (lambda ()
    `((:lang D :expr "string")
      )) "UTF-8 String Types.")

(defconst relangs-utf16-string-type
  (lambda ()
    `((:lang C\# :expr "string")
      (:lang D :expr "wstring")
      )) "UTF-16 String Types.")

(defconst relangs-float-type
  (lambda ()
    `((:lang (Matlab) :expr "single")
      (:lang (C C++ C\# Java D) :expr "float")
      )) "Single-Precision Floating Point Types.")

(defconst relangs-double-type
  (lambda ()
    `((:lang (C C++ C\# Java D Matlab) :expr "double")
      )) "Double-Precision Floating Point Types.")

(defconst relangs-long-double-type
  (lambda ()
    `((:lang (C C++) :expr (: "long" "double"))
      )) "Long-Double-Precision Floating Point Types.")

(defconst relangs-imaginary
  (lambda ()
    `((:lang C :expr (: "_Imaginary" relangs-float-type))
      (:lang D :expr (: "i" relangs-float-type))
      )) "Imaginary Floating Point Type")

(defconst relangs-complex
  (lambda ()
    `((:lang C :expr (: "_Complex" relangs-float-type))
      (:lang D :expr (: "i" relangs-float-type))
      )) "Complex Floating Point Type")

(defconst relangs-builtin-data-types
  '(relangs-integer-type
    relangs-unsigned-integer-type
    relangs-short-integer-type
    relangs-long
    relangs-long-long
    relangs-single-precision-float
    relangs-single-precision-double
    relangs-long-double)
  "Language Built-In Primitive Data Types.")

(defun relangs-limits-minimum (type)
  "Minimum Value of TYPE."
  (lambda ()
    `((:lang C :expr (cond ((equal type "char") "CHAR_MIN")
                           ((equal type "short") "SHORT_MIN")
                           ((equal type "int") "INT_MIN")
                           ((equal type "long") "LONG_MIN")
                           ((equal type "float") "FLT_MIN")
                           ((equal type "double") "DBL_MIN")) :import "limits.h")
      (:lang C++ :expr (: "std::numeric_limits<" type ">::min()") :import "limits")
      (:lang D :expr (: type ".min")))))
;; Use: (relangs-limits-minimum "int")
;; Use: (relangs-limits-minimum "float")

(defun relangs-limits-maximum (type)
  "Maximum Value of TYPE."
  (lambda ()
    `((:lang C :expr (cond ((equal type "char") "CHAR_MAX")
                           ((equal type "short") "SHORT_MAX")
                           ((equal type "int") "INT_MAX")
                           ((equal type "long") "LONG_MAX")
                           ((equal type "unsigned char") "UCHAR_MAX")
                           ((equal type "unsigned short") "USHORT_MAX")
                           ((equal type "unsigned int") "UINT_MAX")
                           ((equal type "unsigned long") "ULONG_MAX")
                           ((equal type "float") "FLT_MAX")
                           ((equal type "double") "DBL_MAX")) :import "limits.h")
      (:lang C++ :expr (: "std::numeric_limits<" type ">::max()") :import "limits")
      (:lang D :expr (: type ".max")))))
;; Use: (relangs-limits-maximum "int")
;; Use: (relangs-limits-maximum "float")

(defun relangs-byte-sizeof-type (expr)
  "Byte Size of EXPR."
  (lambda ()
    `((:lang (C C++ D) :expr (: "sizeof" "(" expr ")"))
      (:lang D :expr (: expr ".sizeof"))))) ;TODO: Automatically brace around char*
;; Use: (relangs-byte-sizeof-type "float")
;; Use: (relangs-byte-sizeof-type "double")

(defconst relangs-limits-maximum
  (lambda (type)
    `((:lang D :expr (: type ".mant_dig"))
      )) "Number of Mantissa Digits in Floating Point Type")

(defconst relangs-named-parameter
  (lambda (N V)
    `((:lang Python
             :expr `(: ,N "=" ,V))
      (:lang C\#-4.0
             :expr `(: ,N ":" ,V))
      (:lang Ada
             :expr `(: ,N "=>" ,V) :ref "http://en.wikibooks.org/wiki/Ada_Programming/Subprograms#Named_parameters")
      )) "Function Parameter named N of value V.")

(defconst relangs-optional-type
  (lambda (type)
    `((:lang C++ :expr (: (| "boost" "std") "::optional<" type  ">") :import "boost/optional.hpp")
      (:lang D :expr (: "Nullable" _ "!" type))
      (:lang Haskell :expr (: "Maybe" _ type)) ;Monad
      (:lang C\# :expr (| (: "Nullable" _ "<" _ type _ ">")
                          (: type "?")))
      (:lang Scala :expr (: "Option[" type "]"))
      )) "Template wrapping value types to having an additional undefined state.

See
- https://akrzemi1.wordpress.com/2012/12/13/constexpr-unions/
- http://channel9.msdn.com/Shows/Going+Deep/C-and-Beyond-2012-Andrei-Alexandrescu-Systematic-Error-Handling-in-C")

;;; Complex Numbers
(defconst relangs-complex-numbers
  '(relangs-complex-number-type
    relangs-complex-number-literal
    relangs-imaginary-unit
    relangs-complex-real-part
    relangs-complex-imag-part
    relangs-complex-abs
    relangs-complex-arg)
  "Complex Numbers.")
(defconst relangs-complex-number-type
  (lambda ()
    `((:lang C99 :expr "_Complex" :import "complex.h")
      (:lang C++ :expr "std::complex" :import "complex")
      (:lang D :expr "std::complex" :import "std.complex")
      )) "Complex Number Type")
(defconst relangs-complex-number-literal
  (lambda ()
    `((:lang (Matlab D) :expr (: real "+" imag "i"))
      )) "Complex Number Literal Expression")
(defconst relangs-imaginary-unit
  (lambda ()
    `((:lang C99 :expr "_Complex_I")
      )) "Imaginary Unit")
(defconst relangs-complex-real-part
  (lambda (x)
    `((:lang C99 :expr (: "creal(" x ")"))
      )) "Real Part of Complex Number")
(defconst relangs-complex-imag-part
  (lambda (x)
    `((:lang C99 :expr (: "cimag(" x ")"))
      )) "Imaginary Part of Complex Number")
(defconst relangs-complex-abs
  (lambda (x)
    `((:lang C99 :expr (| "cabs(" x ")"
                          "cabsf(" x ")"
                          "cabsl(" x ")"))
      )) "Absolute Value (Magnitude) of of Complex Number")
(defconst relangs-complex-arg
  (lambda (x)
    `((:lang C99 :expr (| "carg(" x ")"
                          "cargf(" x ")"
                          "cargl(" x ")"))
      )) "Argument (Angle) of Complex Number")

;; \see https://en.wikipedia.org/wiki/Automatic_variable
(defconst relangs-auto-variable-type-storage-class-qualifier
  (lambda ()
    `((:lang (C++11 D) :expr (: "auto"))
      (:lang (JavaScript C\#-3.0) :expr (: "var"))
      (:lang Java :expr nil)            ;not available
      )) "Automatic Variable Type Storage Class Qualifier")

(defconst relangs-reference-type-name
  (lambda (type)
    `((:lang (C++ D Java) :expr "Reference Type")
      (:lang (C) :expr "Pointer Type")
      (:lang (Ada) :expr "Access Type")
      )))

(defconst relangs-variable-reference
  (lambda (type)
    `((:lang C :expr (,type "&"))
      (:lang D :expr ("ref" _ ,type))
      )) "Variable Reference to Variable Instance of type TYPE.")

(defconst relangs-variable-definition
  (lambda (name type value)
    `((:lang Shell :expr (: ,name "=" ,value)) ;TODO; Express that whitespace is not allowed around =
      (:lang Emacs-Lisp :expr (: "(" L* "def" (| "var" "custom") L* ,name L+ ,value ")"))
      (:lang (C C++) :expr (: ""))
      )) "Definition of Variable Named NAME having Value VALUE.")

(defconst relangs-constant-definition
  (lambda (name type value)
    `(
      (:lang Shell :reuse relangs-variable-definition) ;TODO: Support `:reuse'
      (:lang Emacs-Lisp :expr (: "(" L* "defconst" L* name L+ value ")"))
      (:lang (C C+) :expr (: "const" type name "=" value ";"))
      (:lang D :expr (: "enum" name "=" value ";")) ;NOTE: Type inferred from VALUE
      )) "Definition of Constant Named NAME having Value VALUE.")

(defconst relangs-list-head
  (lambda ()
    `((:lang Emacs-Lisp :expr (: "(car {{X}})"))
      (:lang Haskell :expr (: "head ({{X}})"))
      )) "List Head of {{X}}")

(defconst relangs-list-tail
  (lambda (X)
    `("Tail of {{X}}"
      (:lang Emacs-Lisp :expr (: "(cdr {{X}})"))
      (:lang Haskell :expr (: "tail ({{X}})"))
      )) "List Tail of X.")

(defconst relangs-type-definition
  (lambda (X)
    `("Tail of {{X}}"
      (:lang C :expr (: "typedef ... {{X}};"))
      (:lang Haskell :expr (: "data {{X}} = ...")) ;data Bool = True | False
      )) "List Tail of {{X}}")

(defconst relangs-concept-type-trait
  (lambda (X)
   `(
     (:lang C++ :header "type_traits")
     (:lang D :module "std.traits" :ref "http://dlang.org/concepts.html")
     )) "Concepts and Type Traits")

(defconst relangs-case-sensitivity
  (lambda ()
    `((:lang (Ada Fortran-77) :expr t)
      )) "Language Case Sensitivity")

(defconst relangs-boolean
  (lambda ()
    `((:lang C99 :expr (| "bool" "_Bool") :import "stdbool.h")
      (:lang C++ :expr (: "bool"))
      (:lang C\# :expr (: "bool"))
      (:lang D :expr (| (: "bit")
                        (: "bool")))
      (:lang Java :expr (: "boolean"))
      (:lang Haskell :expr (: "Bool"))
      (:lang Matlab :expr (: "logical"))
      (:lang Fortran-77 :expr (: "logical"))
      )) "Boolean Type")

(defconst relangs-true
  (lambda ()
    `((:lang C :expr (| "1" "TRUE"))
      (:lang C99 :expr (: "true"))
      (:lang C++ :expr (: "true"))
      (:lang C\# :expr (: "true"))
      (:lang Java :expr (: "true"))
      (:lang Lisp :expr (: "t"))
      (:lang Ruby :expr (: "true"))
      (:lang Python :expr (: "True"))
      (:lang Haskell :expr (: "True"))
      (:lang Matlab :expr (: "true"))
      (:lang Ada :expr (: "True"))
      (:lang Fortran-77 :expr (: ".TRUE."))
      )) "True Value")

(defconst relangs-false
  (lambda ()
    `((:lang C :expr (| "0" "FALSE"))
      (:lang C99 :expr (: "false"))
      (:lang C++ :expr (: "false"))
      (:lang C++11 :expr (: "false"))
      (:lang C\# :expr (: "false"))
      (:lang Java :expr (: "false"))
      (:lang Lisp :expr (: "nil"))
      (:lang Ruby :expr (: "false"))
      (:lang Python :expr (: "False"))
      (:lang Haskell :expr (: "False"))
      (:lang Matlab :expr (: "false"))
      (:lang Ada :expr (: "False"))
      (:lang Fortran-77 :expr (: ".FALSE."))
      )) "False Value")

(defconst relangs-relational-less-than
  (lambda ()
    `((:lang (C++) :expr (: "std::cmp"))
      (:lang (Python) :expr (: "__cmp__"))
      )) "Compare/Sig")

(defconst relangs-to-string-conversion
  (lambda (expr)
    `((:lang (C++) :expr (: "boost::lexical_cast<std::string>(" expr ")"))
      (:lang (D) :expr (: "toString(" expr ")"))
      (:lang (Python) :expr (: "str(" expr ")"))
      )) "To String Conversion of expression EXPR.")

;;; Relational
(defconst relangs-relational-less-than
  (lambda ()
    `((:lang (C C++ D Java C\# Ada) :expr (: "<"))
      (:lang Fortran-77 :expr (: ".LT."))
      )) "Relational Less-Than Operator")
(defconst relangs-relational-greater-than
  (lambda ()
    `((:lang (C C++ D Java C\# Ada) :expr (: ">"))
      (:lang Fortran-77 :expr (: ".GT."))
      )) "Relational Greater-Than Operator")
(defconst relangs-relational-less-than-or-equal
  (lambda ()
    `((:lang (C C++ D Java C\# Ada) :expr (: "<="))
      (:lang Fortran-77 :expr (: ".LE."))
      )) "Relational Less-Than or Equal Operator")
(defconst relangs-relational-greater-than-or-equal
  (lambda ()
    `((:lang (C C++ D Java C\# Ada) :expr (: ">="))
      (:lang Fortran-77 :expr (: ".GE."))
      )) "Relational Greater-Than or Equal Operator")

;;; Contents Equality
(defconst relangs-content-equality-operator
  (lambda (x y)
    `((:lang (C C++ D Java C\# Python Ruby) :expr (: x "==" y))
      (:lang Fortran-77 :expr (: x (| ".EQV." ".EQ.") y)) ;TODO: Prefer EQV
      (:lang Matlab :expr (| (: x "==" y)
                             (: "eq(" x "," y ")")))
      (:lang Emacs-Lisp :expr (: "(equal" x y ")"))
      (:lang (Ada Pascal) :expr "=")
      )) "Contents Equality Operator")
(defconst relangs-content-not-equality-operator
  (lambda (x y)
    `((:lang (C C++ D Java C\# Python Ruby) :expr (: "!="))
      (:lang Fortran-77 :expr (| ".NEQV." ".NE.")) ;TODO: Prefer NEQV
      (:lang Matlab :expr (| "~="
                             "ne(X,Y)"))
      (:lang Emacs-Lisp :expr (: "(not (equal" x y ")" ")"))
      (:lang (Ada) :expr "/=")
      )) "Contents Non-Equality Operator")
(define-opposites
  relangs-content-equality-operator
  relangs-content-not-equality-operator)

;;; Object Equality
(defconst relangs-object-equal-operator
  (lambda (x y)
    `((:lang (Python) :expr (x "is" y))
      (:lang (Ruby) :expr (x "equal?" y))
      (:lang Emacs-Lisp :expr (: "(eq " x ", $Y$)"))
      )) "Object Equality Operator of X and Y")

;;; Arithmetic
(defconst relangs-arithmetic-addition
  (lambda ()
    `((:lang (C C++ D Java C\#) :expr "+")
      (:lang Matlab :expr (| ".+" "+"))
      )) "Arithmetic Addition Operator")
(defconst relangs-arithmetic-subtraction
  (lambda ()
    `((:lang (C C++ D Java C\#) :expr "-")
      (:lang Matlab :expr (| ".+" "-"))
      )) "Arithmetic Subtraction Operator")
(defconst relangs-arithmetic-division
  (lambda ()
    `((:lang (C C++ D Java C\#) :expr "/")
      (:lang Matlab :expr (| "./" "/"))
      )) "Arithmetic Division Operator")
(defconst relangs-arithmetic-modulus-or-remainder
  (lambda ()
    `((:lang (C C++ D Java C\#) :expr "%" :arity 2 :kind operator)
      (:lang (Matlab Ada) :expr "mod" :arity 2 :kind function)
      )) "Arithmetic Division Remainder (Modulus) Operator")
(defconst relangs-arithmetic-absolute
  (lambda ()
    `((:lang (Matlab Ada Emacs-Lisp) :expr "abs" :arity 1)
      (:lang (C++) :expr "std::abs")
      )) "Arithmetic Absolute Value")
(defconst relangs-arithmetic-power
  (lambda (base exponent)
    `((:lang (Fortran Python Ruby Ada) :expr (: base "**" exponent))
      (:lang Matlab :expr (: base (| ".^" "^")  exponent))
      (:lang D :expr (: base "^^" exponent))
      (:lang Pascal :expr (: "Exp(" base "," exponent ")"))
      (:lang C :expr (: (opt "c") (| ("pow")
                                     ("powf")
                                     ("powl")
                                     )
                        "(" base "," exponent ")"))
      )) "Arithmetic Power (Exponentation) Operator of to the power of exponent")

(defun relangs-arithmetic-floating-point-remainder (type x y)
  "Floating Point Division Remainder."
  `((:lang (Matlab Ada) :expr "rem" :arity 2)
    (:lang (C C++) :expr ,(cond ((equal type "float") (list "fmodf(" x "," y))
                                ((equal type "double") (list "fmod(" x "," y))
                                ((equal type "long double") (list "fmodl(" x "," y))))
    (:lang (D) :expr ,(list x "%" y))))
;; Use: (relangs-arithmetic-floating-point-remainder "float" 'alpha 'beta)
;; Use: (relangs-arithmetic-floating-point-remainder "double" 'alpha 'beta)

;;; Logical
(defconst relangs-logical-and
  `((:lang C :expr (: "&&"))
    (:lang C++ :expr (| "&&" "and"))
    (:lang Ada :expr (: "and"))
    (:lang Lisp :expr (: "(and X..."))
    (:lang Fortran-77 :expr (: ".AND."))
    ) "Logical And Operation")
(defconst relangs-logical-or
  `((:lang C :expr (: "||"))
    (:lang C++ :expr (| "||" "or"))
    (:lang Ada :expr (: "or"))
    (:lang Lisp :expr (: "(| X..."))
    (:lang Fortran-77 :expr (: ".OR."))
    ) "Logical Or Operation")
(defconst relangs-logical-not
  `((:lang C :expr (: "!"))
    (:lang C++ :expr (| "!" "not"))
    (:lang Ada :expr (: "not"))
    (:lang C\# :expr (: "!"))
    (:lang Java :expr (: "!"))
    (:lang Lisp :expr (: "null"))
    (:lang Haskell :expr (: "not"))
    (:lang Matlab :expr (| "~" "not"))
    (:lang Fortran :expr (: ".NOT."))
    ) "Logical Negation (NOT) Operator")
(defconst relangs-logicals '(relangs-logical-and
                                       relangs-logical-or
                                       relangs-logical-not
                                       ) "Logical Operations")

(defconst relangs-bitwise-and
  `((:lang (C C++) :expr (: "&"))
    (:lang C++ :expr (: "bitand"))
    (:lang Ada :expr (: "and"))
    (:lang Emacs-Lisp :expr (: "logand"))
    ) "Bitwise And Operation")
(defconst relangs-bitwise-or
  `((:lang (C C++) :expr (: "&"))
    (:lang C++ :expr (: "bitor"))
    (:lang Ada :expr (: "or"))
    (:lang Emacs-Lisp :expr (: "logior"))
    ) "Bitwise Or Operation")
(defconst relangs-bitwise-xor
  `((:lang (C C++) :expr (: "^"))
    (:lang C++ :expr (: "bitxor"))
    (:lang Ada :expr (: "xor"))
    (:lang Emacs-Lisp :expr (: "logxor"))
    ) "Bitwise XOr (Exclusive Or) Operation")
(defconst relangs-bitwise-not
  `((:lang (C C++) :expr (: "~"))
    (:lang C++ :expr (: "bitnot"))
    (:lang Ada :expr (: "not"))
    (:lang Emacs-Lisp :expr (: "lognot"))
    ) "Bitwise Not Operation")
(defconst relangs-bitwises '(relangs-bitwise-and
                                       relangs-bitwise-or
                                       relangs-bitwise-xor
                                       relangs-bitwise-not
                                       ) "Bitwise Operations")

(defconst relangs-variable-assign
  `((:lang (C C++ D C\# Java Haskell Matlab Fortran) :expr (: "X = V"))
    (:lang Haskell :expr (: "<-"))
    (:lang Lisp :expr (: "(setq X V)"))
    (:lang (Make Pascal Go Ada) :expr (: "X := V"))
    )
  "Variable X Assignment to V")

(defconst relangs-range-operator
  (lambda (x y)
    `((:lang Haskell :expr ("[" ,x ".." ,y "]"))
      (:lang Matlab :expr (,x _ ":" _ ,y))
      (:lang (D Ada) :expr (,x _ ".." _ ,y))
      )) "Range Operator")

(defconst relangs-membership-operator
  (lambda (x y)
    `((:lang Ada :expr (: x "in" y))
      (:lang Java :expr (: x ".isinstance(" y ")"))
      )) "Membership")

(defconst relangs-negated-membership-operator
  (lambda (x y)
    `((:lang Ada :expr (: x "not" "in" y))
      (:lang D :expr (: "!" "(" x "in" y ")"))
      )) "Negated Membership")

(defconst relangs-lambda-expression
  (lambda (x)
    `((:lang C++11 :expr (: "[](" x ") { return" x "> 10; }"))
      (:lang D :expr (: "" x " =>" x "> 10"))
      (:lang Python :expr (: "lambda " x ":" x "> 10"))
      (:lang Emacs-Lisp :expr (: "(lambda (X) (> X 10))"))
      )) "Lambda Expression")

(defconst relangs-list
  `((:lang Lisp :expr ("'" _ "(" _ ")"))
    (:lang Haskell :expr ("[" _ "]"))
    ) "List")

(defconst relangs-list-append
  (lambda (x y)
    `((:lang Lisp :expr ("(append" _ ,x _ ,y ")"))
      (:lang Haskell :expr (,x _ "++" _ ,y))
      )) "List Append Operation")

(defconst relangs-list-cons
  (lambda (X Y)
    `((:lang Lisp :expr ("(cons" _ ,X _ ,Y _ ")"))
      (:lang Haskell :expr (,X _ ":" _ ,Y))
      )) "List Cons Operation of Elements X and Y")

(defconst relangs-list-index
  `((:lang Lisp :expr (: "(nth N LIST)"))
    (:lang Haskell :expr (: "LIST !! N"))
    ) "List Cons Operation")

(defconst relangs-typeof
  (lambda (object)
    `((:lang C :expr (: "typeof(" ,object ")") :static)
      (:lang C++ :expr (: "decltype(" ,object ")") :static)
      (:lang (C\# C++-GCC D) :expr (: "typeof(" ,object ")") :static)
      (:lang Matlab :expr (: "class(" ,object ")"))
      (:lang Python :expr (: "type(" ,object ")"))
      (:lang Ruby :expr (: ,object "." type) :ref "http://stackoverflow.com/questions/2192335/is-there-a-ruby-equivalent-for-the-typeof-reserved-word-in-c")
      ))
  "Type-Of Expression/Value Operator of Expression E,XPR.")

(defconst relangs-has-type
  (lambda (object type)
    `((:lang Emacs :expr ("(typep" _ ,object _ ,type ")"))
      (:lang Python :expr ("(isinstance" "(" ,object "," ,type ")"))
      (:lang Ruby :expr (: ,object (| ".is_a?" ".is_instance?") _ ,type) :ref "http://stackoverflow.com/questions/2192335/is-there-a-ruby-equivalent-for-the-typeof-reserved-word-in-c")
      )) "OBJECT Has TYPE Predicate.")

(defconst relangs-map-algorithm
  (lambda ()
    `((:lang Emacs :expr (| "map"
                            "mapcar"))
      (:lang Python :expr (: "map"))
      (:lang C++ :expr (: "std::for_each"))
      (:lang D :expr (: "foreach(index, element, range"))
      )) "Map (For Each) Algorithm.")

(defconst relangs-reduce-algorithm
  `((:lang Python :expr (: "reduce") :ref "http://docs.python.org/2/library/functions.html#reduce")
    (:lang C++ :expr (: "std::accumulate") :ref "http://en.cppreference.com/w/cpp/algorithm/accumulate" :include "numeric")
    ) "Reduce (Accumulate) Algorithm.")

(defconst relangs-minimum-algorithm
  (lambda (x)
    `((:lang Emacs :expr (: "(min x, ...)"))
      (:lang Python :expr (: "min(x, ...)"))
      (:lang C++ :expr (: "std::min(x, y)"))
      (:lang GLSL :expr (: "min(x, y)") :ref "http://www.opengl.org/sdk/docs/manglsl/xhtml/max.xml")
      (:lang Ruby :expr (: "[" x "]" "." "min") :ref "http://stackoverflow.com/questions/1359370/how-do-you-find-a-min-max-with-ruby")
      )) "Minimum Algorithm.")

(defconst relangs-maximum-algorithm
  (lambda (x)
    `((:lang Emacs :expr (: "(max x, ...)"))
      (:lang Python :expr (: "max(x, ...)"))
      (:lang C++ :expr (: "std::max(x, y)"))
      (:lang GLSL :expr (: "max(x, y)") :ref "http://www.opengl.org/sdk/docs/manglsl/xhtml/max.xml")
      (:lang Ruby :expr (: "[" x "]" "." "max") :ref "http://stackoverflow.com/questions/1359370/how-do-you-find-a-max-max-with-ruby")
      )) "Maximum Algorithm.")

(defconst relangs-minimum-maximum-algorithm
  (lambda (x)
    `((:lang C++ :expr (: "std::minmax(x,y)"))
      (:lang Ruby :expr (: "[" ,x "...]" "." "minmax") :ref "http://stackoverflow.com/questions/1359370/how-do-you-find-a-min-max-with-ruby")
      )) "Minimum and Maximum of values in X.")

(defconst relangs-linear-interpolation-algorithm
  (lambda (x y a)
    `((:lang C++ :expr (: "glm::mix(" ,x "," ,y ","" a )") :import "glm/glm.hpp")
      (:lang GLSL :expr (: "mix(" x "," ,y ","" a )") :ref "http://www.opengl.org/sdk/docs/manglsl/xhtml/mix.xml")
      )) "Linear Interpolation Algorithm.
That is return x ⋅ ( 1 − a ) + y ⋅ a")

(defconst relangs-string-type-predicate
  (lambda (X)
   `((:lang Matlab :expr ("ischar(" ,X ")" "isstr(" ,X ")"))
     (:lang Emacs :expr (: "(stringp ") ,X ")")
     (:lang Python :expr (: "isinstance(") ,X ", str")
     "Vector Value Predicate.")))

(defconst relangs-undefined-type-predicate
  `((:lang Matlab :expr (: "isempty"))
    (:lang Emacs :expr (: "null"))
    (:lang Haskell :expr (: "null"))
    ))

(defconst relangs-directory-type-predicate
  `((:lang Matlab :expr (: "isdir"))
    (:lang Emacs :expr (: "file-directory-p"))
    )
  )

(defconst relangs-vector-type-predicate
  `((:lang Matlab :expr (: "isvector"))
    (:lang Emacs :expr (: "vectorp"))
    )
  "Vector Value Predicate.")

(defconst relangs-float-type-predicate
  `((:lang Matlab :expr (: "isfloat"))
    (:lang Emacs :expr (: "floatp"))
    )
  "Floating Point Type Value Predicate.")

(defconst relangs-nan-value-predicate
  `((:lang (C C++) :expr (: "isnan"))
    (:lang Matlab :expr (: "isnan"))
    (:lang Emacs :expr (: "isnan"))
    (:lang Emacs :expr (: "isNaN"))
    )
  "Non-A-Number (NaN) Value Predicate.")

(defconst relangs-finite-value-predicate
  `((:lang C :expr (: "isfinite"))
    (:lang D :expr (: "isFinite"))
    )
  "Finite Value Predicate.")

(defconst relangs-finite-value-predicate
  `((:lang C :expr (: "isinf"))
    (:lang D :expr (: "isInfinity"))
    )
  "Infinite Value Predicate.")

(defconst relangs-sign-bit-integer
  `((:lang C :expr (: "signbit(" value ")"))
    (:lang D :expr (: "signbit(" value ")"))
    )
  "Return 1 if sign bit of X is set, 0 if not.")

(defconst relangs-function-local
  `((:lang Matlab :expr (: "persistent"))
    (:lang C :expr (: "static"))
    ))

(defconst relangs-function-definition
  (lambda (X)
   `((:lang Python :expr (: "def " ,X "():"))
     (:lang C :expr (: ,X "()"))
     (:lang Emacs-Lisp :expr (: "(defun " ,X " ()"))
     )))

(defconst relangs-function-call
  `((:lang Matlab :expr (: "feval"))
    (:lang Emacs-Lisp :expr (: "funcall"))
    ))

(defconst relangs-matlab-predicates
  '(|
    "isa" "isactiveuimode" "isappdata"
    "isccslinkinstalled" "iscell" "iscellstr" "iscom" "isdeployed"
    "isdfgate" "isdynpropenab" "isequal"
    "isequalwithequalnans" "isfdhdlcinstalled" "isfdtbxinstalled" "isfield"
    "isfinite" "isfixptinstalled" "isglobal" "ishandle" "ishghandle"
    "ishold" "isinf" "isinteger" "isinterface" "isjava" "iskeyword" "isletter"
    "islogical" "ismac" "ismcc" "ismembc" "ismembc2" "ismember" "ismethod"
    "isnumeric" "isobject" "isocaps" "isocolors" "isonormals" "isosurface" "ispc"
    "isplotchild" "ispref" "isprime" "isprop" "isreal" "isreserved" "isscalar"
    "issimulinkinstalled" "issorted" "issourcecontrolconfigured" "isspace"
    "issparse" "isspblksinstalled" "isstrprop" "isstruct" "isstudent"
    "isunix" "isvarname")
  "False Value")

;;; See: https://github.com/aldacron/Derelict3/pull/80#issuecomment-12763120
(defconst relangs-glfw-update
  `((:lang C-GLFW :expr (| "glfwGetError" "glfwErrorString"))
    (:lang C-GLFW-Update :expr (: "GLFWerrorfun to glfwSetErrorCallback"))
    ))

(define-opposites relangs-true relangs-false)
;; Use: (relangs-are-opposites relangs-true relangs-false)
;; Use: (plist-get relangs-true 'opposite)

(defconst relangs-assertion
  (lambda (X M)
    `((:lang C :expr (: "assert(" ,X ")") :ref "man://assert")
      (:lang C++11 :expr (: "static_assert(" ,X "," ,M ")") :ref "http://en.wikipedia.org/wiki/C%2B%2B0x#Static_assertions")
      (:lang C++-Boost :expr (: "BOOST_STATIC_ASSERT(" ,X ")") :ref "http://www.boost.org/doc/libs/1_44_0/doc/html/boost_staticassert.html")
      (:lang D :expr (| "assert(" ,X "," ,M ")"
                        "enforce(" ,X "," ,M ")"))
      (:lang Python :expr (: "assert " ,X "," ,M ""))
      ))
  "Assert expression X to true. If false stop and optionally display M.
See: http://en.wikipedia.org/wiki/Assertion_(computing)")

(defconst relangs-assert-equal
  (lambda (X Y)
   `((:lang (C C++ D) :expr (: "assert(" ,X "==" ,Y ")"))
     (:lang (C C++) :expr (: "enforce_eq(" ,X "," ,Y ")"))
     (:lang (D) :expr (: "assertEqual(" ,X "," ,Y ")"))
     (:lang Emacs-Lisp :expr (: "(assert-equal " ,X " ",Y ")"))
     ))
  "Assert that expression X and Y have same contents.")

(defconst relangs-plotting
  (lambda (X)
    `((:lang Matlab :expr ("figure(" ,X ")" "clf"))
      (:lang Matlab :expr ("plot(" ,X ")"))
      (:lang Matlab :expr ("axes(" ,X ")" "cla"))
      )) "Plotting X")

(defconst relangs-matlab-global-states
  `((:lang Matlab :expr ("assignin"))
    (:lang Matlab :expr ("global"))
    (:lang Matlab :expr ("set" "get"))
    (:lang Matlab :expr ("setappdata" "getappdata" "isappdata" "rmappdata"))
    ) "Function that modify global variable states, making functions non-pure")

(defconst relangs-arguments
  `((:lang Matlab :keyword ("nargin"
                            "nargout"
                            "varargin"
                            "varargout"))
    ) "Plot X")

(defconst relangs-input-argument
  (lambda (T X)
    `((:lang Ada :expr (: "in" X) :ref "http://en.wikibooks.org/wiki/Ada_Programming/Keywords/in")
      (:lang C :expr (: (| "const*"
                           "const") T X))
      (:lang C++ :expr (: "const" T "&" X))
      (:lang D :expr (| (: "ref" "const(" Y ")" X)
                        (: Y X)))
      )) "Input Argument X of type T.")

(defconst relangs-output-argument
  (lambda (T X)
    `((:lang Ada :expr (: "in" X) :ref "http://en.wikibooks.org/wiki/Ada_Programming/Keywords/out")
      (:lang C :expr (: (? "*") T X))
      (:lang C++ :expr (: T "&" X))
      )) "Ouput Argument X of T.")

(defconst relangs-structure-end
  `((:lang Matlab :expr ("" x "(end)"))
    (:lang D :expr ("" x "($)"))
    (:lang C++ :expr ("" x "(" x ".size())"))
    ) "Get end of struct X")

(defconst relangs-structure-last
  `((:lang C++ :expr ("" x ".back()"))
    (:lang D :expr ("" x "[$-1]"))
    ) "Return last of element of structure X")

(defconst relangs-array-initializer-definition
  `((:lang (C C++) :expr (: type "a[] = { 1,2,3,4 }"))
    (:lang D :expr (| (: type "a[] = [ 1,2,3,4 ]")
                      (: "auto a = [ 1,2,3,4 ]")))
    ) "")

(defconst relangs-full-array-slice
  `((:lang D :expr ("" x "[]"))
    (:lang D :expr ("" x "[0..$]"))
    ) "Return whole slice of X")

(defconst relangs-number-to-string
  (lambda (x y)
   `((:lang Emacs-Lisp :expr ("(string-to-number " x ")"))
     (:lang Python :expr (: "(float " x ")"))
     )) "Interpret string $X$ as a number.")

(define-opposites 'number-to-string 'string-to-number)

(defconst relangs-current-graphics-state
  `((:lang Matlab :expr ("gcf"
                         "gca"
                         "gco"
                         "gcbo"
                         "gcbf"))
    ) "Current Graphics State")

(defconst relangs-string-type
  (lambda (x y)
    `((:lang C :type "char* ")
      (:lang C++ :expr "std::string ")
      (:lang Java :expr "String")
      (:lang Modelica :expr "String")
      )) "String Type.")

(defconst relangs-string-definition
  (lambda (x y)
   `((:lang C :type (: "char* " x ";") :depend "string.h" :length (: "strlen(" x ")"))
     (:lang C++ :type (: "std::string " x ";") :depend "string" :length-member (: "" x ".size()"))
     (:lang Java :type (: "String " x ";") :depend "java.util.String" :length-member (: "" x ".length()"))
     (:lang Lisp )
     )) "Define a string object X.")

(defconst relangs-use
  `((:lang C++ (| "using std::cout"
                  "using namespace std"))
    (:lang VHDL "use  ieee.std_logic_1164.all;"))
  "Use feature X")

(defconst relangs-basics
  '(
    ;; Naming Standards and Conventions
    (:name ("Method Name" 'x)
           :C c-id-regexp
           :C++ c-id-regexp
           :Ruby ruby-id-regexp
           )
    (:name ("Constant Declaration" 'x)
           :C "const"
           :D "immutable"
           :C\# "readonly"
           :C++ "const"
           :Ruby (lambda (x) (upcased-p x))
           )
    (:name ("Class Name" 'x)
           :C c-id-regexp
           :C++ c-id-regexp
           :Ruby (lambda (x) (capitalized-p x))
           )
    (:name ("Variable Name" 'x)
           :C c-id-regexp
           :C++ c-id-regexp
           :Ruby (lambda (x) (downcased-p x))
           )

    ;; Type Instantiation
    (:name ("X Constuctor" "ctor")
           :C++ "X::X()"
           :Ruby "initialize()")
    (:name ("X Destructor" "dtor")
           :C++ "X::~X()"
           :Matlab "clear"
           )

    ;; Create and Delete Resources as Memory (and Object Type)
    (:name ("Allocate")
           :C "malloc"
           :C-GLib ("g_malloc" "g_malloc_n"
                    "g_malloc0" "g_malloc0_n"
                    "g_try_malloc" "g_try_malloc0")
           :C-SAMBA "talloc" ;A hierarchical, reference counted memory pool system with destructors.
           )
    (:name ("Allocate-Zeroed")
           :C "calloc"
           )
    (:name ("Reallocate")
           :C "realloc"
           :C-GLib ("g_realloc" "g_try_realloc"
                    "g_realloc_n" "g_try_realloc_n")
           :C-GLib "g_renew"
           )
    (:name ("Stack-Allocate")
           :C "alloca"
           :C-GLib ("g_alloca")
           :C-GLib ("g_newa")
           )
    (:name ("Create")
           :C-GLib ("g_new" "g_try_new")
           :C-GLib ("g_new0" "g_try_new0")
           :C++ "new"
           :Matlab implicit
           :Java implicit               ;TODO: Correct?
           )

    (:name ("Delete")
           :C "free"
           :C-GLib "g_free"
           :C++ "delete"
           :Matlab "clear"
           :Java implicit               ;TODO: Correct?
           )

    ;; Inheritance
    (:name ("Multiple Inheritance")
           :C++ 'yes
           :Ruby "No, but mixins inherits all instance methods of a module"
           )
    (:name ("Virtual Member Function")
           :C++ 'when-specified
           :Ruby 'always
           )
    (:name ("Object Self Reference")
           :C++ "this"
           :Ruby "self")
    (:name ("Argument Passing")
           :C ('by-reference 'by-value)
           :C++ ('by-reference 'by-value)
           :Ruby ('by-reference)
           )

    ;; Data Structures
    ;; Use For C\# and C++ use code conversion .org and http://stackoverflow.com/questions/3659044/comparison-of-c-stl-collections-and-c-sharp-collections
    (:structure ("Array")
                :lang (C C++) "$T$ variable[length]" ;if length is known at compile type its a static array otherwise a dynamic array
                :lang (C++) "std::valarray<$T$> variable(data, length)"
                :lang (C++11) "std::array<$T$,length> variable"  ;NOTE: Add restriction that N must known at compile-time
                :lang (C++14) "std::dynarray<$T$> variable(length)"  ;NOTE: Add restriction that N cannot grow after construction.

                :lang Ada (| "variable : T(0..length+$OFFSET$)"
                             "variable is array (0..length+$OFFSET$) of T") ;called constrained type
                :lang Fortran-77 "$T$ variable(length)"
                :lang C\# "Array<$T$> V"
                )
    (:structure ("Vector")
                C++ "std::vector<$T$>"
                C\# "List<$T$>"      ;Non-Conformant Name!
                Lisp (: "(setq" x "make-vector())")
                )
    (:structure ("Sorted Vector")
                C\# "SortedList<TKey,TValue>"
                )
    (:structure ("Array")
                :Ruby "Array x"
                :Python "np.array()"
                )
    (:structure (| "Hash Table"
                   "Hash Map"
                   "Dictionary")
                :C++ "std::hash_map<Key,Data>"
                :C++11 "std::unordered_map<Key,Data>"
                :C\# "Dictionary<TKey, TValue>"
                :Ruby "Hash x"
                :Lisp "(setq x make-hash-table())"
                :Python (| "x = dict()"
                           "x = {}")
                )
    (:structure ("Set")
                :C++ "std::set<Key>"
                :C\# "SortedSet<Key>"
                )
    (:structure ("Hash Set")
                :C++ "std::hash_set<Key>"
                :C\# "HashSet<T>"
                )
    (:structure ("Map")
                :C++ "std::map<Key, Data>"
                :C\# "SortedDictionary<Key, Value>"
                )
    (:structure ("Queue")
                :C++ "std::queue<T>"
                :C\# "Queue<T>"
                )
    (:structure ("Stack")
                :C++ "std::stack<T>"
                :C\# "Stack<T>"
                )
    (:structure ("Singly-Linked-List")
                :C++ "std::dlist<T>"
                )
    (:structure ("Double-Linked-List")
                :C++ "std::list<T>"
                :C\# "LinkedList<T>"
                )

    (:name ("Threading")
           :C 'extension
           :C++ 'extension
           :Ruby 'built-in              ;Green Threads
           :Lisp 'not-possible
           )

    (:name ("Unit Test")
           :C 'extension
           :C++ 'extension
           :Ruby 'built-in
           :Lisp 'extension
           )

    (:name ("Type Conversion")
           :C ('implicit 'explicit)
           :C++ ('implicit 'explicit)
           )
    )
  "List of Basic Relation between Programming Languages."
  )

(defconst relangs-type-predicates
  (lambda (X)
    `(
      ("File " ,X " (of Any type) Exist"
       (:lang (Bash Zsh) :expr (: "-a " ,X ""))
       (:lang Emacs-Lisp :expr (: "(file-exist-p \"" ,X "\")"))
       (:lang Matlab :expr (: "exist('" ,X "', 'file')"))
       (:lang Python :expr ("exists"))
       (:lang D :expr (: ,X ".exists") :import "std.file")
       )
      ("Directory " ,X " Exist"
       (:lang (Bash Zsh) :expr (: "-d " ,X ""))
       (:lang Emacs-Lisp :expr (: "(file-directory-p \"" ,X "\")"))
       (:lang Matlab :expr (: "exist('" ,X "', 'dir')"))
       (:lang Python :expr ("isdir"))
       (:lang D :expr (: ,X ".isDir") :import "std.file")
       )
      ("Regular File " ,X " Exist"
       (:lang (Bash Zsh) :expr (: "-f " ,X ""))
       (:lang Emacs-Lisp :expr (: "(file-regular-p \"" ,X "\")"))
       (:lang Python :expr ("isfile"))
       (:lang D :expr (: ,X ".isFile") :import "std.file")
       )
      ("Symbolic Link File " ,X " Exist"
       (:lang Emacs-Lisp :expr (: "(file-symlink-p \"" ,X "\")"))
       (:lang Python :expr ("islink"))
       (:lang D :expr (: ,X ".isSymlink") :import "std.file")
       )

      ("Variable " ,X " Exist"
       (:lang Emacs-Lisp :expr (: "(boundp \"" ,X "\")"))
       (:lang Matlab :expr (: "exist('" ,X "', 'var'"))
       )
      ("Function " ,X " Exist"
       (:lang Emacs-Lisp :expr (: "(functionp \"" ,X "\")"))
       )
      ("Builtin Function " ,X " Exist"
       (:lang Emacs-Lisp :expr (: "(subrp \"" ,X "\")"))
       (:lang Matlab :expr (: "exist('" ,X "' , 'builtin')"))
       )
      )) "List of Associations between File Predicate (Functions).")

(defconst file-directory-predicates
  '(
    ;; ** File/Directory Predicates
    ;; - [[file-accessible-directory-p]]
    ;; - [[file-begin-p]]
    ;; - [[file-compressed-p]]
    ;; - [[file-directory-p]]
    ;; - [[file-executable-magic-is-ELF-p]]
    ;; - [[file-executable-p]]
    ;; - [[file-exists-p]]
    ;; - [[file-locked-p]]
    ;; - [[file-magic-is-ELF-exe-p]]
    ;; - [[file-magic-is-ELF-obj-p]]
    ;; - [[file-magic-is-ELF-p]]
    ;; - [[file-name-absolute-p]]
    ;; - [[file-newer-than-file-p]]
    ;; - [[file-oprofileable-p]]
    ;; - [[file-ownership-p]]
    ;; - [[file-readable-p]]
    ;; - [[file-regular-p]]
    ;; - [[file-remote-p]]
    ;; - [[file-symlink-p]]
    ;; - [[file-writable-p]]
    )
  "List of Associations between File/Directory Predicates."
  )

(defconst relangs-elisp-operations
  `(("definitions"
     (ldefun defun defmacro defmacro* defmacro defsubst
             defsubst* defconst defconst defclass))
    ("functions"
     (defun defmacro defmacro))
    ("data"
     (defconst defconst))
    ("types"
     (defclass))
    ("conditionals"
     (if when cond case while unless))
    ("loop/iterations"
     (for-each do while))
    ("predicates"
     ((functionp fbuiltinp)
      (boolean-p numberp number-or-marker-p markerp bool-vector-p)
      ))
    ("function-predicates"
     (functionp builtinp))
    ("structure-construction"
     ((make-list make-vector make-bool-vector make-string make-hash-table make-ring)
      (make-syntax-table make-keymap make-face))
     )
    ("structure-element-indexing"
     ((elt nth aref)
      (nthcdr)))
    ("file-operations"
     (find-file-.*)
     (write-file)
     )
    ("buffer-operations"
     (current-buffer set-buffer save-current-buffer with-current-buffer with-temp-buffer)
     (buffer-name rename-buffer get-buffer get-buffer-create get-buffer-window)
     (pop-to-buffer switch-to-buffer switch-to-buffer-other-window)
     (display-buffer)
     ;; TODO: Compare with (select-window (get-buffer-window buf))
     )
    ("string-operations"
     (string-match))
    ("buffer-navigation"
     ())
    ("comparison-equality"
     (equal eq eql =))
    ("comparison-less-than"
     (< <=))
    ("comparison-greater-than"
     (> >=))
    ("modify/alter/change"
     (put setq set-.*
          setcar setcdr
          setf psetf))
    ("serialization-operations"
     (prin1-to-string read-from-string))
    ("set-operations"
     (append concat nconc concatenate mapconcat))
    ("list-iteration"
     (dolist))
    ("state-push-and-pop-savers"
     (save-excursion save-current-buffer save-window-excursion save-restriction
                     save-match-data save-point save-selected-window save-stop))
    ("duplicates"
     (remove-duplicates delete-dups delete-duplicates))
    )
  "List of Associations between Emacs Lisp Similar
  Objects. Use (assoc KEY) to lookup")

(defconst relangs-shallow-copy
  (lambda (X)
    `(
      (:lang Python :expr (: "copy(" ,X ")") :import copy)
      (:lang Ruby :expr (: "" ,X ".dup"))
      )) "Return of Shallow Copy X")

(defconst relangs-deep-copy
  (lambda (X)
    `(
      (:lang Python :expr (: "deepcopy(" ,X ")") :import copy)
      (:lang Ruby :expr (: "x.clone"))
      (:lang D :expr (: "dup(" ,X ")"))
      )) "Return of Deep Copy X")

(defconst relangs-uniquify-elements
  (lambda (X)
    `(
      (:lang Emacs-Lisp :expr (: "(delete-dups " ,X ")"))
      (:lang Haskell :expr (: "Data.List.nub"))
      (:lang Python :expr (: "list(set(" ,X "))") :when "isinstance(" ,X ",list)")
      (:lang D :expr (: "uniq(" ,X ")") :import "std.algorithm")
      )) "Uniquify/Delete Elements in X")

(defconst relangs-unique-pointer
  (lambda (T V)
    `(
      (:lang C++ :expr (: "std::unique_ptr<" ,T "> " ,V " = std::make_unique<" T ">();") :import "memory")
      (:lang D :expr (: "shared " ,T " " ,V " = new " ,T ";") :ref ("http://forum.dlang.org/thread/mailman.1191.1368248719.4724.digitalmars-d@puremagic.com?page=3"
                                                                 "http://wiki.dlang.org/DIP29"))
      )) "Allocate Unique Pointer of Type T stored in variable V.")

(defconst relangs-containing-directory-of-filename
  (lambda (X)
    `(
      (:lang Emacs-Lisp :expr (: "(file-name-directory " ,X ")"))
      (:lang C          :expr (: "dirname(" ,X ")") :include "libgen.h")
      (:lang D          :expr (: "dirName(" ,X ")") :import "std.path")
      (:lang Shell      :expr (: "dirname " ,X))
      (:lang GNU-Make   :expr (: "$(dir " ,X ")"))
      (:lang Python     :expr (: "dirname(" ,X ")") :import "os.path")
      (:lang Matlab     :expr (: "fileparts(" ,X ")"))
      )) "Containing Directory part of Filename (path) X.")

(defconst relangs-filename-directory
  (lambda (X)
    `(
      (:lang Emacs-Lisp :expr (: "(file-name-nondirectory ") ,X ")")
      (:lang GNU-Make   :expr (: "$(notdir ") ,X ")")
      (:lang C          :expr ("basename(" ,X ")") :include "libgen.h")
      (:lang D          :expr (: "baseName(") ,X ")" :import "std.path")
      )) "Filename X without any leading directory part.")

(defconst relangs-filename-base
  (lambda (X)
   `(
     (:lang Emacs-Lisp :expr (: "(file-name-sans-extension ") ,X ")")
     (:lang GNU-Make :expr (: "$(basename ") ,X ")")
     (:lang Python :expr (: "splitext(") ,X ")[0]" :import "os.path")
     (:lang D :expr (: "std.path.stripExtension(") ,X ")" :import "std.path")
     )) "Get Extension of filename if any")

(defconst relangs-filename-extension
  (lambda (X)
    `(
      (:lang Emacs-Lisp :expr (: "(file-name-extension " ,X ")"))
      (:lang GNU-Make :expr (: "$(suffix " ,X ")"))
      (:lang Python :expr (: "splitext(" ,X ")[1][1:].strip()") :import "os.path")
      )) "Get Extension of filename X if any.")

(defconst relangs-combine-canonicalize-path
  (lambda (X)
    `(
      (:lang Emacs-Lisp :expr (: "(expand-file-name " ,X ")"))
      (:lang Python :expr (: "normpath(" ,X ")") :import "os.path")
      (:lang Matlab :expr (: "fullfile(" ,X ")"))
      (:lang GNU-Make :expr (: "$(abspath " ,X ")"))
      (:lang D :expr (: "std.path.buildNormalizedPath(" ,X ")"))
      )) "Canonicalize Path X")

(defconst relangs-combine-combine-diretory-and-file
  (lambda (file dir)
    `(
      (:lang Emacs-Lisp :expr (: "(expand-file-name " ,file " " (? ,dir) ")")) ;NOTE: dir is optional
      (:lang Python :expr (: "join(" ,dir "," ,file ")") :import "os.path")
      (:lang D :expr (: "buildPath(" ,dir "," ,file ")") :import "std.path")
      )) "Combine Filenames or Paths")

(define-opposites
  'expand-file-name
  'abbreviate-file-name)

(defconst relangs-string-lower-case
  (lambda (X)
   `(
     (:lang C :expr (: "tolower(" ,X ")"))
     (:lang Emacs-Lisp :expr (: "(downcase " ,X ")"))
     (:lang Python :expr (: ,X ".lower()"))
     (:lang Ruby :expr (: ,X ".downcase"))
     (:lang Matlab :expr (: "lower(" ,X ")"))
     ))  "String X Lower Cased")

(defconst relangs-string-upper-case
  (lambda (X)
    `(
      (:lang C :expr (: "toupper(" ,X ")"))
      (:lang Emacs-Lisp :expr (: "(upcase " ,X ")"))
      (:lang Python :expr (: ,X ".upper()"))
      (:lang Ruby :expr (: ,X ".upcase"))
      (:lang Matlab :expr (: "upper(" ,X ")"))
      )) "String X Upper Casesd")

(defconst relangs-string-capitalize
  (lambda (X)
    `(
      (:lang Emacs-Lisp :expr (: "(capitalize " ,X ")"))
      (:lang Python :expr (: ,X ".capitalize()"))
      )) "String Capitalize.")

(defconst relangs-string-length
  (lambda (X)
    `(
      (:lang Emacs-Lisp :expr (: "(string-length " ,X ")"))
      (:lang Python :expr (: "len(" ,X ")"))
      (:lang Ruby :expr (| (: ,X ".length")
                           (: ,X ".size")))
      (:lang D :expr (: ,X ".length"))
      )) "Length of String X")

(defconst relangs-string-concatenation
  (lambda (x y)
    `(
      (:doc (: "String Concatenation/Appending of " ,x " and " ,y "."))
      (:lang C :bin-fun (: "strcat(" ,x "," ,y ")"))
      (:lang C++ :bin-op (: ,x "+" ,y))
      (:lang Ada :bin-op (: ,x "&" ,y))
      (:lang D :bin-op (: ,x "~" ,y))
      (:lang Haskell :binop (: ,x "++" ,y))
      (:lang Emacs-Lisp :nary-fun (: "(" "concat" _ ,x _ ,y ")"))
      (:lang Python :bin-op (: ,x "+" ,y))
      (:lang Fortran-77 :bin-op (: ,x "//" ,y))
      ) "Concatenate Strings X and Y."))
;; Use: (funcall relangs-string-concatenation "111" "222")

(defconst relangs-array-append
  (lambda (x y)
    `((:doc (: "Append " ,y " to end of the Array " ,x ".")) (:see "http://stackoverflow.com/questions/14114228/add-to-a-dynamic-array-in-d")
      (:lang Python :expr (: ,x ".append(" ,y ")") :if (:lang Python "isinstance(",x", list)"))
      (:lang C++ :expr (: ,x "push_back(" ,y ")"))
      (:lang D :expr (: ,x " ~= " ,y) :if (and (is-of array ,x)
                                             (| (is-of element ,y)
                                                (is-of array ,y))))
      )) "Append Y to end of array X.")
;; Use: (funcall relangs-array-append 111 222)

(defconst relangs-list-of-strings-to-string
  (lambda (X)
    `(
      (:lang Emacs-Lisp :expr (| "(mapconcat 'identity " ,X " "
                                 "(reduce 'identiy " ,X ")") :when "(sequencep " ,X ")")
      (:lang Python :expr (: "reduce(operator.add, ") ,X ")" :when "isinstance(" ,X ", list)")
      "List of Strings X to String Concatenation")))

(defconst relangs-string-replace
  (lambda (OLD NEW X)
    `(
      (:lang Emacs-Lisp :expr (: ,X ".replace(" ,OLD "," ,NEW ")"))
      (:lang Bash :expr (: "${" ,X "/" ,OLD "/" ,NEW "}"))
      (:lang Zsh :expr (: "${" ,X "/" ,OLD "/" ,NEW "}"))
      "Replace OLD with NEW in String Varible X.")))

(defconst relangs-string-replace
  (lambda (REGEXP REP STRING)
    `(
      (:lang Emacs-Lisp :expr (: "(replace-regexp-in-string " ,REGEXP " " ,REP " " ,STRING ")"))
      (:lang Python :expr (: "re.sub(" ,REGEXP "," ,REP "," ,STRING ""))
      "String Regular Expression REGEXP with Replacement REP in STRING.")))

(defconst relangs-positive-numbers
  (lambda ()
    `(
      (:lang Haskell :expr (: "1.."))
      (:lang D :expr (: "siota"))
      (:lang Python :expr (: "xrange (1"))
      )) "Positive Numbers Generator.")

(defconst relangs-emacs-lisp-function-groups
  '(
    ("member" "equal" "assoc" "delete-list-members")
    ("memq" "eq" "assq" "delq")
    ) "List of Relations between Emacs Lisp Language Function Groups.")

(defconst relangs-member-predicate-operator
  '(
    (:lang Emacs-Lisp :expr (| "(memq $ELEMENT$ $SET$)"
                               "(member $ELEMENT$ $SET$)"))
    (:lang Python :expr ("($ELEMENT$ in $SET$)"))
    ) "Set Member Operator")

(defconst relangs-?-:
  (lambda (P T F)
    `(
      (:lang (C C++ D) :expr (: ,P "?" ,T ":" ,F))
      (:lang Python :expr (: ,T if ,P else ,F))
      )) "Ternary Operator.")

(relangs-define-synonomys "(global-set-key KEY-COMMAND 'SYMBOL-NAME)"
                          "(define-key global-map KEY-COMMAND 'SYMBOL-NAME)")


;;; ===========================================================================

(defconst relangs-level-one-header
  (lambda (text)
    `((:lang LaTeX :expr (: "\\section" "{" ,text "}"))
      (:lang Markdown :expr (: "# " ,text " "))
      (:lang HTML :expr (: "<h1>" ,text "</h1>"))
      )) "Level One Header")

(defconst relangs-bold-font-style
  (lambda (text)
    `((:lang Tex :expr (: "{" "\\bf" text "}"))
      (:lang LaTeX :expr (: "\\textbf" "{" text "}"))
      (:lang Markdown :expr (: "**" text "**"))
      (:lang HTML :expr (: "<b>" text "</b>"))
      (:lang DDoc :expr (: "$(B" text ")"))
      )) "Bold font style of TEXT.")

(defconst relangs-italic-font-style
  (lambda (text)
    `((:lang Tex :expr (: "{" "\\it" text "}"))
      (:lang LaTeX :expr (: "\\textit" "{" text "}"))
      (:lang Markdown :expr (: "*" text "*"))
      (:lang HTML :expr (: "<i>" text "</i>"))
      (:lang DDoc :expr (: "$(I" text ")"))
      )) "Italic font style of TEXT.")

(defconst relangs-small-caps-font-style
  (lambda (text)
    `((:lang LaTeX :expr (: "\\textsc" "{" text "}"))
      )) "Small caps font style of TEXT.")

(defconst relangs-emphasize-font-style
  (lambda (text)
    `((:lang LaTeX :expr (: "\emph{" text "}"))
      (:lang Markdown :expr (: "*" text "*"))
      (:lang HTML :expr (: "<emph>" text "</emph>"))
      )) "Italic font style of TEXT.")

(defconst relangs-underline-font-style
  (lambda (text)
    `((:lang LaTeX :expr (: "\\ul{" text "}"))
      (:lang HTML :expr (: "<ul>" text "</ul>"))
      (:lang DDoc :expr (: "$(U" text ")"))
      )) "Underline font style of TEXT.")

(defconst relangs-link-font-style
  '(
    (:lang Markdown :expr (lambda (text url) (: "[" text "]" "(" url ")")))
    ) "Link")

;;; ===========================================================================
;;; My Own List of Synonyms

(defconst relangs-synonyms-and-acronyms
  '(
    (copy (cp) clone)
    (move (mv) rename)
    (remove (rm) delete erase destroy clear)
    (run execute (exec) call)
    (shift translate)
    (mirror reverse)
    (vector array)
    ) "List of Associations Synonyms often used in Computer and
  Programming Contexts")

(defun relangs-vc-revert ()
  "Version Control Revert."
  `((:lang SVN :expr (: "svn revert"))
    (:lang Hg :expr (: "hg revert") :ref "http://stackoverflow.com/questions/2239331/using-hg-revert-in-mercurial")
    (:lang Git :expr (: "git reset --hard HEAD^"))
    ))

(defconst relangs-design-patterns
  '(

    ("Fundamental patterns"
     "Encapsulation or Information hiding" "Provide indirect methods for manipulating object or class data, instead of letting external code manipulate it directly. Use internal code to ensure that changes are handled properly (e.g. perform input validation, maintain invariants or normalization)." :class fundamental)

    ("Inheritance or subclassing" "Inherit methods from a parent class, to reuse code." :class fundamental)
    ("Exceptions" "Programming language structures support \"throwing\" and \"catching\" errors or \"exceptions\". This prevents code from being cluttered with error checks, and centralizes error handling to avoid repetition." :class fundamental)

    ;; Creational: This design patterns is all about class
    ;; instantiation. This pattern can be further divided into
    ;; class-creation patterns and object-creational patterns. While
    ;; class-creation patterns use inheritance effectively in the
    ;; instantiation process, object-creation patterns use delegation
    ;; effectively to get the job done.
    ("Abstract Factory" "Creates an instance of several families of classes" :class creational)
    ("Builder" "Separates object construction from its representation" :class creational)
    ("Lazy initialization" "Tactic of delaying the creation of an object, the calculation of a value, or some other expensive process until the first time it is needed." :class creational)
    ("Factory Method" "Creates an instance of several derived classes" :class creational)
    ("Object Pool" "Avoid expensive acquisition and release of resources by recycling objects that are no longer in use" :class creational)
    ("Prototype" "Specify the kinds of objects to create using a prototypical instance, and create new objects by copying this prototype." :class creational)
    ("Singleton" "Ensure a class has only one instance, and provide a global point of access to it." :class creational)
    ("Multiton" "Ensure a class has only named instances, and provide global point of access to them." :class creational)
    ("Resource acquisition is initialization" "Ensure that resources are properly released by tying them to the lifespan of suitable objects." :class creational)

    ;; Structural: This design patterns is all about
    ;; Class and Object composition. Structural class-creation
    ;; patterns use inheritance to compose interfaces. Structural
    ;; object-patterns define ways to compose objects to obtain new
    ;; functionality.
    ("Adapter or Wrapper" "Match interfaces of different classes" :class structural)
    ("Bridge" "Separates an object’s interface from its implementation" :class structural)
    ("Composite" "A tree structure of simple and composite objects" :class structural)
    ("Decorator" "Add responsibilities to objects dynamically" :class structural)
    ("Facade" "A single class that represents an entire subsystem" :class structural)
    ("Flyweight" "A fine-grained instance used for efficient sharing" :class structural)
    ("Private Class Data" "Restricts accessor/mutator access" :class structural)
    ("Proxy" "An object representing another object" :class structural)

    ;; Behavioral: This design patterns is all about Class's objects
    ;; communication. Behavioral patterns are those patterns that are
    ;; most specifically concerned with communication between objects.
    ("Chain of responsibility" "Avoid coupling the sender of a request to its receiver by giving more than one object a chance to handle the request. Chain the receiving objects and pass the request along the chain until an object handles it.	Yes	No	No" :type behavioral)
    ("Command" "Encapsulate a request as an object, thereby letting you parameterize clients with different requests, queue or log requests, and support undoable operations." :type behavioral)
    ("Interpreter" "Given a language, define a representation for its grammar along with an interpreter that uses the representation to interpret sentences in the language." :type behavioral)
    ("Iterator" "Provide a way to access the elements of an aggregate object sequentially without exposing its underlying representation." :type behavioral)
    ("Mediator" "Define an object that encapsulates how a set of objects interact. Mediator promotes loose coupling by keeping objects from referring to each other explicitly, and it lets you vary their interaction independently." :type behavioral)
    ("Restorer" "An alternative to the existing Memento pattern." :type behavioral)
    ("Memento" "Without violating encapsulation, capture and externalize an object's internal state so that the object can be restored to this state later." :type behavioral)
    ("Null Object" "designed to act as a default value of an object." :type behavioral)
    ("Observer or Publish/subscribe" "Define a one-to-many dependency between objects so that when one object changes state, all its dependents are notified and updated automatically." :type behavioral)
    ("Blackboard" "Generalized observer, which allows multiple readers and writers. Communicates information system-wide.[12]" :type behavioral)
    ("State" "Allow an object to alter its behavior when its internal state changes. The object will appear to change its class." :type behavioral)
    ("Strategy" "Define a family of algorithms, encapsulate each one, and make them interchangeable. Strategy lets the algorithm vary independently from clients that use it." :type behavioral)
    ("Specification" "Recombinable business logic in a boolean fashion" :type behavioral)
    ("Template method" "Define the skeleton of an algorithm in an operation, deferring some steps to subclasses. Template Method lets subclasses redefine certain steps of an algorithm without changing the algorithm's structure." :type behavioral)
    ("Visitor" "Represent an operation to be performed on the elements of an object structure. Visitor lets you define a new operation without changing the classes of the elements on which it operates." :type behavioral)

    ;; Concurrency patterns
    ("Active Object" "The Active Object design pattern decouples method execution from method invocation that reside in their own thread of control. The goal is to introduce concurrency, by using asynchronous method invocation and a scheduler for handling requests." :type concurrency)
    ("Binding Properties" "Combining multiple observers to force properties in different objects to be synchronized or coordinated in some way.[13]" :type concurrency)
    ("Event-Based Asynchronous" "The event-based asynchronous design pattern addresses problems with the Asychronous Pattern that occur in multithreaded programs.[14]" :type concurrency)
    ("Balking" "The Balking pattern is a software design pattern that only executes an action on an object when the object is in a particular state." :type concurrency)
    ("Guarded suspension" "In concurrent programming, guarded suspension is a software design pattern for managing operations that require both a lock to be acquired and a precondition to be satisfied before the operation can be executed." :type concurrency)
    ("Monitor object" "A monitor is an approach to synchronize two or more computer tasks that use a shared resource, usually a hardware device or a set of variables." :type concurrency)
    ("Scheduler" "The scheduler pattern is a concurrency pattern used to explicitly control when threads may execute single-threaded code." :type concurrency)
    ("Thread pool" "In the thread pool pattern in programming, a number of threads are created to perform a number of tasks, which are usually organized in a queue. Typically, there are many more tasks than threads." :type concurrency)
    ("Thread-specific storage" "Thread-local storage (TLS) is a computer programming method that uses static or global memory local to a thread." :type concurrency)
    ("Reactor" "The reactor design pattern is a concurrent programming pattern for handling service requests delivered concurrently to a service handler by one or more inputs. The service handler then demultiplexes the incoming requests and dispatches them synchronously to the associated request handlers." :type concurrency)
    ("Lock" "One thread puts a "lock" on a resource, preventing other threads from accessing or modifying it.[15]" :type concurrency)
    ("Double checked locking" "Double-checked locking is a software design pattern also known as "double-checked locking optimization". The pattern is designed to reduce the overhead of acquiring a lock by first testing the locking criterion (the 'lock hint') in an unsafe manner; only if that succeeds does the actual lock proceed.
    The pattern, when implemented in some language/hardware combinations, can be unsafe. It can therefore sometimes be considered an anti-pattern.
    No" :type concurrency)
    ("Read write lock" "Allows concurrent read access to an object but requires exclusive access for write operations." :type concurrency)

    ("Reader-Follower" "Doc..." :keyword ("threading"))
    ("Thread" "Doc...")
    ("Guard" "Doc...")
    )
  "List of Design Pattern common to all Programming
  Languages. See: http://sourcemaking.com/design_patterns and
  http://en.wikipedia.org/wiki/Design_pattern_(computer_science)")

(defconst c++-stl-ms-mfc-mappings
  '(
    ((:MFC "CArray")
     (:STL "std::vector"))
    ((:MFC "CString")
     (:STL "std::string"))

    ((:MFC "Find")
     (:STL "find"))

    ((:MFC "RemoveAll")
     (:STL "clear"))

    ((:MFC "Remove")
     (:STL "erase"))

    ((:MFC "RemoveAll")
     (:STL "clear"))

    ((:MFC "GetSize")
     (:STL "size"))

    ((:MFC "IsEmpty")
     (:STL "empty"))

    ((:MFC "Add")
     (:STL "push_back"))
    ) "Mappings between C++ Standard Template Library (STL) and Microsoft's MFC")

(defconst relangs-emacs-commands-history
  '(last-command
    this-command
    command-history)
  "Emacs Command History Variables")

(defconst relangs-emacs-hooks
  '(
    ;; Pre/Post Command Call
    pre-command-hook
    post-command-hook

    ;; Buffer Change
    first-change-hook
    after-change-functions
    before-change-functions

    ;; Find (Open) File
    find-file-hook
    find-file-hooks
    find-file-not-found-hooks

    ;; Minibuffer Setup and Exit
    minibuffer-exit-hook
    minibuffer-setup-hook

    ;; Write (Save) File
    auto-save-hook after-save-hook before-save-hook
    write-file-hooks write-file-functions
    local-write-file-hooks

    tramp-handle-file-local-copy-hook
    ) "Emacs Hooks")

(homo-relate 'trace-function
             :related
             'debug-on-entry)

(defun describe-function-related (function)
  (let ((related (get function :related)))
    (when related
      (with-current-buffer (get-buffer "*Help*")
        (let ((buffer-read-only nil)
              (inhibit-changing-match-data t))
          (goto-char (point-max))
          (re-search-backward "\\[back\\]")
          (insert "Related: ")
          ;; FIXME: This doesn't show anything.
          (help-insert-xref-button
           (symbol-name related) 'help-xref)
          (insert "\n\n"))))))

;; TODO: Fix and activate!
(when nil
  (defadvice describe-function (after related (function) compile)
    ;; (describe-function-related function)
    )
  (ad-deactivate 'describe-function))

(require 'case-utils)

(defun relangs-filter (relang-symbol lang-sym)
  "Get pattern from SYMBOL using MODE."
  (let ((lang-sym lang-sym)) ;TODO: Make `lang-sym' optional and get from major-mode
    (delq nil
          (mapcar
           (lambda (entry)
             (let* ((lang (plist-get entry :lang))
                    (hit (cond ((symbolp lang)
                                (memq (downcase-any lang-sym)
                                      (downcase-any lang)))
                               ((listp lang)
                                (memq (downcase-any lang-sym)
                                      (downcase-any lang)))))
                    (expr (or (plist-get entry :expr) ;Handle case when (functionp expr) and query the number of arguments
                              (plist-get entry :regexp))))
               (when hit expr)))
           relang-symbol))))
;; Use: (relangs-filter relangs-binary-number 'Ada)

(defun relangs-try-translate (translation string &optional from-lang to-lang)
  "Try to translate STRING from language FROM-LANG to language TO-LANG using TRANSLATION.
TRANSLATION is eiter a symbol or a list of translations.  If
FROM-LANG is not given guess or ask for it. If TO-LANG is not
given ask for it."
  (let* ((translation (if (symbolp translation)
                          (symbol-value translation)
                        translation))
         (to-lang (or to-lang
                      (let* ((to-langs (delq nil (mapcar (lambda (entry)
                                                           (plist-get entry :lang))
                                                         translation)))
                             (to-default (car to-langs)))
                        (completing-read "To language: " to-langs nil nil nil nil to-default))))
         (to-lang (if (symbolp to-lang)
                      to-lang
                    (intern to-lang)))
         (to-expr (delq nil (mapcar `(lambda (entry)
                                       (let ((lang (plist-get entry :lang)))
                                         (cond ((symbolp lang)
                                                (when (eq ',to-lang lang)
                                                  entry)))
                                         (cond ((list-of-symbols-p lang)
                                                (when (memq ',to-lang lang)
                                                  entry)))))
                                    translation))))
    to-expr))
;; Use: (relangs-try-translate 'relangs-undefined "null")
;; Use: (relangs-try-translate relangs-undefined "null")

(defun translate-buffer (&optional buffer lang)
  "Translate BUFFER to language LANG.
BUFFER defaults to `current-buffer'.
LANG defaults major-mode language, for example `c' if `c-mode' etc."
  (let ((buffer (or buffer (current-buffer))))))

(defconst relangs-range-concept-name
  `((:lang Matlab :expr (: "Sub-" (| "Array"
                                     "Matrix")))
    (:lang D :expr "Range")
    (:lang C++ :expr "Pair of Iterators")
    (:lang Java :expr "InputStream")
    ) "Range Concept Names")

(provide 'relangs)
