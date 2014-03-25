;;; ddl-mode.el --- Handles the Tandem-Compaq-HP DDL language.

;; Copyright (C) 2001 Free Software Foundation, Inc.

;; Author: Rick Bielawski <rbielaws@i1.net>
;; Keywords: languages, extensions, tandem, compaq, hp

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

;; DDL is Tandem's DATA DEFINITION Language.

;; Keywords as of G06.05 are recognized by this version of ddl-mode.
;; imenu recognizes ?section <name> and ?page <name> declarations
;; as well as the expected RECORD <name>. & DEFINITION <name>. lines.
;; Both ! and * style comments are handled correctly (I think).
;; Movement by balanced expressions is supported.  That is, begin/end pairs
;;   are recognized.  However paren-mode and blink-matching-paren cannot 
;;   recognize begin/end pairs due to limitations/bugs.  Paren-mode can be
;;   'fixed' by by changing the following in paren.el and recompiling.
;;
;;   (defun show-paren-function ()
;;     ;; Do nothing if no window system to display results with.
;;     ;; Do nothing if executing keyboard macro.
;;     ;; Do nothing if input is pending.
;;     (when window-system
;;       (let (pos dir mismatch face (oldpos (point)))
;;         (cond (;(eq (char-syntax (preceding-char)) ?\))
;;                (save-excursion
;;                  (goto-char (1- (point)))
;;                  (looking-at "\\s)"))
;;                (setq dir -1))
;;               (;(eq (char-syntax (following-char)) ?\()
;;                (looking-at "\\s(")
;;         (setq dir 1)))
;;    ...
;;
;; This is not a complete fix because begin/end are highlighted as being
;;   mismatched but they do highlight.  This happens because it uses the
;;   matching-paren function to determine if they match.  That function only
;;   checks the syntax of the character 'b' or 'd' not the syntax of the text.
;; The blink-matching-paren support cannot even be 'fixed' this well.
;;   The function (defined in simple.el) is not even called unless the
;;   character typed belongs to the paren syntax class (which the 'd' in
;;   end does not).  That character is only converted to paren class via
;;   font-lock-syntactic-keywords once the whole word is recognized.
;; There is a further problem introduced by assigning the 'd' of End to the
;;   'paren' syntax class.  It is no longer part of the 'word' class.  This
;;   makes movement by words act odd.  I.E. point will be placed at EN.D
;;   because 'd' is no longer considered a 'word' character.  I could use
;;   the expression "\<end\(\w\|;\)" insted of "\<en\(d\)\>" but then you
;;   get forced into puting a space after 'end' in all cases where a newline
;;   would typically be the next character.  This is impossible to maintain
;;   in cases where trailing blanks get stripped automatically.
;;
;; There is no adaptive-fill support yet.
;; Custom indentation support has not been created yet.
;; There are no abbrevs defined.

;;; Installing:

;; There are 3 ways to edit a file using DDL-MODE.  The first method manually
;; selects ddl-mode as the editing mode.  The other 2 cause emacs to recognize
;; automatically that you want to visit the file using ddl-mode.
;;
;; 1. While visiting the target file, type: M-x ddl-mode 
;; 2. Put the string -*-ddl-*- in a comment on the first line of the file.
;; 3. Create an association between a particular file naming convention and
;;    ddl-mode.  This is done by adding an association to auto-mode-alist.
;; For example:
;; (setq auto-mode-alist  
;;   (append 
;;     '(("\\.ta0l\\'" . ddl-mode)         ;extension of .ddl means ddl-mode
;;       ("\\([\\/]\\|^\\)[^.]+$" . ddl-mode)) ;so does no extension at all.
;;    auto-mode-alist))
;;
;; The above tell emacs that you want to use ddl-mode but you must load
;; ddl-mode before you can use it.  There are 2 methods of telling emacs 
;; how to load the ddl-mode definitions.  The first unconditionally loads
;; ddl-mode definitions immediately.  The second tells emacs to load ddl-mode
;; the first time a request to use it is made.  Add one of the following lines
;; to your .emacs file.
;;
;;(require 'ddl-mode)
;;(autoload 'ddl-mode "ddl-mode" "Major mode for Tandem DDL files." t nil)
;;
;; Either way you choose to load ddl-mode, emacs needs to be able to find it.
;; Place the ddl-mode.el file in a directory on the load-path; typically the
;; `.../lisp/progmodes' directory or maybe the `.../site-lisp' directory.

;;; Code:

(defgroup ddl nil
  "Major mode for editing Tandem DDL source files in Emacs."
  :group 'languages
)

;;; KEY MAP

(defvar ddl-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Personally, I like this to work within all major modes
    (define-key map [?\C-j] 'eval-print-last-sexp)
    ;; not many custom definitions yet
    (define-key map [?\C-c ?\C-f] 'auto-fill-mode)
    map)
  "Keymap for `ddl-mode'."
)

(defvar ddl-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\n ">" st)
    (modify-syntax-entry ?! "<13" st)
    (modify-syntax-entry ?$ "'" st)
    (modify-syntax-entry ?% "'" st)
    (modify-syntax-entry ?& "'" st)
    (modify-syntax-entry ?' "." st)
    (modify-syntax-entry ?\( "'" st)
    (modify-syntax-entry ?\) "." st)
    (modify-syntax-entry ?* "<" st)
    (modify-syntax-entry ?+ "." st)
    (modify-syntax-entry ?, "." st)
    (modify-syntax-entry ?- "w" st)
    (modify-syntax-entry ?. "." st)
    (modify-syntax-entry ?/ "." st)
    (modify-syntax-entry ?: "." st)
    (modify-syntax-entry ?\; "." st)
    (modify-syntax-entry ?< "." st)
    (modify-syntax-entry ?= "." st)
    (modify-syntax-entry ?> "." st)
    (modify-syntax-entry ?\? "'" st)
    (modify-syntax-entry ?@ "'" st)
    (modify-syntax-entry ?[ "'" st)
    (modify-syntax-entry ?] "." st)
    (modify-syntax-entry ?\\ "'" st)
    (modify-syntax-entry ?^ "w" st)
    (modify-syntax-entry ?_ "w" st)
    (modify-syntax-entry ?{ "." st)
    (modify-syntax-entry ?| "." st)
    (modify-syntax-entry ?} "." st)
    st)
  "Syntax table for `ddl-mode'."
)

; All keyword lists get sorted, so you can add new words to the end.

(defvar ddl-keywords-directives
  '("c00align"               "c_decimal"              "c_match_historic_tal"
    "ccheck"                 "cdefineupper"           "cendif"
    "cfieldalign_matched2"   "cifdef"                 "cifndef"
    "clistin"                "clistout"               "clistoutdetail"
    "coblevel"               "columns"                "comments"
    "cpragma"                "ctokenmap_asdefine"     "cundef"
    "deflist"                "dict"                   "dictn"
    "dictr"                  "do_ptal_off"            "do_ptal_on"
    "edit"                   "errors"                 "expandc"
    "fieldalign_shared8"     "filler"                 "forcheck"
    "fortranunderscore"      "help"                   "linecount"
    "list"                   "nclconstant"            "newfup_fileformat"
    "noc00align"             "noc_decimal"            "noc_match_historic_tal"
    "noccheck"               "nocdefineupper"         "noclistin"
    "noclistout"             "nocomments"             "nocpragma"
    "noctokenmap_asdefine"   "nodeflist"              "nodict"
    "noexpandc"              "nofileformat"           "noforcheck"
    "nofortranunderscore"    "nolist"                 "nonclconstant"
    "nooutput_sensitive"     "nopascalcheck"          "nopascalnamedvariant"
    "noreport"               "notalallocate"          "notalcheck"
    "notalunderscore"        "notimestamp"            "novalues"
    "nowarn"                 "oldfup_fileformat"      "output_sensitive"
    "page"                   "pascalbound"            "pascalcheck"
    "pascalnamedvariant"     "report"                 "reset"
    "section"                "setsection"             "source"
    "spacing"                "taclgen"                "talallocate"
    "talbound"               "talcheck"               "talunderscore"
    "tedit"                  "timestamp"              "values"
    "warn"                   "warnings"
  )
  "List of DDL compiler directives.
   Used to create the font-lock-keywords table."
)
(defvar ddl-keywords-output-directives
  '("c"         "cobol"     "ddl"       "fortran"   "fup"       "noc"
    "nocobol"   "noddl"     "nofortran" "nofup"     "nopascal"  "notacl"
    "notal"     "out"       "pascal"    "tacl"      "tal"
  )
  "List of DDL file output control compiler directives.
   Used to create the font-lock-keywords table."
)
(defvar ddl-keywords-reserved
  '("are"       "end"       "is"        "through"   "enum"      "binary"
    "complex"   "character" "thru"      "filler"    "of"        "time"
    "logical"   "float"     "on"        "timestamp" "begin"
  )
  "List of DDL reserved words - cannot be used as field names.
   Used to create the font-lock-keywords table."
)
(defvar ddl-keywords-statements 
  '("all"                     "allowed"                 "as"
    "ascending"               "assigned"                "audit"
    "auditcompress"           "be"                      "bit"
    "block"                   "buffered"                "buffersize"
    "by"                      "cfieldalign_matched2"    "character"
    "c_match_historic_tal"    "code"                    "comp"
    "comp-3"                  "compress"                "computational"
    "computational-3"         "constant"                "crtpid"
    "current"                 "date"                    "datetime"
    "day"                     "dcompress"               "def"
    "definition"              "delete"                  "depending"
    "descending"              "device"                  "display"
    "duplicates"              "edit-pic"                "entry-sequenced"
    "exit"                    "ext"                     "external"
    "file"                    "fieldalign_shared8"      "fname"
    "fname32"                 "for"                     "fraction"
    "heading"                 "help"                    "high-number"
    "high-value"              "hour"                    "icompress"
    "index"                   "indexed"                 "interval"
    "just"                    "justified"               "key"
    "key-sequenced"           "keytag"                  "ln"
    "low-number"              "low-value"               "low-values"
    "maxextents"              "minute"                  "month"
    "must"                    "n"                       "no"
    "not"                     "novalue"                 "noversion"
    "null"                    "occurs"                  "oddunstr"
    "output"                  "packed-decimal"          "phandle"
    "pic"                     "picture"                 "quote"
    "quotes"                  "record"                  "redefines"
    "refresh"                 "relative"                "renames"
    "right"                   "second"                  "seq"
    "sequence"                "serialwrites"            "setlocalename"
    "show"                    "space"                   "spaces"
    "spi-null"                "sql"                     "sqlnull"
    "sql-nullable"            "ssid"                    "subvol"
    "system"                  "tacl"                    "talunderscore"
    "temporary"               "time"                    "times"
    "to"                      "token-code"              "token-map"
    "token-type"              "transid"                 "tstamp"
    "type"                    "unsigned"                "unstructured"
    "update"                  "upshift"                 "usage"
    "use"                     "username"                "value"
    "varchar"                 "varying"                 "varifiedwritesversion"
    "year"                    "zero"                    "zeroes"
    "zeros"
  )
  "List of DDL statement keywords
   Used to create the font-lock-keywords table."
)
(defvar ddl-keyword-fcn-names-regexp
  "^\\s-\\{0,3\\}\\(?:record\\|definition\\|def\\)\\s-+\\(\\w+\\)\\s-*\\."
  "regexp that finds the names of record & structure definitions."
)

;;; Font lock (highlighting)

(defcustom ddl-font-lock-always t
  "If true, DDL-MODE will always turn `font-lock-mode' on even if
`global-font-lock-mode' is off.  nil disables this feature."
  :type 'boolean
  :group 'ddl
)
(defvar ddl-column-marker-face 'ddl-column-marker-face)
(defface ddl-column-marker-face
  '((t (:background "grey")))
  "Used for marking column 79 (or whatever)."
  :group 'ddl
  :group 'faces
)
(defcustom ddl-column-marker-1 0
  "When not zero, this column is font-lock'ed to ddl-column-marker-face.
   Setting this to zero turns off the column marker.  This column marker
   is useful for columnizing things or when working in languages like COBOL
   where a particular column has significance."
  :type 'integer
  :group 'ddl
)
(defcustom ddl-column-marker-2 79
  "When not zero, this column is font-lock'ed to ddl-column-marker-face.
   Setting this to zero turns off the column marker.  This column marker
   is most useful when working in languages like COBOL where a particular
   column has significance."
  :type 'integer
  :group 'ddl
)
(defcustom ddl-primecode-warning t
  "When not nil, instances of ]a ]d and ]e appearing in column 1-2 are
highlighted with a warning face.  This alerts you that submission of this file
to RMS/PrimeCode will fail due to invalid contents."
  :type 'boolean
  :group 'ddl
)
(defun ddl-keyword-anywhere-regexp ( word-list )
  "Returns a regexp that finds the words passed.
   But only if the keyword is surrounded by non-word chars."
  (concat "\\<"(regexp-opt word-list t)"\\>")
)
(defvar ddl-keyword-on-directive-line-regexp () "internal use only")
(defun  ddl-keyword-on-directive-line-regexp ( word-list )
  "Returns a function that finds the words passed only if on a line starting
with ?"
  (setq ddl-keyword-on-directive-line-regexp 
	(concat "\\b"(regexp-opt word-list t)"\\b"))
  'ddl-font-lock-directive-line
)
(defvar ddl-amid-font-lock-excursion nil
  "Used by `ddl-font-lock-directive-line'.  When a line starting with ? in
column 1 is detected this variable holds the context needed to continue
searching for more keywords.  If nil a line starting with ? should be searched
for."
)
(make-variable-buffer-local 'ddl-amid-font-lock-excursion)
(defun ddl-font-lock-directive-line ( search-limit )
  "This function finds keywords only in lines starting with ?.  Valid keywords
are described by ddl-keyword-on-directive-line-regexp.  First a line beginning
with ? is searched for.  Once found, point is moved to the beginning of that
area and limit is set to the end.  Keywords are searched for within that
range.  If found, context is saved in ddl-amid-font-lock-excursion and the
match-data is returned.  If not found, another line starting with ?  is
searched for.  If saved context exists when this function is called then
another keyword is searched for in the previously narrowed region.  If none is
found the next region is searched for."
  (let ((looking t))
    (while 
	(and looking
	     (or ddl-amid-font-lock-excursion
		 (when (re-search-forward "^\\?.+\n" search-limit t)
		   (setq ddl-amid-font-lock-excursion (point))
		   (goto-char (match-beginning 0))
	)    )   )
      (if (re-search-forward ddl-keyword-on-directive-line-regexp
			     ddl-amid-font-lock-excursion t)
	  (setq looking nil)
	(goto-char ddl-amid-font-lock-excursion)
	(setq ddl-amid-font-lock-excursion nil)
      ) 
    )
    (not looking)
  )
)
(defun ddl-keyword-directives-regexp ( word-list )
  "Returns a regexp that finds ?directives."
  (concat "^\\?.*\\<" (regexp-opt word-list t) "\\>")
)
(defvar ddl-font-lock-keywords
  ; font-lock-keywords is a symbol or list of symbols yielding the keywords to
  ; be fontified.  Keywords are listed here using either (MATCHER . FACENAME)
  ; or (MATCHER . (MATCH FACENAME)) syntax.  Other options are available but
  ; not used here.  For simplicity, all regexp's were designed so MATCH would
  ; be 1.  Nothing forced this but to me it makes debug/maintenance easier.
  `(
    ; this is necessary because b and d in these words are not word
    ; constituent characters, they are ( ) syntax.
    (,"\\W\\(begin\\|end\\)\\W" 1 font-lock-keyword-face)
;???("^\\s-\\{0,2\\}\\(end\\|def\\|definition\\|record\\)\\W"
;???  1 font-lock-keyword-face)
    (,(ddl-keyword-anywhere-regexp ddl-keywords-statements)
     1 font-lock-keyword-face)
    (,(ddl-keyword-anywhere-regexp ddl-keywords-reserved)
     1 font-lock-variable-name-face)
    (,(ddl-keyword-directives-regexp ddl-keywords-output-directives)
     1 font-lock-warning-face)
    (,(ddl-keyword-on-directive-line-regexp ddl-keywords-directives)
     1 font-lock-builtin-face)
    (,ddl-keyword-fcn-names-regexp 1 font-lock-function-name-face)
    ,@(when (> ddl-column-marker-1 0)
        (list (list (format "^.\\{%d\\}\\(.\\)" ddl-column-marker-1)
                    1 ddl-column-marker-face 'prepend t)))
    ,@(when (> ddl-column-marker-2 0)
        (list (list (format "^.\\{%d\\}\\(.\\)" ddl-column-marker-2)
                    1 ddl-column-marker-face 'prepend t)))
    ,@(when ddl-primecode-warning
        ;; ]a  ]d or ]e cannot appear in col 1-2 if using RMS/PrimeCode.
        (list '("^\\][ade]" . font-lock-warning-face)))
  )
  "Keyword highlighting specification for `ddl-mode'."
)
(defvar ddl-font-lock-syntactic-keywords
 '(; The B of Begin gets open paren syntax.  Case-fold assumed true.
   ("\\(\\s-\\|^\\)\\(b\\)egin\\(\\s-\\|$\\)" (2 (4 . ?d)))
   ; The D in def or definition gets open-paren syntax.
   ("^\\s-\\{0,2\\}\\(d\\)\\(ef\\|efinition\\)\\b" 1 (4 . ?d))
   ; The R in Record gets open-paren syntax.
   ("^\\s-\\{0,2\\}\\(r\\)ecord\\b" 1 (4 . ?d))
   ; The D of End gets close paren syntax.
   ("\\(\\s-\\|^\\)en\\(d\\)\\b" (2 (5 . ?b)))
   ; Pairs of ! enclose comments but eol terminates them too
;   ("\\(!\\)[^\n!]*\\([\n!]\\|\\'\\)" (1 (11)) (2 (12)))
   ; Asterisk in column 1 defines a comment to EOL
;   ("^\\(\\*\\)[^\n]*\\(\n\\|\\'\\)" (1 (11)) (2 (12) nil t))
   ; A quote is terminated by a matching quote of course.
   ; But I also terminate it by the character preceeding \n
   ("\\(\"\\)[^\n\"]*\\(?:\\(\"\\)\\|\\(.\\)\n\\)"
    (1 (15)) (2 (15) nil t) (3 (15) nil t))
  )
 "A list of regexp's or functions.  Used to add syntax-table properties to
characters that can't be set by the syntax-table alone."
)
(defun ddl-setup-font-lock ()
  "Sets up the buffer local value for font-lock-defaults."
  ; Column markers work by counting characters in the line.  Tabs throw the
  ; count off and won't highlight the char in the correct column.  If there
  ; are already tabs the column marker will look wierd but I'm not going to
  ; mess with the users buffer unexpectedly by converting them.
  (when (or (/= ddl-column-marker-1 0)
            (/= ddl-column-marker-2 0)
        )
    (setq indent-tabs-mode nil)      ;documented as buffer local
  )
  ; I use font-lock-syntactic-keywords to set some properties and I don't want
  ; them ignored.
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  ; I really can't imagine anyone wanting this off in DDL.  It would force you
  ; never to use the words begin or end in a comment unless you balanced them.
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  ; This is where all the font-lock stuff actually gets set up.  Once
  ; font-lock-defaults has it's value, setting font-lock-mode true should
  ; cause all your syntax highlighting dreams to come true.
  (set (make-local-variable 'font-lock-defaults)
         ; The first value is all the keyword expressions.
       '(ddl-font-lock-keywords
         ; keywords-only means no strings or comments get fontified
         nil
         ; case-fold (ignore case) 
         t
         ; syntax-alist AFAIK nothing needs to be here
         ()
         ; syntax-begin - no function defined to move outside syntactic block
         nil
         ; font-lock-syntactic-keywords
         ; takes (matcher (match syntax override lexmatch) ...)...
         (font-lock-syntactic-keywords . ddl-font-lock-syntactic-keywords )
       )
  )
  ; font lock is turned on by default in this mode. Use customize to disable.
  (when ddl-font-lock-always (font-lock-mode t))
)

;;; Imenu

(defcustom ddl-imenu-menubar nil
  "If not nil, `imenu-add-to-menubar' is called during mode initialization.
This adds a [Menu name] menu to your menu bar.  By default the menu contains a
list of all procedures, sections and pages in your program.  You can go
directly to any item on the menu by selecting it.  You can control what
appears on this menu by modifying `ddl-imenu-expression-alist'.  You must turn
imenu on for this to work.  See `imenu' in the Emacs reference manual for more
information.  Personally I recommend customizing `imenu-sort-function' to sort
by name."
  :type  '(choice :tag "Menu Name" (string :tag "Menu Name") (const nil))
  :group 'ddl
)
(defvar ddl-imenu-syntax-alist ()
  "Overrides to ddl-mode-syntax-table used during
imenu-generic-expression search."
  ;AFAIK there are no character adjustments needed during imenu search.
)
(defcustom ddl-imenu-expression-alist
  '(("?Sections" "^\\?SECTION +\\(\\w+\\b\\)"                           1)
    ("?Pages"    "^\\?PAGE +\"\\(.+?\\)\""                              1)
    ("Records"   "^\\s-*\\(record\\)\\s-+\\(\\w+\\)\\s-*\\."            2)
    ("Def's"     "^\\s-*\\(definition\\|def\\)\\s-+\\(\\w+\\)\\s-*\\."  2)
  )
  "A list of regular expressions for creating an `imenu' index.

Each element has the form (list-name regexp num).

Where list-name is the name of the submenu under which items matching regexp
are found and num is the expression index defining the label to use for the
submenu entry.  When num = 0 the entire matching regexp text appears under
list-name.  When list-name is nil the matching entries appear in the root
imenu list rather than in a submenu.  See also `ddl-imenu-menubar'"
  :type '(repeat (list (choice :tag "Submenu Name" string (const nil))
                       regexp (integer :tag "Regexp index")))
  :group 'ddl
)
(defcustom ddl-display-which-function t
  "This option turns `which-func' on for all ddl-mode buffers.  `which-func'
is a package that causes the current record, section or page to be displayed
on the mode line.  `which-func' uses `imenu'.  Also see
`ddl-imenu-expression-alist' for more information."
  :type 'boolean
  :group 'ddl
)
(defun ddl-setup-imenu ()
  "Installs ddl-imenu-generic-expression & ddl-imenu-syntax-alist."
  ;; imenu doc says these 3 are buffer-local by default
  (setq imenu-generic-expression ddl-imenu-expression-alist)
  (setq imenu-syntax-alist ddl-imenu-syntax-alist)
  (setq imenu-case-fold-search t) 
  (when ddl-imenu-menubar
    (if (condition-case ()
            (progn (require 'imenu) t)
          (error nil))
        (imenu-add-menubar-index)
      (message "ddl-imenu-menubar set but imenu feature not available.")
    )
  )
  (when ddl-display-which-function
    (if (condition-case ()
            (progn (require 'which-func) t)
          (error nil))
        (which-function-mode t)
      (message "ddl-display-which-function set but which-func not available")
    )
  )
)

;;; Indentation

(defun ddl-indent-line ()
  "Indent current line of DDL code."
  (interactive)
  (let ((savep (> (current-column) (current-indentation)))
	(indent (condition-case nil (max (ddl-calculate-indentation) 0)
		  (error 0))))
    (if savep
	(save-excursion (indent-line-to indent))
      (indent-line-to indent)
    )
  )
)

(defun ddl-calculate-indentation ()
  "Return appropriate indentation for current line as DDL code.
   In usual case returns an integer: the column to indent to.
   If the value is nil, that means don't change the indentation
   because the line starts inside a string."
  4
)


;(defvar ddl-outline-regexp
;...)

;;;###autoload
(defun ddl-mode ()
  "A major mode for editing DDL (Data Definition Language) source.
Customization options are available via:
M-x customize-group <ret> DDL <ret>

This mode provides DDL specific support for the following packages:
    `font-lock-mode'            `show-paren-mode'
    `imenu'                     `which-function'

It also implements the following commands  M-x ... commands

ddl-mode          activates this mode for the current buffer

Use  C-h b  to see key bindings.
"
  (interactive)
  (kill-all-local-variables)
  (set (make-local-variable 'major-mode) 'ddl-mode)
  (set (make-local-variable 'mode-name) "DDL")
  (set (make-local-variable 'make-backup-files) nil) ;necessary for now
  (use-local-map ddl-mode-map)
  (set-syntax-table ddl-mode-syntax-table)
  (ddl-setup-font-lock)
;  (ddl-setup-adaptive-fill)
;  (ddl-setup-abbrevs)
  (ddl-setup-imenu)
  (set (make-local-variable 'indent-line-function) 'indent-relative-maybe)
;  (set (make-local-variable 'skeleton-transformation) 'ddl-skel-transform)
;  (set (make-local-variable 'outline-regexp) ddl-outline-regexp)
  (show-paren-mode 1)
  (run-hooks 'ddl-mode-hook)
)

(provide 'ddl-mode)

;;; ddl-mode.el ends here.