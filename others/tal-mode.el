;;; tal-mode.el --- Handles the Tandem-Compaq-HP TAL & pTAL languages.

;; Copyright (C) 2001 Free Software Foundation, Inc.

;; Author: Rick Bielawski <rbielaws@i1.net>
;; Keywords: languages, extensions, Tandem, Compaq, HP, TAL, pTAL

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; TAL is Tandem's Transaction Application Language.
;; pTAL is the newer 'portable' version of the language.

;; Keywords as of G06.05 are recognized by this version of tal-mode.
;; TAL words not supported in pTAL are highlighted with a warning face.
;; imenu recognizes ?section <name>, ?page <name> and <type> PROC <name>.
;; Both ! and -- style comments are handled correctly (I think).
;; Movement by balanced expressions is supported.  That is, begin/end pairs
;;   are recognized.  However paren-mode and blink-matching-paren cannot
;;   recognize begin/end pairs due to limitations/bugs.  See PAREN-MODE FIX
;;   below.
;;
  
;;; ToDo:
  
;; Custom indentation support has not been created yet.  This is a big todo!
;; There are no abbrevs defined. 
;; Movement by statements, functions etc should be supported.
;; Unterminated strings are currently terminated by EOL.  This makes viewing
;;   mangled code easier but finding unterminated strings harder.  Eventually
;;   I'd like to toggle this on/off.
;; Fix tal-keyword-on-directive-line-regexp code to use the anchor feature
;; imenu doesn't suport -- int proc mas_op_cde_buf_parse( ptr,
;;                                                        op_tbl_entry );
;;       and it incorrectly assumes proc x; is a fcn when it could be a ptr.


;;; Installing:
  
;; There are 4 ways to edit a file using TAL-MODE.  The first method manually
;; selects tal-mode as the editing mode.  The other 3 cause emacs to recognize
;; automatically that you want to visit the file using tal-mode.
;;
;; Pick one:
;; 1. While visiting the target file, type: M-x tal-mode
;; 2. Put the string -*-tal-*- in a comment on the first line of the file.
;; 3. Create an association between a particular file naming convention and
;;    tal-mode.  This is done by adding an association to auto-mode-alist.
;; For example:
;; (setq auto-mode-alist
;;   (append
;;     '(("\\.tal\\'" . tal-mode)         ;extension of .tal means tal-mode
;;       ("\\([\\/]\\|^\\)[^.]+$" . tal-mode)) ;so does no extension at all.
;;    auto-mode-alist))
;; 4. See RECOGNIZING LANGUAGE WITHOUT FILE EXTENSIONS below.
;;
;; The above all tell emacs that you want to use tal-mode but you must load
;; tal-mode before you can use it.  There are 2 methods of telling emacs how
;; to load the tal-mode definitions.  The first unconditionally loads tal-mode
;; definitions immediately.  The second tells emacs to load tal-mode the first
;; time a request to use it is made.  Add one of the following lines to your
;; .emacs file.
;;
;;(require 'tal-mode)      ; Unconditional load
;;(autoload 'tal-mode "tal-mode" "Major mode for Tandem TAL/pTAL files." t nil)
;;
;; Either way you choose to load tal-mode, emacs needs to be able to find it.
;; Place the tal-mode.el file in a directory on the load-path; typically the
;; `.../site-lisp' directory.  Typically you would also want to byte compile
;; tal-mode.el but this is not required.  There should be no warnings or
;; errors during byte compilation.
  
;;; RECOGNIZING LANGUAGE WITHOUT FILE EXTENSIONS
  
;;  Since Guardian/Tandem/NSK... doesn't support extensions I use the
;;  following code in my .emacs to recognize the language and set the proper
;;  mode.  This only handles the cases I run into most often but it's a good
;;  start and example of how you can support files you edit often and can't
;;  handle by putting -*-tal-*- in a comment on the first line.
;;
;;  (defadvice set-auto-mode
;;    (after my-determine-language last () activate)
;;    "When language is fundamental-mode. DDL, TAL, TACL & ACIMAKE modes are
;;     recognized if the standard ACI version line is present.  Some other
;;     'first line indicators' are also recognized too."
;;    (if (eq major-mode 'fundamental-mode)
;;        (let ((mode nil))
;;          (save-excursion  ; in case set-auto-mode is run interactively
;;            (goto-char (point-min))
;;            (if (looking-at "\\(\\*\\|!\\|#\\|{\\)\\*\\(SYNC\\|FIX2\\|SEQ2\\)\\.")
;;                (progn
;;                  (goto-char (min (1- (point-max)) (+ (point) 34)))
;;                  (cond ((looking-at "DDL ")
;;                         (setq mode 'ddl-mode))
;;                        ((looking-at "TAL ")
;;                         (setq mode 'tal-mode))
;;                        ((looking-at "COBOL ")
;;                         (setq mode 'ddl-mode)) ;its better than nothing:-(
;;                        ((looking-at "SCOBOL ")
;;                         (setq mode 'ddl-mode)) ;its better than nothing:-(
;;                        ((looking-at "TACL ")
;;                         (setq mode 'tacl-mode))
;;                        ((looking-at "MAKE ")
;;                         (setq mode 'acimake-mode))))
;;              (if (looking-at "\\(\\?TACL\\|==\\)")
;;                  (setq mode 'tacl-mode)
;;                (if (looking-at "#[-*#=]")
;;                    (setq mode 'acimake-mode)
;;                  (if (looking-at "! SCHEMA")
;;                      (setq mode 'ddl-mode))))))
;;          (if mode (funcall mode))))
;;  )
  
  
;;; History:
  
;; 2004-05-26 RGB Mode is finally useable enough to start tracking.
;; 2004-06-02 RGB Prettied up some comments and code sections.
;;                Fixed minor bug turning on imenu & which-function.
;; 2004-06-17 RGB Lots of updates to documentation and comments.
;;                Added customization of tal-primecode-warning
;;                Changed how comments & strings are detected by font-lock
;;                so that more things work more smoothly (hopefully).
;;                Added/fixed adaptive-fill support.
;; 2004-08-12 RGB Finally broke down and fixed the comment/string handling the
;;                way it really should have been done in the first place.
;;                Tweaked the imenu regexp to eliminate leading whitespace
;;                in ?page "        heading strings".
;; 2004-08-25 RGB Column markers are now dynamically configurable.
  
;;; Code:
  
(defgroup tal nil
  "Major mode for editing Tandem TAL/pTAL source files in Emacs.
While in tal-mode use C-h m for a description of the mode's features."
  :prefix 'tal-
  :group 'languages
) 
  
;;; KEY MAP
  
(defvar tal-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Personally, I like this to work within all major modes
    (define-key map [?\C-j] 'eval-print-last-sexp)
    ;; not many custom definitions yet
    (define-key map [?\C-c ?\C-f] 'auto-fill-mode)
    (define-key map [?\C-c ?\C-e] 'tal-if-else-skel)
    (define-key map [?\C-c ?\C-i] 'tal-if-skel)
    (define-key map [?\C-c ?\C-c] 'tal-case-skel)
    map)
  "Keymap for `tal-mode'."
) 
  
(defvar tal-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\n ">" st)
    (modify-syntax-entry ?\! "'" st)
    (modify-syntax-entry ?\" "'" st)
    (modify-syntax-entry ?\$ "'" st)
    (modify-syntax-entry ?\% "'" st)
    (modify-syntax-entry ?\& "." st)
    (modify-syntax-entry ?\' "." st)
    (modify-syntax-entry ?\( "()" st)
    (modify-syntax-entry ?\) ")(" st)
    (modify-syntax-entry ?\* "." st)
    (modify-syntax-entry ?\+ "." st)
    (modify-syntax-entry ?\, "." st)
    (modify-syntax-entry ?\- "." st)
    (modify-syntax-entry ?\. "'" st)
    (modify-syntax-entry ?\/ "." st)
    (modify-syntax-entry ?\: "'" st)
    (modify-syntax-entry ?\; "." st)
    (modify-syntax-entry ?\< "." st)
    (modify-syntax-entry ?\= "." st)
    (modify-syntax-entry ?\> "." st)
    (modify-syntax-entry ?\? "'" st)
    (modify-syntax-entry ?\@ "'" st)
    (modify-syntax-entry ?\[ "(]" st)
    (modify-syntax-entry ?\\ "'" st)
    (modify-syntax-entry ?\] ")[" st)
    (modify-syntax-entry ?^  "w" st)
    (modify-syntax-entry ?\_ "w" st)
    (modify-syntax-entry ?\{ "." st)
    (modify-syntax-entry ?\| "." st)
    (modify-syntax-entry ?\} "." st)
    st)
  "Syntax table for `tal-mode'."
) 
  
;; All keyword lists get sorted so new words can be anywhere within the
;; appropriate list.  The keywords are currently only used for highlighting but
;; more uses such as abbrev-mode are in progress.
  
(defvar tal-keywords-unqualified-data-types
  '( "string" )
  "A list of keywords that denote an unqualified data type.  Used to create
the `font-lock-keywords' table.  Unqualified data types are data types which
do not accept a size qualifier such as int(16), unsigned(32) etc.  See also
`tal-keywords-qualified-data-types'."
) 
(defvar tal-keywords-qualified-data-types
  '( "int" "unsigned" "fixed" "real" )
  "A list of keywords that denote data types which can be qualified.  Used to
create the `font-lock-keywords' table.  Qualified data types are data types
that accept a size qualifier such as int(16), unsigned(32) etc.  See also
`tal-keywords-unqualified-data-types'."
) 
(defvar tal-keywords-address-types
  '( ".ext"     ".sg"      "baddr"    "cbaddr"   "cwaddr"   "extaddr"
     "procaddr" "sgbaddr"  "sgwaddr"  "sgxbaddr" "sgxwaddr" "struct"
     "waddr"
  )
  "List of TAL/pTAL variable types.
   Used to create the `font-lock-keywords' table."
) 
(defvar tal-keywords-directives
  '( "abort"                "abslist"              "assertion"
     "begincompilation"     "blockglobals"         "checkshiftcount"
     "code"                 "columns"              "decs"
     "defexpand"            "definetog"            "do-tns-syntax"
     "dumpcons"             "else"                 "endif"
     "errorfile"            "errors"               "export_globals"
     "extendtalheap"        "fieldalign"           "fmap"
     "gmap"                 "gp_ok"                "highpin"
     "highrequesters"       "icode"                "if"
     "ifnot"                "innerlist"            "inspect"
     "int32index"           "invalid-for-ptal"     "library"
     "lines"                "list"                 "map"
     "noabort"              "noabslist"            "nocode"
     "nodefexpand"          "nofmap"               "nogmap"
     "noinnerlist"          "nolist"               "nomap"
     "nooverflow_traps"     "noprintsym"           "noround"
     "nosuppress"           "nosymbols"            "nowarn"
     "optimize"             "optimizefile"         "overflow_traps"
     "page"                 "pep"                  "popcode"
     "popdefexpand"         "popinnerlist"         "poplist"
     "popmap"               "printsym"             "pushcode"
     "pushdefexpand"        "pushinnerlist"        "pushlist"
     "pushmap"              "refaligned"           "resettog"
     "round"                "rp"                   "saveabend"
     "saveabend"            "saveglobals"          "section"
     "settog"               "source"               "srl"
     "suppress"             "symbolpages"          "symbols"
     "syntax"               "target"               "useglobals"
     "warn"
  )
  "List of TAL/pTAL compiler directives.
   Used to create the `font-lock-keywords' table."
) 
(defvar tal-keywords-statements
  '( "and"         "assert"      "baddr"       "begin"       "by"
     "call"        "callable"    "case"        "cbaddr"      "cwaddr"
     "define"      "do"          "downto"      "drop"        "else"
     "end"         "entry"       "extaddr"     "external"    "fieldalign"
     "for"         "forward"     "goto"        "if"          "interrupt"
     "label"       "land"        "literal"     "lor"         "main"
     "not"         "of"          "or"          "otherwise"   "priv"
     "proc"        "procaddr"    "procptr"     "refaligned"  "resident"
     "return"      "rscan"       "scan"        "sgbaddr"     "sgwaddr"
     "sgxbaddr"    "sgxwaddr"    "subproc"     "then"        "to"
     "until"       "use"         "variable"    "volatile"    "waddr"
     "while"       "xor"
  )
  "List of TAL/pTAL statement keywords.
   Used to create the `font-lock-keywords' table."
) 
(defvar tal-keywords-deprecated
  '( "$axadr"      "$carry"      "$ladr"       "$overflow"   "'g'"
     "'l'"         "'s'"         "code"        "stack"       "store"
   )
  "List of TAL keywords and Builtin functions now deprecated.
   Used to create the `font-lock-keywords' table"
) 
(defvar tal-keywords-nonreserved
  '( "'p'"         "'sg'"        "at"          "below"       "bit_filler"
     "block"       "bytes"       "elements"    "filler"      "private"
     "words"
;;   "auto"        "c"           "cobol"       "ext"         "extensible"
;;   "fortran"     "language"    "name"        "nodefault"   "pascal"
;;   "returncc"    "shared2"     "shared8"     "unspecified"
   )
  "List of TAL keywords reserved only in certain language contexts.
   Used to create the `font-lock-keywords' table."
) 
(defvar tal-keywords-std-fcns
  '( "$abs"                 "$alpha"               "$baddr_to_extaddr"
     "$baddr_to_waddr"      "$bitlength"           "$bitoffset"
     "$comp"                "$dbl"                 "$dbll"
     "$dblr"                "$dfix"                "$eflt"
     "$efltr"               "$extaddr"             "$extaddr_to_baddr"
     "$extaddr_to_waddr"    "$fill16"              "$fill32"
     "$fill8"               "$fix"                 "$fixd"
     "$fixi"                "$fixl"                "$fixr"
     "$flt"                 "$fltr"                "$high"
     "$ifix"                "$int"                 "$int_ov"
     "$intr"                "$len"                 "$lfix"
     "$lmax"                "$lmin"                "$max"
     "$min"                 "$numeric"             "$occurs"
     "$offset"              "$optional"            "$param"
     "$point"               "$readclock"           "$rp"
     "$scale"               "$sgbaddr_to_extaddr"  "$sgbaddr_to_sgwaddr"
     "$sgwaddr_to_extaddr"  "$sgwaddr_to_sgbaddr"  "$special"
     "$stack_allocate"      "$type"                "$udbl"
     "$usercode"            "$xadr"
   )
  "List of TAL standard functions.
   Used to create the `font-lock-keywords' table."
) 
(defvar tal-keywords-privileged
  '( "$executeio"           "$freeze"              "$halt"
     "$interrogatehio"      "$interrogateio"       "$locatespthdr"
     "$lockpage"            "$readbaselimit"       "$readspt"
     "$unlockpage"          "$writepte"
   )
  "List of TAL privileged functions.
   Used to create the `font-lock-keywords' table."
) 
(defvar tal-keywords-builtin
  '( "$asciitofixed"        "$atomic_add"          "$atomic_and"
     "$atomic_dep"          "$atomic_get"          "$atomic_or"
     "$atomic_put"          "$checksum"            "$countdups"
     "$exchange"            "$executeio"           "$fixedtoascii"
     "$fixedtosciiresidue"  "$moveandcxsumbytes"   "$movenondup"
     "$readtime"            "$udivrem16"           "$udivrem32"
   )
  "List of TAL privileged builtin functions.
   Used to create the `font-lock-keywords' table."
) 
(defvar tal-keyword-fcn-names-regexp
  "^\\s-*\\(?:\\w+\\(?:\\s-*(\\w+)\\)?\\s-+\\)??\\(?:proc\\|subproc\\)\\s-+\\(\\w+\\)\\b"
  "Defines a regexp that finds the names of procedures & subprocedures.
   Used to create the `font-lock-keywords' table."  )
  
;;; Font lock (highlighting)
  
(defcustom tal-font-lock-always t
  "If non-nil, TAL-MODE will always turn `font-lock-mode' on even if
`global-font-lock-mode' is off.  nil disables this feature."
  :type 'boolean
  :group 'tal
) 
(defvar tal-column-marker-face 'tal-column-marker-face)
(defface tal-column-marker-face
  '((t (:background "grey")))
  "Used for marking column 79 or whatever column is pointed to by
`tal-column-marker-1' & `tal-column-marker-2'"
  :group 'tal
  :group 'faces
) 
(defcustom tal-column-marker-1 0
  "*When not zero, this column is font-lock'ed to tal-column-marker-face.
Setting this to zero turns off the column marker.  This column
marker is useful for columnizing things or when working in
languages like COBOL where a particular column has significance.
Use `C-u <column> \\[tal-column-marker-1]' while in a tal-mode
buffer to change the column marker interactively in that buffer
only.  This customize option sets the default for tal-mode."
  :type 'integer
  :group 'tal
) 
(defun tal-column-marker-1 (column)
  "Set the column marker interactively for the current tal-mode buffer.
Max value allowed is 132.  0 turns off the marker.  Set the default
with `M-x customize-option RET tal-column-marker-1 RET'. For this buffer
only, specify the column with `C-u <column> \\[tal-column-marker-1]' or
`\\[tal-column-marker-1] RET <column> RET'."
  (interactive "NMarker Column: ")
  (if (not(equal major-mode 'tal-mode))
      (error "Current buffer must be tal-mode")
    (if (< column 0)(setq column 0))
    (if (> column 132)(setq column 132))
    (let ((tal-column-marker-1 column))
      ;; now, to make it take effect immediately I turn off font-lock, make
      ;; font-lock think it has not been on in this buffer previously, then
      ;; re-do our normal font-lock initialization which typically turns it
      ;; back on.  Only this time the new config in place.
      (font-lock-mode -1)
      (setq font-lock-set-defaults nil)
      (tal-setup-font-lock)
    )
  )
)
(defcustom tal-column-marker-2 79
  "*When not zero, this column is font-lock'ed to tal-column-marker-face.
Setting this to zero turns off the column marker.  This column marker is
useful for columnizing things or when working in languages like COBOL where a
particular column has significance.  Use `\\[tal-column-marker-2]' RET num
while in a tal-mode buffer to change the column marker interactively in
that buffer only.  This customize option sets the default for tal-mode."
  :type 'integer
  :group 'tal
) 
(defun tal-column-marker-2 (column)
  "Set the column marker interactively for the current tal-mode buffer.
Max value allowed is 132.  0 turns off the marker.  Set the default
with `M-x customize-option RET tal-column-marker-2 RET'. For this buffer
only, specify the column with `C-u <column> \\[tal-column-marker-2]' or
`\\[tal-column-marker-2] RET <column> RET'."
  (interactive "NMarker Column: ")
  (if (not(equal major-mode 'tal-mode))
      (error "Current buffer must be tal-mode")
    (if (< column 0)(setq column 0))
    (if (> column 132)(setq column 132))
    (let ((tal-column-marker-2 column))
      ;; now to make it take effect immediately I turn off font-lock, make
      ;; font-lock think it has not been on in this buffer previously, then
      ;; re-do our normal font-lock initialization which typically turns it
      ;; back on.  Only this time the new config in place.
      (font-lock-mode -1)
      (setq font-lock-set-defaults nil)
      (tal-setup-font-lock)
    )
  )
)
(defcustom tal-primecode-warning t
  "When not nil, instances of ]a ]d and ]e appearing in column 1-2 are
highlighted with a warning face.  This alerts you that submission of this file
to RMS/PrimeCode will fail due to invalid contents."
  :type 'boolean
  :group 'tal
) 
(defun tal-keyword-anywhere-regexp ( word-list )
  "Returns a regexp that finds any of the words in the list passed.  But only
if the keyword is surrounded by non-word chars."
  (concat "\\<"(regexp-opt word-list t)"\\>")
) 
(defun tal-keyword-qualified-regexp ( word-list )
  "Returns a regexp that finds any of the words in the list passed but only if
the keyword is preceeded by a non-word char and optionally followed by a
'(width|fpoint)' qualifier and ends with a non-word char."
  (concat "\\<\\("(regexp-opt word-list)"\\(?:\\s-*(\\w+)\\)?\\)\\>")
) 
  
;; The next 4 def's work tightly together and, as coded, cannot be reused for
;; additional purposes.
(defvar tal-keyword-on-directive-line-regexp () "internal use only")
(defun  tal-keyword-on-directive-line-regexp ( word-list )
  "Returns a function that finds the words passed only if on a line starting
with ?"
  (setq tal-keyword-on-directive-line-regexp
        (concat "\\b"(regexp-opt word-list t)"\\b"))
  'tal-font-lock-directive-line
) 
(defvar tal-amid-font-lock-excursion nil
;; Used by `tal-font-lock-directive-line'.  When a line starting with ? in
;; column 1 is detected this variable holds the context needed to continue
;; searching for more keywords.  If nil a line starting with ? should be
;; searched for.
) 
(make-variable-buffer-local 'tal-amid-font-lock-excursion)
(defun tal-font-lock-directive-line ( search-limit )
;; This function finds keywords only in lines starting with ?.  Valid keywords
;; are described by `tal-keyword-on-directive-line-regexp'.  First a line
;; beginning with ? is searched for.  Once found, point is moved to the
;; beginning of that area and limit is set to the end.  Keywords are searched
;; for within that range.  If found, context is saved in
;; tal-amid-font-lock-excursion and the match-data is returned.  If not found,
;; another line starting with ?  is searched for.  If saved context exists when
;; this function is called then another keyword is searched for in the
;; previously narrowed region.  If none is found the next region is searched
;; for.
  (let ((looking t))
    (while
        (and looking
             (or tal-amid-font-lock-excursion
        	 (when (re-search-forward "^\\?.+\n" search-limit t)
        	   (setq tal-amid-font-lock-excursion (point))
        	   (goto-char (match-beginning 0))
        )    )   )
      (if (re-search-forward tal-keyword-on-directive-line-regexp
        		     tal-amid-font-lock-excursion t)
          (setq looking nil)
        (goto-char tal-amid-font-lock-excursion)
        (setq tal-amid-font-lock-excursion nil)
      )
    )
    (not looking)
  )
) 
;; This finds comments and strings because the syntax table can't handle TAL.
(defun tal-find-syntactic-keywords ( search-limit )
  ;; Comments starting with -- go to eol always, while comments starting with
  ;; !  go until another ! or eol.  Strings start and end with " as usual but
  ;; cannot span lines so they are terminated by eol.  This fcn returns nil if
  ;; neither is found.  It returns t and either match-string 1&2 are set for
  ;; comment or 3&4 are set if a string is found.  Point is left at the end of
  ;; the match.
  (when (re-search-forward "\\(?:--\\|!\\|\"\\)" search-limit t)
    ;; either a comment or string was found
    (let ((start (match-data))
          (match (match-string-no-properties 0))
          end)
      ;; see if it was a string
      (if (equal "\"" match)
          ;; This 'when' can't fail since eob is part of the search but if it
          ;; does then no search data will be set and the result will be the
          ;; original search above which is a shy group and so no sub-group
          ;; matches will return.  Seemingly appropriate.
          (when (re-search-forward "\\(?:\n\\|\"\\|\\'\\)" search-limit t)
            (setq end (match-data))                   
            (set-match-data
             `(,(car start) ,(car (cdr end))    ;match-string 0
               nil nil nil nil                  ;match-string 1&2 not found
               ,@start ,@end)))                 ;match-string 3&4
        ;; Must be a comment.  Determine type.
        (if (equal "!" match)
            (setq match "\\(?:\n\\|!\\|\\'\\)") ;! can delimit as well as eol/eob
          (setq match "\\(?:\n\\|\\'\\)"))      ;only eol or eob delimits
        ;;see above 'when' comment
        (when (re-search-forward match search-limit t) 
          (setq end (match-data))
          (set-match-data
           `(,(car start) ,(car (cdr end))      ;match-string 0
             ,@start ,@end)))))                 ;match-string 1&2
    ;; insure t returns if a string or comment was found. nil returns by default.
    t)
)
(defvar tal-static-font-lock-keywords
  ;; font-lock-keywords is a symbol or list of symbols yielding the keywords to
  ;; be fontified.  Keywords are listed here using either (MATCHER . FACENAME)
  ;; or (MATCHER . (MATCH FACENAME)) syntax.  Other options are available but
  ;; not used here.  For simplicity, all regexp's were designed so MATCH would
  ;; be 1.  Nothing forced this but to me it makes debug/maintenance easier.
  `((,(tal-keyword-anywhere-regexp tal-keywords-unqualified-data-types)
     1 font-lock-type-face)
    (,(tal-keyword-qualified-regexp tal-keywords-qualified-data-types)
     1 font-lock-type-face)
    (,(tal-keyword-anywhere-regexp tal-keywords-address-types)
     1 font-lock-type-face)
    (,(tal-keyword-on-directive-line-regexp tal-keywords-directives)
     1 font-lock-builtin-face)
    (,(tal-keyword-anywhere-regexp tal-keywords-builtin)
     1 font-lock-builtin-face)
    (,(tal-keyword-anywhere-regexp tal-keywords-statements)
     1 font-lock-keyword-face)
    ; this is necessary because b and d in these words are not word
    ; constituent characters, they are ( ) syntax.
    (,"\\(?:^\\|\\W\\)\\(begin\\|end\\)\\(?:\\'\\|$\\|\\W\\)"
     1 font-lock-keyword-face)
    (,(tal-keyword-anywhere-regexp tal-keywords-std-fcns)
     1 font-lock-keyword-face)
    (,(tal-keyword-anywhere-regexp tal-keywords-deprecated)
     1 font-lock-warning-face)
    (,(tal-keyword-anywhere-regexp tal-keywords-privileged)
     1 font-lock-warning-face)
    (,(tal-keyword-anywhere-regexp tal-keywords-nonreserved)
     1 font-lock-variable-name-face)
    (,tal-keyword-fcn-names-regexp 1 font-lock-function-name-face)
  )
)
(defvar tal-font-lock-keywords ())
(defun tal-build-font-lock-keywords ()
  "Used to create font-lock-keywords based on current customize settings."
  (append tal-static-font-lock-keywords 
         (when (> tal-column-marker-1 0)
           (list (list (format "^.\\{%d\\}\\(.\\)" tal-column-marker-1)
                       1 tal-column-marker-face 'prepend t)))
         (when (> tal-column-marker-2 0)
           (list (list (format "^.\\{%d\\}\\(.\\)" tal-column-marker-2)
                       1 tal-column-marker-face 'prepend t)))
         (when tal-primecode-warning
           ;; ]a  ]d or ]e cannot appear in col 1-2 if using PrimeCode.
           (list '("^\\][ade]" . font-lock-warning-face)))
  )
)
(defvar tal-font-lock-syntactic-keywords
 '(;; The B of Begin gets open paren syntax.  Case-fold assumed true.
   ("\\(^\\|\\s \\)\\(b\\)egin\\(\\s-\\|$\\)" (2 "(d"))
   ;; The D of End gets close paren syntax.
   ("\\(\\s-\\|^\\)en\\(d\\)\\b" (2 ")b"))
   ;; This function returns matches 1&2 for comments, 3&4 for strings.  I must
   ;; use "|"(15) rather than "\""(7) for strings because the begin and end
   ;; characters may not be the same.  Such as when eol terminates the string.
   (tal-find-syntactic-keywords
    (1 "<" nil t) (2 ">" nil t) (3 "|" nil t) (4 "|" nil t))
  )
 "A list of regexp's or functions.  Used to add syntax-table properties to
characters that can't be set by the syntax-table alone."
)
(defun tal-setup-font-lock ()
  "Sets up the buffer local value for font-lock-defaults and optionally
turns on font-lock-mode"
  ;; Column markers work by counting characters in the line.  Tabs throw the
  ;; count off and won't highlight the char in the correct column.  If there
  ;; are already tabs the column marker will look wierd but I'm not going to
  ;; mess with the users buffer unexpectedly by converting them.
  (when (or (/= tal-column-marker-1 0)
            (/= tal-column-marker-2 0) )
    (setq indent-tabs-mode nil)      ;documented as buffer local in emacs
  )
  ;; I use font-lock-syntactic-keywords to set some properties and I don't want
  ;; them ignored.
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  ;; I really can't imagine anyone wanting this off in TAL.  It would force you
  ;; never to use the words begin or end in a comment unless you balanced them.
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  ;; This allows column markers to be different in seperate tal-mode buffers.
  (set (make-local-variable 'tal-font-lock-keywords)
       (tal-build-font-lock-keywords))
  ;; This is where all the font-lock stuff actually gets set up.  Once
  ;; font-lock-defaults has it's value, setting font-lock-mode true should
  ;; cause all your syntax highlighting dreams to come true.
  (setq font-lock-defaults
         ;; The first value is all the keyword expressions.
       '(tal-font-lock-keywords
         ;; keywords-only means no strings or comments get fontified
         nil
         ;; case-fold (ignore case)
         t
         ;; syntax-alist, dollar sign and period need to be 'word characters'
         ((?\$ . "w")(?\. . "w"))
         ;; syntax-begin - no function defined to move outside syntactic block
         nil
         ;; font-lock-syntactic-keywords
         ;; takes (matcher (match syntax override lexmatch) ...)...
         (font-lock-syntactic-keywords . tal-font-lock-syntactic-keywords )
       )
  )
  ; font lock is turned on by default in this mode. Use customize to disable.
  (when tal-font-lock-always (font-lock-mode t))
)

;;; Imenu

(defcustom tal-imenu-menubar nil
  "If not nil, `imenu-add-to-menubar' is called during mode initialization.
This adds a [Menu name] menu to your menu bar.  By default the menu contains a
list of all procedures, sections and pages in your program.  You can go
directly to any item on the menu by selecting it.  You can control what
appears on this menu by modifying `tal-imenu-expression-alist'.  You must turn
imenu on for this to work.  See `imenu' in the Emacs reference manual for more
information.  Personally I recommend customizing `imenu-sort-function' to sort
by name."
  :type  '(choice :tag "Menu Name"
                  (string :tag "Menu Name")
                  (const "Index")
                  (const nil))
  :group 'tal
)
(defvar tal-imenu-syntax-alist ()
  "Overrides to tal-mode-syntax-table used during
imenu-generic-expression search."
  ;;AFAIK there are no character adjustments needed during imenu search.
)
(defcustom tal-imenu-expression-alist
  '(("?Sections" "^\\?section +\\(\\w+\\b\\)"                                    1)
    ("?Pages"    "^\\?page +\"\\s-*\\(.+?\\)\""                                  1)
    ("proc"      "^\\(?:\\w+\\(?:\\s-*(\\w+)\\)?\\s-+\\)?proc\\s-+\\(\\w+\\)\\b" 1)
    ;; When subprocs are 'on' imenu sees all proc code as belonging to the
    ;; last subproc defined :-( Moreover, there is no way to tell subprocs
    ;; with the same name in different procs apart.
    ;; ("SubProcs"  "^\\w*\\s-*subproc\\s-+\\(\\w+\\)\\b" 1)
  )
  "A list of regular expressions for creating an `imenu' index.

Each element has the form (list-name regexp num).

Where list-name is the name of the submenu under which items matching regexp
are found and num is the expression index defining the label to use for the
submenu entry.  When num = 0 the entire matching regexp text appears under
list-name.  When list-name is nil the matching entries appear in the root
imenu list rather than in a submenu.  See also `tal-imenu-menubar'"
  :type '(repeat (list (choice :tag "Submenu Name" string (const nil))
                       regexp (integer :tag "Regexp index")))
  :group 'tal
)
(defcustom tal-display-which-function t
  "This option turns `which-func' on for all tal-mode buffers.  `which-func'
is a package that causes the current function, section or page to be displayed
on the mode line.  `which-func' uses `imenu'.  Also see
`tal-imenu-expression-alist' for more information."
  :type 'boolean
  :group 'tal
)
(defun tal-setup-imenu ()
  "Installs tal-imenu-generic-expression & tal-imenu-syntax-alist."
  ;; imenu doc says these 3 are buffer-local by default
  (setq imenu-generic-expression tal-imenu-expression-alist)
  (setq imenu-syntax-alist tal-imenu-syntax-alist)
  (setq imenu-case-fold-search t) ;TAL/pTAL are never case sensitive
  (when tal-imenu-menubar
    (if (condition-case ()
            (progn (require 'imenu) t)
          (error nil))
        (imenu-add-menubar-index)
      (message "tal-imenu-menubar is set but imenu feature not available.")
    )
  )
  (when tal-display-which-function
    (if (condition-case ()
            (progn (require 'which-func) t)
          (error nil))
        (which-function-mode t)
      (message "tal-display-which-function set but which-func not available")
    )
  )
)

;;; Adaptive-fill / auto-fill (needs much work but it's a start)

(defcustom tal-restrict-auto-fill t
  "When not nil a buffer local value for `fill-nobreak-predicate' is created
to prevent code from being accidentally realligned.  The function uses syntax
highlighting to detect comments so `font-lock-mode' must be enabled for it to
function."
  :type 'boolean
  :group 'tal
)
(defun tal-setup-adaptive-fill ()
  "Sets up the TAL-MODE adaptive-fill variables"
  (set (make-local-variable 'fill-individual-varying-indent)
       nil)
  (set (make-local-variable 'auto-fill-inhibit-regexp)
       "\\s-*[^!-]")
  (set (make-local-variable 'comment-use-syntax)
       t)
  (set (make-local-variable 'comment-start)
       "--")
  (set (make-local-variable 'comment-end)
       "")
  (set (make-local-variable 'comment-start-skip)
       "\\(\\s<\\|--\\)\\s-*")
  (set (make-local-variable 'sentence-end)
       "\\(;\\|\\.[ \t\n\f]\\)")
  (set (make-local-variable 'paragraph-start)
       "^\\([\n\f]\\|\\s-*begin\\b\\)")
  (set (make-local-variable 'paragraph-separate)
       "\\(^\n\\|\\s-end\\([;\n]\\|\\s-\\)\\)")
  (set (make-local-variable 'adaptive-fill-regexp)
       "^\\s-*\\(!\\|--\\)[~%^&()_#[*|;:-=+]*\\s-*")
  (set (make-local-variable 'adaptive-fill-first-line-regexp)
       adaptive-fill-regexp)
  (when tal-restrict-auto-fill
    ; This is supposed to restrict auto-fill to comments only
    (fset (make-local-variable 'fill-nobreak-predicate)
          (lambda ()
            (not (eq (get-text-property (point) 'face)
                     'font-lock-comment-face))
          )
    )
  )
)

;;; Indentation

(defun tal-indent-line ()
  "Indent current line of Tal code."
  (interactive)
  (let ((savep (> (current-column) (current-indentation)))
	(indent (condition-case () (max (tal-calculate-indentation) 0)
		  (error 0))))
    (if savep
	(save-excursion (indent-line-to indent))
      (indent-line-to indent)
    )
  )
)

(defun tal-calculate-indentation ()
  "Return appropriate indentation for current line as TAL code.  In usual case
returns an integer: the column to indent to.  If the value is nil, that means
don't change the indentation because the line starts inside a string."
  4
)

;;; Language Skeletons -- Feel free to add more of your own!

(defcustom tal-keywords-case 'camel
  "*Indicates if keywords in skeletons should be all UPPER CASE, all lower
case or Camel Case (First Char Upper & Rest Lower)."
  :type  '(choice (const :tag "ALL CAPS"   upper)
                  (const :tag "all small"  lower)
                  (const :tag "Camel Case" camel))
  :group 'tal
)
(defun tal-skel-transform ( element )
  "Used to insure skeleton's are inserted using the requested capitalization."
  ;; This should be made more complex to only change the case of certain words
  ;; so the user can create skeletons containing items that should not be
  ;; affected by tal-keywords-case.  There are 3 obvious ways.  1) use the
  ;; keywords tables above. 2) add a customize to ignore words. 3) add a
  ;; customize to specify specific words to be affected.  Preferences?
  (if (stringp element)
    (cond
     ((eq tal-keywords-case 'upper) (upcase element))
     ((eq tal-keywords-case 'lower) (downcase element))
     ( t                            (capitalize element))
    )
    element
  )
)

(define-skeleton tal-if-skel
  "Inserts a standard TAL/pTAL if/then statement skeleton."
  nil "IF (" _ ") THEN"
      \n > "  BEGIN"
      \n "  " _
      \n > "END\;"
)
(define-skeleton tal-if-else-skel
  "Inserts a standard TAL/pTAL if/then statement skeleton."
  nil "IF (" _ ") THEN"
      \n > "  BEGIN"
      \n "  " _
      \n > "END  "
      \n > -2 "ELSE"
      \n > "  BEGIN"
      \n "  " _
      \n > "END\;"
)
(define-skeleton tal-case-skel
  "Inserts a standard TAL/pTAL Labled Case -> statement skeleton."
  nil "CASE (" _ ") OF"
      \n > "  BEGIN"
      \n > "  " _ "-> ;"
      \n > "OTHERWISE -> ;  "
      \n > -2 "END\;"
)
(define-skeleton tal-proc-skel
  "This is an example of a procedure skeleton."
  nil "?SECTION"
      \n "?page " _
      \n > "  BEGIN"
      \n > "  " _ "-> ;"
      \n > "OTHERWISE -> ;  "
      \n > -2 "END\;"
)

;;; Movement by ...

;(defvar tal-outline-regexp
;...)

;;;###autoload
(defun tal-mode () "
A major mode for editing TAL/pTAL language program source files.
Customization options are available via:
M-x customize-group <ret> TAL <ret>

This mode provides TAL specific support for the following packages:
    `font-lock-mode'            `show-paren-mode'
    `imenu'                     `which-function'
    `skeleton-insert'           `auto-fill-mode'
    `adaptive-fill-mode'        `filladapt-mode'

It also implements the following commands  M-x ... commands

tal-mode             Activates this mode for the current buffer
tal-case-skel        Inserts a labeled case statement skeleton
tal-if-skel          Inserts an if/then statement skeleton
tal-if-else-skel     Inserts an if/then/else statement skeleton
tal-proc-skel        Example of a skeleton procedure
tal-column-marker-1  \These move the column markers for this 
tal-column-marker-2  /buffer only. See C-h f tal-column-marker-1

Use  C-h b  to see key bindings.
"
  (interactive)
  (kill-all-local-variables)
  (set (make-local-variable 'major-mode) 'tal-mode)
  (set (make-local-variable 'mode-name) "TAL")
  (set (make-local-variable 'make-backup-files) nil) ;necessary for now
  (use-local-map tal-mode-map)
  (set-syntax-table tal-mode-syntax-table)
  (tal-setup-font-lock)
  (tal-setup-adaptive-fill)
;  (tal-setup-abbrevs)
  (tal-setup-imenu)
  (set (make-local-variable 'indent-line-function) 'indent-relative-maybe)
  (set (make-local-variable 'skeleton-transformation) 'tal-skel-transform)
;  (set (make-local-variable 'outline-regexp) tal-outline-regexp)
  (show-paren-mode 1)
  (run-hooks 'tal-mode-hook)
)

(provide 'tal-mode)

;;; tal-mode.el ends here.
