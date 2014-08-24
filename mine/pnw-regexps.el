;;; pnw-regexps.el - Various regular expressions

(require 'syntax)
(require 'font-lock)

(defconst _1 "[[:space:]]" "One Whitespaces Character.")
(defconst _? "[[:space:]]?" "Zero or One Whitespace Characters.")
(defconst _* "[[:space:]]*" "Zero or More Whitespaces Characters.")
(defconst _+ "[[:space:]]+" "One or More Whitespace Characters.")

(defconst L1 "[[:space:]\n]" "One Whitespace Character or Newline.")
(defconst L? "[[:space:]\n]?" "Zero or One Whitespace Characters or Newlines.")
(defconst L* "[[:space:]\n]*" "Zero or More Whitespace Characters or Newlines.")
(defconst L+ "[[:space:]\n]+" "One More Whitespaces Characters or Newlines.")

(defconst W1 "[[:word:]]" "One Word Character.")
(defconst W? "[[:word:]]?" "Zero or One Word Characters.")
(defconst W* "[[:word:]]*" "Zero or More Word Characters.")
(defconst W+ "[[:word:]]+" "One or More Word Characters.")

(defconst D1 "[[:digit:]]" "One Decimal Digit.")
(defconst D? "[[:digit:]]?" "One or Zero Decimal Digits.")
(defconst D* "[[:digit:]]*" "Zero or More Decimal Digits.")
(defconst D+ "[[:digit:]]+" "One or More Decimal Digits.")

(defconst Y1 "[[:word:]]" "One Symbol Character.")
(defconst Y? "[[:word:]]?" "Zero or One Symbol Characters.")
(defconst Y* "[[:word:]]*" "Zero or More Symbol Characters.")
(defconst Y+ "[[:word:]]+" "One or More Symbol Characters.")

(defconst W< "\\<" "Beginning of Word.")
(defconst W> "\\>" "End of Word.")
(defconst W1 (concat W< W+ W>) "A Single Word.")

(defconst Y< "\\_<" "Beginning of Symbol.")
(defconst Y> "\\_>" "End of Symbol.")
(defconst Y1 (concat Y< Y+ Y>) "A Single Symbol.")

(defconst BOL "^" "Beginning of Line.")
(defconst EOL "$" "End of Line.")

(defconst B< "\\`" "Beginning of String or Buffer.")
(defconst B> "\\'" "End of String or Buffer.")

(defconst $< "\\(" "Beginning of Group.")
(defconst $> "\\)" "End of Group.")

;; ----------------------------------------------------------------------------

;; File and Path

;; [a-zA-Z_][a-zA-Z0-9_]*

(defconst ascii-name-regexp
  (concat Y<
          "[[:word:]_]"
	  "[[:word:][:digit:]_]*"
          Y>
	  )
  "Regular Expression Matching a C-style identifier.")
(defconst c-id-regexp ascii-name-regexp
  "Regular Expression Matching a C-style identifier.")
(defconst CID c-id-regexp)

(defconst id-regexp
  (concat Y<
	  "[[:alnum:]_]+"
          Y>
	  )
  "Regular Expression Matching an identifier.")
(defconst ID id-regexp)
(defconst ID+ (concat ID "+"))

(defconst ruby-id-regexp
  (concat "\\(?:"
          Y<
          "[[:alpha:]_]"
	  "[[:alnum:]_?!]*"             ;Ruby allows '!' and '?' at the end of an identifier.
          Y>
          $>
	  )
  "Regular Expression Matching a C-style identifier.")
(defconst *RID ruby-id-regexp)

(defconst line-nr-regexp
  (concat "\\(?:"
          "[1-9][[:digit:]]*"
          $>
	  )
  "Regular Expression Matching the line number location in a (source) file.")

(defconst ascii-path-regexp
  (concat "\\(?:" "~?" "/" ascii-name-regexp $>
	  "\\(?:" "/" ascii-name-regexp $> "*"
	  )
  "Regular Expression Matching file path part of URL.")

(defconst c-function-declaration-regexp
  (let ((sym (concat $< c-id-regexp $>)))
    (concat "\\(?:"
            Y< sym ;function name
            _1 "(" _1
            sym ;type name
            "[[:space:]*]" ;zero or more pointer stars along with spaces
            "&?"           ;optional C/C++ reference argumentx operator
            "[[:space:]]"  ;and more space
            sym ;variable name
            $>
            ))
  "Regular Expression Matching a C-style function declaration.")

;; ----------------------------------------------------------------------------

;; Faces

(defface number-hex-face
  '((t (:foreground "Green" :background "Black")))
  "*Face used to highlight a Hexadecimal Integer."
  :group 'pnw-regexps)
(defvar number-hex-face 'number-hex-face)

;; ----------------------------------------------------------------------------

;; Number Literal

(defun number-dec-regexp (&optional mode)
  "Regular Expression Matching a Decimal Integer (positive or negative."
  (concat Y<
	  $< "[+-]?" (if (memq mode '(d-mode ada-mode c++-mode))
                         "[[:digit:]_]"
                       "[[:digit:]]") "+" $>          ;digits (1)
	  Y>))
(eval-when-compile
  (assert-equal 0
                (string-match (number-dec-regexp 'd-mode) "+123_456_7890")))

(defun number-hex-regexp (&optional mode)
  "Regular Expression Matching a Hexadecimal Integer."
  (concat Y<
	  $< "0[xX]" $>              ;prefix (1
	  $< (if (memq mode '(d-mode ada-mode c++-mode))
                 "[[:xdigit:]_]"
               "[[:xdigit:]]") "+" $>  ;digits (2)
	  Y>))
(eval-when-compile
  (assert-equal 0
                (string-match (number-hex-regexp 'd-mode) "0x01234567890_abcdef")))

(defun number-bin-regexp (&optional mode)
  "Regular Expression Matching a C++/D-style Binary Integer."
  (concat Y<
          $< "0[bB]" $>              ;prefix (1
          $< (if (memq mode '(d-mode ada-mode c++-mode))
                 "[01_]"
               "[01]") "+" $>           ;digits (2)
          Y>))
(eval-when-compile
  (assert-equal 0
                (string-match (number-bin-regexp 'd-mode) "0b10_000")))

;; ----------------------------------------------------------------------------

;; C/C++-language Number Literal

(defconst c++11-user-defined-literal-suffix
  (concat "\\(?:" CID "\\)?")
  "Regular Expression matching C++11 User Defined Literal (UDL).")

(defun c-number-dec-regexp (&optional mode)
  "Regular Expression Matching a Decimal Integer."
  (concat Y<
          $< (if (memq mode '(d-mode ada-mode c++-mode))
                 (concat "[[:digit:]]"
                         "[[:digit:]_]+") ;digits (1) with D underscore separators
               "[[:digit:]]+"      ;digits (1)
               )
          $>
          $< "[uU]?" "[lL]" "\\{" "0,2" "\\}" "[uU]?" $> ;unsigned long long (2)
          $< (when (eq mode 'c++-mode)
               c++11-user-defined-literal-suffix) $>
          Y>))

(defun c-number-dec-4to6-regexp (&optional mode)
  "Regular Expression Matching a C Decimal Integer with 4 to 6 digits."
  (concat Y<
	  $< "[[:digit:]]" "\\{" "1,3" "\\}" $> ;1-to-3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[uU]?" "[lL]" "\\{" "0,2" "\\}" "[uU]?" $> ;unsigned long long (2)
          $< (when (eq mode 'c++-mode)
               c++11-user-defined-literal-suffix) $>
               Y>)
  )

(defconst c-number-dec-7to9-regexp
  (concat Y<
	  $< "[[:digit:]]" "\\{" "1,3" "\\}" $> ;1-to-3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[uU]?" "[lL]" "\\{" "0,2" "\\}" "[uU]?" $> ;unsigned long long (2)
	  Y>)
  "Regular Expression Matching a C Decimal Integer with 7 to 9 digits.")

(defconst c-number-dec-10to12-regexp
  (concat Y<
	  $< "[[:digit:]]" "\\{" "1,3" "\\}" $> ;1-to-3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[uU]?" "[lL]" "\\{" "0,2" "\\}" "[uU]?" $> ;unsigned long long (2)
	  Y>)
  "Regular Expression Matching a C Decimal Integer with 10 to 12 digits.")

(defconst c-number-dec-13to15-regexp
  (concat Y<
	  $< "[[:digit:]]" "\\{" "1,3" "\\}" $> ;1-to-3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[uU]?" "[lL]" "\\{" "0,2" "\\}" "[uU]?" $> ;unsigned long long (2)
	  Y>)
  "Regular Expression Matching a C Decimal Integer with 13 to 15 digits.")

(defconst c-number-dec-16to18-regexp
  (concat Y<
	  $< "[[:digit:]]" "\\{" "1,3" "\\}" $> ;1-to-3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[uU]?" "[lL]" "\\{" "0,2" "\\}" "[uU]?" $> ;unsigned long long (2)
	  Y>)
  "Regular Expression Matching a C Decimal Integer with 16 to 18 digits.")

(defconst c-number-dec-19to21-regexp
  (concat Y<
	  $< "[[:digit:]]" "\\{" "1,3" "\\}" $> ;1-to-3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[[:digit:]]" "\\{"   "3" "\\}" $>	;3-digit group
	  $< "[uU]?" "[lL]" "\\{" "0,2" "\\}" "[uU]?" $> ;unsigned long long (2)
	  Y>)
  "Regular Expression Matching a C Decimal Integer with 19 to 21 digits.")

;; ----------------------------------------------------------------------------

;; C-language Number HexaDecimal Literal

(defun c-number-hex-regexp (&optional mode)
  "Regular Expression Matching a C/C++/D Hexadecimal Integer."
  (concat Y<
	  $< "0[xX]" $>             ;prefix (1)
	  $< (if (memq mode '(d-mode ada-mode))
                 "[[:xdigit:]_]"
               "[[:xdigit:]]")
          "\\{" "1,16" "\\}" $>                          ;digits (2)
	  $< "[UI]?" "[lL]" "\\{" "0,2" "\\}" "[uU]?" $> ;unsigned long long (3)
          $< (when (eq mode 'c++-mode)
               c++11-user-defined-literal-suffix) $>
	  Y>))

(defun c-number-hex-fancy-regexp (&optional mode)
  "Regular Expression Matching a C Fancy Hexadecimal Integer."
  (let ((xdigit (if (memq mode '(d-mode ada-mode))
                    "[[:xdigit:]_]"
                  "[[:xdigit:]]")))
    (concat Y<
            $< "0[xX]" $>		;prefix (1)
            $< xdigit "\\{1,2\\}?" $>
            $< xdigit "\\{1,2\\}?" $>
            $< xdigit "\\{1,2\\}?" $>
            $< xdigit "\\{1,2\\}?" $>
            $< xdigit "\\{1,2\\}?" $>
            $< xdigit "\\{1,2\\}?" $>
            $< xdigit "\\{1,2\\}?" $>
            $< xdigit "\\{1,2\\}?" $>
            $< "[UI]?" "[lL]" "\\{" "0,2" "\\}" "[uU]?" $> ;unsigned long long (10)
            Y>
            )))

;; ----------------------------------------------------------------------------

(defconst std-untyped-number-float-regexp
  (concat $<
          "[\\+-]?"
	  "\\(?:"
	  "\\(?:" "[[:digit:]]+" "\\(?:" "\\." "[[:digit:]]*" "\\)?" $>
	  "\\|"
	  "\\(?:" "[[:digit:]]*" "\\(?:" "\\." "[[:digit:]]+" $> $>
	  $>
	  "\\(?:" "[eE]" "[\\+-]?" "[[:digit:]]+" "\\)?"
          $>)
  "Regular Expression Matching a Standard Untyped Floating Point Literal.")

(defconst emacs-lisp-number-float-regexp
  (concat Y<
          std-untyped-number-float-regexp
          Y>)
  "Regular Expression Matching a Emacs Lisp Floating Point Literal.")

(defun c-number-float-regexp (&optional mode)
  "Regular Expression Matching a C Typed Floating Point Literal."
  (concat Y<
          std-untyped-number-float-regexp
          $< "[dDfFlL]?" $>             ;precision (2)
          $< (when (eq mode 'c++-mode)
               c++11-user-defined-literal-suffix) $>
          Y>))

(defconst haskell-number-float-regexp
  (concat Y<
          $<
	  "[\\+-]?"
	  "\\(?:" "[[:digit:]]+" "\\(?:" "\\." "[[:digit:]]*" "\\)?" $>
	  "\\(?:" "[eE]" "[\\+-]?" "[[:digit:]]+" "\\)?"
	  $>
	  Y>)
  "Regular Expression Matching a Haskell Floating Point Literal.")

;; ----------------------------------------------------------------------------

(defconst emacs-lisp-number-bin-regexp
  (concat "\\(?:"
          $< "#[bB]" $>		;prefix (1)
          $< "[01]+" $>   ;digits (2)
          Y>
          $>)
  "Regular Expression Matching an Emacs Lisp Binary Integer.")

(defconst emacs-lisp-number-oct-regexp
  (concat "\\(?:"
          $< "#[oO]" $>		;prefix (1)
	  $< "[07]+" $>           ;digits (2)
          Y>
          $>)
  "Regular Expression Matching an Emacs Lisp Octal Integer.")

(defconst emacs-lisp-number-dec-regexp
  (concat "\\(?:"
          $< $>                   ;empty prefix (1). Important: Must have matcher here to make its match-format same other number matchers!
          $< "[09]+" $>           ;digits (2)
          Y>
          $>)
  "Regular Expression Matching an Emacs Lisp Binary Integer.")

(defconst emacs-lisp-number-hex-regexp
  (concat "\\(?:"
          $< "#[xX]" $>		;prefix (1)
	  $< "[[:xdigit:]]+" $>	;digits (2)
          Y>
          $>)
  "Regular Expression Matching an Emacs Lisp Hexadecimal Integer.")

;; ----------------------------------------------------------------------------

;; Phone Numbers

(defface swedish-phone-number-face
  '((t (:foreground "PaleGoldenrod" :background "MidnightBlue")))
  "*Face used to highlight a swedish phone number."
  :group 'pnw-regexps)
(defvar swedish-phone-number-face 'swedish-phone-number-face)

(defconst swedish-phone-number-regexp
  (concat "[[:digit:]]" "\\{" "2,4" "\\}"	;area number (1)
	  "-"				;separator (2)
	  "[[:digit:]]" "\\{" "5,8" "\\}"	;local number (3)
	  )
  "Regular Expression Matching a swedish phone number.")

(defconst foi-phone-number-regexp
  (concat "013"
	  "-"
	  "37"
	  "[[:digit:]]" "\\{" "4" "\\}"
	  )
  "Regular Expression Matching a phone number at FOI Linköping.")

;; ----------------------------------------------------------------------------

;; Date

(defconst swedish-date-regexp
  (concat "[[:digit:]]" "\\{" "2,4" "\\}"
	  "-"
	  "[[:digit:]]" "\\{" "2" "\\}"
	  "-"
	  "[[:digit:]]" "\\{" "2" "\\}"
	  )
  "Regular Expression Matching a swedish date.")

;; ----------------------------------------------------------------------------

;; Time

(defconst swedish-time-regexp
  (concat "[0-2][[:digit:]]"
	  ":" "[0-5][[:digit:]]"
	  "\\(?:" ":[[:digit:]][[:digit:]]" $> "?"
	  )
  "Regular Expression Matching a swedish time.")

;; ----------------------------------------------------------------------------

;; Room Number

(defconst foi-room-number-regexp
  (concat "[A-Z][[:digit:]]"
	  "\\."
	  "[[:digit:]]" "\\{" "3" "\\}"
	  )
  "Regular Expression Matching a room number at FOI Linköping.")

;; ----------------------------------------------------------------------------

;; Numbers

(defconst dec-1-to-3-regexp
  (concat "[[:digit:]]" "\\{" "1,3" "\\}"
	  )
  "Regular Expression Matching 1 to 3 decimal digits.")

(defconst dec-u8-regexp
  (concat "\\(?:"
	  "\\(?:" "[[:digit:]]" $> "\\|"
	  "\\(?:" "[1-9]" "[[:digit:]]" $> "\\|"
	  "\\(?:" "[1]"   "[[:digit:]]" "[[:digit:]]" $> "\\|"
	  "\\(?:" "[2]"   "[0-4]" "[[:digit:]]" $> "\\|"
	  "\\(?:" "[2]"   "[5]"   "[0-5]" $>
	  $>
	  )
  "Regular Expression Matching a decimal unsigned 8-bit char [0...255].")

;; ----------------------------------------------------------------------------

;; URLs

(defconst url-protocol-regexp
  (concat "\\(?:"
	  "file" "\\|"
	  "s?ftp" "\\|"
	  "s?http"
	  $>
	  "://"
	  )
  "Regular Expression Matching protocol prefix of URL.")

(defconst url-hostname-regexp
  (concat "[\\sw-]+"			;first part
	  "\\(?:" "\\." "[\\sw-]+" $> "+" ;resting parts
	  )
  "Regular Expression Matching hostname part of URL.")

(defconst url-port-regexp
  (concat "\\(?:" ":[[:digit:]]" "\\{" "1,5" "\\}" $> "?"
	  )
  "Regular Expression Matching port specification part of URL.")

(defconst url-path-regexp
  (concat "\\(?:" "/" "~?" "[\\sw-]+" $>
	  "\\(?:" "/" "[\\sw-]+" $> "*"
	  )
  "Regular Expression Matching file path part of URL.")

(defconst url-regexp
  (concat url-protocol-regexp
	  url-hostname-regexp
	  url-port-regexp
	  "\\(?:" url-path-regexp "\\)?"
	  )
  "Regular Expression Matching URLs.")

;; ----------------------------------------------------------------------------

;; Emails

(defconst email-name-regexp
  (concat "[[:alnum:]_.-]+"
	  )
  "Regular Expression Matching the name part of an email.")

(defconst email-regexp
  (concat email-name-regexp
	  "@"
	  "[[:alnum:]_.-]+"
	  )
  "Regular Expression Matching emails.")

(defconst foi-email-regexp
  (concat email-name-regexp
	  "@foi.se"
	  )
  "Regular Expression Matching a FOI email.")

;; ----------------------------------------------------------------------------

;; Commands and Programs

(defconst sh-builtin-list
  (list "echo" "set" "setenv" "export")
  "Names of builtin commands in common UNIX shells.")
(defconst sh-builtin-regexp
  (concat "\\<\\(" (mapconcat 'identity sh-builtin-list "\\.") "\\)\\>")
  "Regular Expression Matching builtin commands in common UNIX shells.")

;; ----------------------------------------------------------------------------

;; Common UNIX Programs

;; TODO: Replace with by scanning `exec-path' and add results to a file-name
;; hash-table. Already exists?
(defconst unix-programs-list
  (list "ls" "cp" "rm" "mv"
	"cat" "zcat"
	"zip" "unzip"
	"gzip" "gunzip"
	"bzip2" "bunzip2"
	"grep"
	"modprobe" "lsmod" "inmod" "rmmod"
	"awk" "gawk" "sed"
	"df" "du" "hdparm"
	"passwd" "su" "id"
	"mkfs" "mke2fs" "mkreiserfs"
	"sshd" "crond"			;daemons
	"gcc" "g++" "pkgadd"
	"configure")
  "Names of common Linux programs.")
(defconst unix-programs-regexp
  (concat "\\<\\(" (mapconcat 'identity unix-programs-list "\\.") "\\)\\>")
  "Regular Expression Matching common Linux programs.")

;; ----------------------------------------------------------------------------
;; File System Types

;; (pnw-install-file "pnw-regexps.el")
(defconst fs-types-list
  (list "ext2" "ext3" "reiserfs"
	"swap" "xfs" "vfat" "minix" "cramfs" "bfs" "jfs")
  "Names of common UNIX file systems.")
(defconst fs-types-regexp
  (concat "\\<\\(" (mapconcat 'identity fs-types-list "\\.") "\\)\\>")
  "Regular Expression Matching common UNIX file systems.")

;; ----------------------------------------------------------------------------
;; Shell Commands

(defconst sh-cmd-regexp
  (concat BOL _* "[\\$#] .*$")
  "Regular Expression Matching a shell command line interface (CLI) call.")

;; ----------------------------------------------------------------------------
;; Valgrind

(defconst valgrind-process-nr-regexp
  (concat "^==\\([[:digit:]]+\\)== "
	  )
  "Regular Expression Matching process number part of a Valgrind line prefix.")

;; ----------------------------------------------------------------------------
;; Web-related

(defconst pnw-font-lock-extra-list
  (list
   (list (concat
	  "\\(?:" "[^0-9a-fA-F]" "\\|" BOL $>
	  $<
	  (number-hex-regexp)
	  $>)
	 1 font-lock-constant-face)
   (list foi-phone-number-regexp
	 0 font-lock-builtin-face)
   (list swedish-phone-number-regexp
	 0 swedish-phone-number-face)
   (list swedish-date-regexp
	 0 font-lock-constant-face)
   (list swedish-time-regexp
	 0 font-lock-constant-face)
   (list foi-room-number-regexp
	 0 font-lock-constant-face)
   ;; IP Literals
   (list (concat
	  ;;"[^0-9.]"
	  "\\<\\("
	  (mapconcat 'identity (make-list 4 dec-u8-regexp) "\\.") ;IPv4 quads
	  "\\|"
	  (mapconcat 'identity (make-list 16 dec-u8-regexp) "\\.") ;IPv6
	  "\\)\\>"
	  ;;"[^0-9.]"
	  )
	 1 font-lock-constant-face)
   ;; Shell Commands
   (list sh-cmd-regexp
	 '(0 font-lock-warning-face))
   ;; Shell Builtins
   (list sh-builtin-regexp
	 0 font-lock-builtin-face)
   ;; Shell Programs
   (list unix-programs-regexp
	 0 font-lock-function-name-face)
   ;; File Systems
   (list fs-types-regexp
	 0 font-lock-constant-face)
   ;; Alone Paths
   (list (concat
	  $<
	  ascii-path-regexp
	  $>
	  )
	 1 font-lock-constant-face)
   ;; Valgrind address and source function
   (list (concat
	  $< (number-hex-regexp) $>
	  ": "
	  $< ascii-name-regexp $>
	  )
	 '(1 number-hex-face)
	 '(2 font-lock-function-name-face)
	 )
   ;; Valgrind process number
   (list (concat
	  valgrind-process-nr-regexp
	  )
	 1 font-lock-builtin-face)
   ;; Valgrind Name and Line
   (list (concat "("
		 $< ascii-name-regexp $>
		 ":"
		 $< line-nr-regexp $>
		 ")$"
		 )
	 '(1 font-lock-warning-face)
	 '(2 font-lock-variable-name-face)
	 )
   ;; URL starts
   (list (concat
	  "[^0-9.]"
	  $<
	  url-regexp
	  $>
	  )
	 1 font-lock-variable-name-face)
   ;; Emails
   (list email-regexp
	 0 font-lock-variable-name-face)
   )
  "Extra expressions to font-lock in Text mode(s).")

(defconst pnw-font-lock-extra
  (progn
    (require 'font-lock)
    pnw-font-lock-extra-list)
  "Extra expressions to font-lock in Text mode(s).")

;; ----------------------------------------------------------------------------

(defun regexp-beginning-of-ascii-word (regexp)
  "Construct a pattern matching REGEXP at the beginning of a ASCII-word."
  (concat "[" regexp "]" $< "[[:lower:]]" $>))

(defun regexp-inside-or-end-of-ascii-word (regexp)
  "Construct a pattern matching REGEXP inside or at the end of a ASCII-word."
  (concat $< "[a-zA-Z]" $> "[" regexp "]"))

;; ----------------------------------------------------------------------------

(defvar emacs-lisp-char-class-list
  '("ascii" "alnum" "alpha" "blank" "cntrl"
    "digit" "graph" "lower" "multibyte"
    "nonascii" "print" "punct" "space" "unibyte"
    "upper" "word" "xdigit")
  "List Emacs Lisp Character Classes."
  )

(defconst emacs-lisp-let-forms-list
  '("let"
    "let*"
    "letf"
    "letf*"
    "lexical-let"
    "lexical-let*")
  "List of let-like expressions.")

(defconst emacs-lisp-defs-list
  '("defun" "defun*"
    "defmacro" "defmacro*"
    "defsubst" "defsubst*"
    "define-overloadable-function")
  "Emacs Lisp Definition Forms.")

;; ----------------------------------------------------------------------------

(provide 'pnw-regexps)

;; pnw-regexps ends here
