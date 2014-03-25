;;; tacl-mode.el --- Handles the Tandem/NSK/Guardian TACL language.
;;                   A proprietary language of Tandem/Compaq/HP computers.

;; Copyright (C) 2001, 2004 Free Software Foundation, Inc.

;; Author: Rick Bielawski <rbielaws@i1.net>
;; Keywords: languages, extensions, tandem, tacl, nsk

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

;; TACL stands for Tandem Advanced Command Language.  

;; Keywords as of G06.10 are recognized. There are 3 types of keywords.
;;   #builtin functions, #builtin variables, option keywords.
;;   Option keywords are those that are only keywords when found between
;;   slash marks or vertical bars.
;; All keywords have abbrev table entries.  Use M-x list-abbrevs for a listing.
;;   Abbrevs are generated programatically from tacl-keywords-... to be the
;;   minimum number of characters to uniquely identify the keyword.
;; Bracket handling is managed by emacs show-paren-mode. I just turn it on.
;; imode recognizes both ?section and [#def ...] style definitions but only
;;   within the first 3 characters of a line.  This is intended to prevent
;;   large numbers of sub-definitions from making imenu huge/useless.  You can
;;   tweek this by altering tacl-imenu-expression-alist thru customize.
;; There is no adaptive-fill support yet.
;; Custom indentation support has not been created yet.

;;; Installing:

;; There are 4 ways to edit a file using TACL-MODE.  The first method manually
;; selects tacl-mode as the editing mode.  The other 3 cause emacs to recognize
;; automatically that you want to visit the file using tacl-mode.
;;
;; 1. While visiting the target file, type: M-x tacl-mode 
;; 2. Put the string -*-tacl-*- in a comment on the first line of the file.
;; 3. Create an association between a particular file naming convention and
;;    tacl-mode.  This is done by adding an association to auto-mode-alist.
;; 4. See RECOGNIZING LANGUAGE WITHOUT FILE EXTENSIONS below.
;; For example:
;; (setq auto-mode-alist  
;;   (append 
;;     '(("\\.tacl\\'" . tacl-mode)      ;extension of .tacl means tacl-mode
;;       ("\\([\\/]\\|^\\)[^.]+$" . tacl-mode)) ;so does no extension at all.
;;    auto-mode-alist))
;;
;; The above tell emacs that you want to use tacl-mode but you must load
;; tacl-mode before you can use it.  There are 2 methods of telling emacs 
;; how to load the tacl-mode definitions.  The first unconditionally loads
;; tacl-mode definitions immediately.  The second tells emacs to load tacl-mode
;; the first time a request to use it is made.  Add one of the following lines
;; to your .emacs file.
;;
;; (require 'tacl-mode)
;; (autoload 'tacl-mode "tacl-mode" "Major mode for Tandem TACL files." t nil)
;;
;; Either way you choose to load tacl-mode, emacs needs to be able to find it.
;; Place the tacl-mode.el file in a directory on the load-path; typically the
;; `.../lisp/progmodes' directory or maybe the `.../site-lisp' directory.
;; Typically you would also want to byte compile tacl-mode.el.
;; I make sure that there are no warnings.  If you get some they are NOT ok.

;;; RECOGNIZING LANGUAGE WITHOUT FILE EXTENSIONS

;;  Since Guardian/Tandem/NSK... doesn't support extensions I use the following
;;  code in my .emacs to recognize the language and set the proper mode.
;;  This only handles the cases I run into most often but it's a good start and
;;  example of how you can support files you edit often and can't handle by
;;  putting -*-tacl-*- in a comment on the first line.
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
;; 2004-06-17 RGB Mostly lots of comments and documentation updates were made
;;                Customize options were added for tacl-font-lock-always and
;;                tacl-primecode-warning.

;;; Code:

(defgroup tacl nil
  "Major mode for editing Tandem TACL source files in Emacs.
While in tacl-mode use C-h m for a description of the mode's features."
  :group 'languages
)

;;; KEY MAP

(defvar tacl-mode-map
  (let ((map (make-sparse-keymap)))
    ;; I like this to work within all major modes
    (define-key map [?\C-j] 'eval-print-last-sexp)
    ;; not many custom definitions YET
    (define-key map [?\C-c ?\C-f] 'auto-fill-mode)
    (define-key map [?\C-c ?\C-e] 'tacl-if-else-skel)
    (define-key map [?\C-c ?\C-i] 'tacl-if-skel)
    (define-key map [?\C-c ?\C-c] 'tacl-case-skel)
    map)
  "Keymap for `tacl-mode'."
)
(defvar tacl-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\# "w" st)
    (modify-syntax-entry ?\_ "w" st)
    (modify-syntax-entry ?^  "w" st)
    (modify-syntax-entry ?\. "_" st)
    (modify-syntax-entry ?\: "_" st)
    (modify-syntax-entry ?\? "_" st)
    (modify-syntax-entry ?\[ "(]" st)
    (modify-syntax-entry ?\] ")[" st)
    (modify-syntax-entry ?\( "()" st)
    (modify-syntax-entry ?\) ")(" st)
    (modify-syntax-entry ?\{ "<" st)
    (modify-syntax-entry ?\} ">" st)
    (modify-syntax-entry ?\= "_ b12" st)
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?\~ "/" st)
    (modify-syntax-entry ?\| "$" st)
    (modify-syntax-entry ?\/ "$" st)
    (modify-syntax-entry ?\% "$" st)
    (modify-syntax-entry ?\$ "w" st)
    (modify-syntax-entry ?\' "_" st)
    (modify-syntax-entry ?\@ "_" st)
    (modify-syntax-entry ?\\ "_" st)
    st)
  "Syntax table for `tacl-mode'."
)

; All keyword lists get sorted, so you can add new words to the end.
; NOTE: Words containing CAPITAL LETTERS will never autoexpand.
; Use M-x list-abbrevs to see the shortcuts for each word.

(defcustom tacl-user-keywords '("_debugger" "_execute")
  "Words in this list are highlighted using font-lock-type-face.
   Additionally, the words are merged into the tacl-mode-abbrev-table where 
   abbreviations are generated for them.  Note that abbrev, for some reason,
   refuses to auto-expand words containing capital letters."
  :type '(repeat (string :tag "Keyword"))
  :group 'tacl
)
(defvar tacl-keywords-var-types
  '( "ALIAS" "DELTA" "DIRECTORY" "MACRO" "ROUTINE" "STRUCT" "TEXT")
  "List of TACL variable types.
   Used to create the font-lock-keywords table & abbrev-table."
)
(defvar tacl-keywords-directives
  '( "BLANK" "FORMAT" "SECTION" "TACL")
  "List of TACL #informat interpreter directives.
   Used to create the font-lock-keywords table & abbrev-table."
)
(defvar tacl-keywords-builtin-vars 
  '( "#assign"               "#breakmode"             "#characterrules"
     "#defaults"             "#definemode"            "#errornumbers"
     "#exit"                 "#helpkey"               "#highpin"
     "#home"                 "#in"                    "#informat"
     "#inlineecho"           "#inlineout"             "#inlineprefix"
     "#inlineprocess"        "#inlineto"              "#inputeof"
     "#inspect"              "#myterm"                "#out"
     "#outformat"            "#param"                 "#pmsearchlist"
     "#pmsg"                 "#prefix"                "#processfilesecurity"
     "#prompt"               "#replyprefix"           "#routepmsg"
     "#shiftdefault"         "#taclsecurity"          "#trace"
     "#uselist"              "#wakeup"                "#width"
   )
  "List of TACL Builtin variables.
   Used to create the font-lock-keywords table & abbrev-table."
)
(defvar tacl-keywords-builtin-fcns
  '( "#abend"                "#aborttransaction"      "#activateprocess"
     "#adddsttransition"     "#alterpriority"         "#append"
     "#appendv"              "#argument"              "#backupcpu"
     "#begintransaction"     "#breakpoint"            "#builtins"
     "#case"                 "#changeuser"            "#charaddr"
     "#charbreak"            "#charcount"             "#chardel"
     "#charfind"             "#charfindr"             "#charfindrv"
     "#charfindv"            "#charget"               "#chargetv"
     "#charins"              "#charinsv"              "#coldloadtacl"
     "#comparev"             "#compute"               "#computejuliandayno"
     "#computetimestamp"     "#computetransid"        "#contime"
     "#convertphandle"       "#convertprocesstime"    "#converttimestamp"
     "#createfile"           "#createprocessname"     "#createremotename"
     "#debugprocess"         "#def"                   "#defineadd"
     "#definedelete"         "#definedeleteall"       "#defineinfo"
     "#definenames"          "#definenextname"        "#definereadattr"
     "#definerestore"        "#definerestorework"     "#definesave"
     "#definesavework"       "#definesetattr"         "#definesetlike"
     "#definevalidatework"   "#delay"                 "#delta"
     "#deviceinfo"           "#empty"                 "#emptyv"
     "#emsaddsubject"        "#emsaddsubjectv"        "#emsget"
     "#emsgetv"              "#emsinit"               "#emsinitv"
     "#emstext"              "#emstextv"              "#endoftacllocl"
     "#endtransaction"       "#eof"                   "#errortext"
     "#exception"            "#extract"               "#extractv"
     "#filegetlockinfo"      "#fileinfo"              "#filenames"
     "#filter"               "#frame"                 "#getconfiguration"
     "#getprocessstate"      "#getscan"               "#history"
     "#if"                   "#initterm"              "#inlineeof"
     "#input"                "#inputv"                "#interactive"
     "#interpretjuliandayno" "#interprettimestamp"    "#interprettransid"
     "#juliantimestamp"      "#keep"                  "#keys"
     "#lineaddr"             "#linebreak"             "#linecount"
     "#linedel"              "#linefind"              "#linefindr"
     "#linefindrv"           "#linefindv"             "#lineget"
     "#linegetv"             "#lineins"               "#lineinsv"
     "#linejoin"             "#load"                  "#lockinfo"
     "#logoff"               "#lookupprocess"         "#loop"
     "#match"                "#mom"                   "#more"
     "#mygmom"               "#mypid"                 "#mysystem"
     "#newprocess"           "#nextfilename"          "#openinfo"
     "#output"               "#outputv"               "#pause"
     "#pop"                  "#process"               "#processexists"
     "#processinfo"          "#processlaunch"         "#processorstatus"
     "#processortype"        "#purge"                 "#push"
     "#raise"                "#rename"                "#reply"
     "#replyv"               "#requester"             "#reset"
     "#rest"                 "#result"                "#return"
     "#routinename"          "#segment"               "#segmentconvert"
     "#segmentinfo"          "#segmentversion"        "#server"
     "#set"                  "#setbytes"              "#setconfiguration"
     "#setmany"              "#setprocessstate"       "#setscan"
     "#setsystemclock"       "#setv"                  "#shiftstring"
     "#sort"                 "#spiformatclose"        "#ssget"
     "#ssgetv"               "#ssinit"                "#ssmove"
     "#ssnull"               "#ssput"                 "#ssputv"
     "#stop"                 "#suspendprocess"        "#switch"
     "#system"               "#systemname"            "#systemnumber"
     "#tacloperation"        "#taclversion"           "#timestamp"
     "#tosversion"           "#unframe"               "#userid"
     "#username"             "#variableinfo"          "#variables"
     "#variablesv"           "#wait"                  "#xfileinfo"
     "#xfilenames"           "#xfiles"                "#xlogon"
     "#xppd"                 "#xstatus"
   )
  "List of TACL Builtin functions.
   Used to create the font-lock-keywords table & abbrev-table."
)
(defvar tacl-keywords-argument-types
  '( "ASSIGN"           "ATTRIBUTENAME"   "ATTRIBUTEVALUE"  "CHARACTERS" 
     "CLOSEPAREN"       "COMMA"           "DEFINENAME"      "DEFINETEMPLATE" 
     "DEVICE"           "END"             "FILENAME"        "GMOMJOBID" 
     "JOBID"            "KEYWORD"         "NUMBER"          "OPENPAREN" 
     "OTHERWISE"        "PARAM"           "PARAMVALUE"      "PROCESSID" 
     "PROCESSNAME"      "SECURITY"        "SEMICOLON"       "SLASH"
     "STRING"           "SUBSYSTEM"       "SUBVOL"          "SUBVOLTEMPLATE" 
     "TEMPLATE"         "TEXT"            "TOKEN"           "TRANSID" 
     "USER"             "VARIABLE"        "WORD" 
   )
  "List of TACL #argument 'type' keywords.
   Used to create the font-lock-keywords table & abbrev-table."
)
(defvar tacl-keywords-option-verbs
  '( "PEEK"         "TEXT"         "VALUE"        "START"        "WIDTH" 
     "SEARCHLIST"   "SYNTAX"       "WORDLIST"     "MINIMUM"      "MAXIMUM" 
     "TOKEN"        "ALLOW"        "FORBID"       "QUALIFIED"    "UNQUALIFIED"
     "SPACE" 
   )
  "List of TACL verbs allowed within /slash/ marks of builtins.
   Used to create the font-lock-keywords table & abbrev-table.
   This doesn't include #fileinfo/<keywords>/ at the moment."
)
(defvar tacl-keywords-enclosed
  '( "THEN"         "ELSE"         "DO"           "UNTIL"        "OTHERWISE"
     "BODY"         "WHILE"
   )
  "List of TACL verbs used within |v-bars| marks of select builtins.
   Used to create the font-lock-keywords table & abbrev-table."
)

;;; Abbrev stuff

(defcustom tacl-abbrev-mode t
  "Sets the default value for abbrev-mode in TACL mode.
   Note that this does not turn abbrev-mode on or off it simply determines
   the state of the `abbrev-mode' variable when TACL mode is entered."
  :type 'boolean
  :group 'tacl
)
(defun tacl-make-abbrev-table-list (&rest wordlists)
  "This function converts wordlist(s) to a list of abbrev table entries.
   All wordlists passed to this function are concatinated and sorted.
   This function returns a list of the form ((abbrev expansion)...) . 
   The abbrev portion is the minimum number of characters necessary
   to identify the word uniquely among all words in the list.
   Duplicate words effectively squelch AUTO abbrev of a word"
  (let ((mixed-words)
        (all-words)
        (result)
        (prev-match 0))
    (while wordlists
      (setq all-words (append all-words (car wordlists) nil))
      (setq wordlists (cdr wordlists))
    )
    (setq all-words (sort all-words 'string<))
    (while all-words
      (let*((this (car all-words))
	    (this-len (length this))
	    (next (car (cdr all-words)))
	    (next-len (length next))
	    (len (if (< this-len next-len) this-len next-len ))
	    (cntr 0)
	    (this-match)
	   ) ;let variable definitions
	(while (and (< cntr len)     ;Find 1st non-matching char
		    (= (aref this cntr) (aref next cntr))
	       )                     ;Isn't there a primitive for this?
	  (setq cntr (1+ cntr))
	) ; while this = next
	(setq this-match (if (> cntr prev-match) cntr prev-match))
	(setq prev-match cntr)
	(if (< this-match this-len)(setq this-match (1+ this-match)))
	(setq result (append result (list (list 
			   (substring this 0 this-match) this))))
	(setq all-words (cdr all-words))
      ) ;while's let
    ) ;while all-words
    result
  ) ; let
)
(defvar tacl-mode-abbrev-table-list
  (tacl-make-abbrev-table-list
   tacl-keywords-builtin-fcns
   tacl-keywords-builtin-vars
   tacl-keywords-directives
   tacl-keywords-option-verbs
   tacl-keywords-argument-types
   tacl-keywords-var-types
   tacl-user-keywords
;;;   tacl-keywords-squelch-abbrev
  )
  "Abbreviations for many common TACL Builtin commands"
)
(defvar tacl-mode-abbrev-table)
(defun tacl-setup-abbrevs ()
  "Installs the tacl-mode-abbrev-table as local-abbrev-table"
  (define-abbrev-table 'tacl-mode-abbrev-table tacl-mode-abbrev-table-list)
  (setq local-abbrev-table tacl-mode-abbrev-table)
  (setq abbrev-mode tacl-abbrev-mode)
)

;;; Font lock (highlighting)

(defcustom tacl-font-lock-always t
  "If true, TACL-MODE will always turn `font-lock-mode' on even if 
`global-font-lock-mode' is off.  nil disables this feature."
  :type 'boolean
  :group 'tacl
)
(defvar tacl-column-marker-face 'tacl-column-marker-face)
(defface tacl-column-marker-face
  '((t (:background "grey")))
  "Used for marking column 79 (or whatever)."
  :group 'tacl
  :group 'faces
)
(defcustom tacl-column-marker-1 0
  "When not zero, this column is font-lock'ed to tacl-column-marker-face.
   The value of this must be zero or less than tacl-column-marker-2.
   Setting this to zero turns off the column marker.  This column marker
   is useful for columnizing things or when working in languages like COBOL
   where a particular column has significance."
  :type 'integer
  :group 'tacl
)
(defcustom tacl-column-marker-2 79
  "When not zero, this column is font-lock'ed to tacl-column-marker-face.
   Setting this to zero turns off the column marker.  This column marker
   is useful for columnizing things or when working in languages like COBOL
   where a particular column has significance."
  :type 'integer
  :group 'tacl
)
(defcustom tacl-primecode-warning t
  "When not nil, instances of ]a ]d and ]e appearing in column 1-2 are
highlighted with a warning face.  This alerts you that submission of this file
to RMS/PrimeCode will fail due to invalid contents."
  :type 'boolean
  :group 'tacl
)
(defun tacl-keyword-anywhere-regexp ( word-list )
  "Returns a regexp that finds the words passed.
   But only if the keyword is surrounded by non-word chars."
  (concat "\\<"(regexp-opt word-list t)"\\>")
)
(defun tacl-keyword-directives-regexp ( word-list )
  "Returns a regexp that finds ?directives."
  (concat "^\\?"(regexp-opt word-list t)"\\>")
)
(defun tacl-keyword-between-bars-regexp ( word-list )
  "Returns a regexp that finds the words passed alone between | |."
  (concat "|\\s-*"(regexp-opt word-list t)"\\s-*|")
)
(defun tacl-keyword-vartype-regexp ( word-list )
  "Returns a regexp that finds the words after ?section or #def syntax."
  (concat "\\[#def +\\S-+ +"(regexp-opt word-list t)"\\b")
)
(defvar tacl-keyword-between-slashes-regexp () "internal use only")
(defun  tacl-keyword-between-slashes-regexp ( word-list )
  "Returns a function that finds the words passed only if between /  /."
  (setq tacl-keyword-between-slashes-regexp 
	(concat "\\b"(regexp-opt word-list t)"\\b"))
  'tacl-font-lock-between-slashes
)
(defvar tacl-amid-font-lock-excursion nil
  "Used by `tacl-font-lock-between-slashes'.
   When a pair of slashes are detected this variable holds the context
   needed to continue searching for more keywords.  If nil, slash marks
   should be searched for."
)
(make-variable-buffer-local 'tacl-amid-font-lock-excursion)
(defun tacl-font-lock-between-slashes ( search-limit )
  "This function finds keywords between forward slash marks only.
   Valid keywords are described by tacl-keyword-between-slashes-regexp.
   First a line containing text between forward slashes is searched for.
   Once found, point is moved to the beginning of that area and limit
   is set to the end.  Keywords are searched for within that range.
   If found, context is saved in tacl-amid-font-lock-excursion and the 
   match-data is returned.  If not found, another set of slash marks
   is searched for.  If saved context exists when this function is 
   called then another keyword is searched for between the previously
   found slashes.  If none is found, more /.../ syntax is searched for."
  (let ((looking t))
    (while 
	(and looking
	     (or tacl-amid-font-lock-excursion
		 (when (re-search-forward "/.+/" search-limit t)
		   (setq tacl-amid-font-lock-excursion (point))
		   (goto-char (match-beginning 0))
	)    )   )
      (if (re-search-forward tacl-keyword-between-slashes-regexp
			     tacl-amid-font-lock-excursion t)
	  (setq looking nil)
	(goto-char tacl-amid-font-lock-excursion)
	(setq tacl-amid-font-lock-excursion nil)
      ) 
    )
    (not looking)
  )
)
(defvar tacl-font-lock-keywords
  ; font-lock-keywords is a symbol or list of symbols yielding the keywords to
  ; be fontified.  Keywords are listed here using either (MATCHER . FACENAME)
  ; or (MATCHER . (MATCH FACENAME)) syntax.  Other options are available but
  ; not used here.  For simplicity, all regexp's were designed so MATCH would
  ; be 1.  Nothing forced this but to me it makes debug/maintenance easier.
  `((,(tacl-keyword-anywhere-regexp tacl-keywords-builtin-fcns)  
     1 font-lock-keyword-face)
    (,(tacl-keyword-anywhere-regexp tacl-keywords-builtin-vars)  
     1 font-lock-builtin-face)
    (,(tacl-keyword-vartype-regexp tacl-keywords-var-types)
     1 font-lock-builtin-face)
    (,(tacl-keyword-directives-regexp tacl-keywords-directives)
     1 font-lock-warning-face)
    (,(tacl-keyword-between-slashes-regexp tacl-keywords-option-verbs) 
     1 font-lock-constant-face)
    (,(tacl-keyword-anywhere-regexp tacl-user-keywords)
     1 font-lock-type-face)
    (,(tacl-keyword-between-bars-regexp tacl-keywords-enclosed)
     1 font-lock-constant-face)
    ("`\\(\\sw\\sw+\\)'" 1 font-lock-constant-face prepend)
    ,@(when (> tacl-column-marker-1 0)
        (list (list (format "^.\\{%d\\}\\(.\\)" tacl-column-marker-1)
                    1 tacl-column-marker-face 'prepend t)))
    ,@(when (> tacl-column-marker-2 0)
        (list (list (format "^.\\{%d\\}\\(.\\)" tacl-column-marker-2)
                    1 tacl-column-marker-face 'prepend t)))
    ,@(when tacl-primecode-warning
        ;; ]a  ]d or ]e cannot appear in col 1-2 if using RMS/PrimeCode.
        (list '("^\\][ade]" . font-lock-warning-face)))
    ;; The question mark must be followed by a directive or another ?.
    ("^\\(\\?\\)[^?]" (1 font-lock-warning-face nil t))
  )
  "Keyword highlighting specification for `tacl-mode'."
)
(defun tacl-setup-font-lock ()
  "Sets up the buffer local value for font-lock-defaults and optionally
turns on font-lock-mode"
  ; Column markers work by counting characters in the line.  Tabs throw the
  ; count off and won't highlight the char in the correct column.  If there
  ; are already tabs the column marker will look wierd but I'm not going to
  ; mess with the users buffer unexpectedly by converting them.
  (when (or (/= tacl-column-marker-1 0)
            (/= tacl-column-marker-2 0) )
    (setq indent-tabs-mode nil)      ;documented as buffer local
  )
  ; This is where all the font-lock stuff actually gets set up.  Once
  ; font-lock-defaults has it's value, setting font-lock-mode true should
  ; cause all your syntax highlighting dreams to come true.
  (set (make-local-variable 'font-lock-defaults)
       '(tacl-font-lock-keywords nil t nil)
  )
  (set (make-local-variable 'font-lock-defaults)
         ; The first value is all the keyword expressions.
       '(tacl-font-lock-keywords
         ; keywords-only means no strings or comments get fontified
         nil
         ; case-fold (ignore case) 
         t
         ; syntax-alist AFAIK nothing needs different syntax for font-lock
         ()
         ; syntax-begin - no function defined to move outside syntactic block
         nil
       )
  )
  ; font lock is turned on by default in this mode. Use customize to disable.
  (when tacl-font-lock-always (font-lock-mode t))
)

;;; Imenu

(defcustom tacl-imenu-menubar nil
  "If not nil, `imenu-add-to-menubar' is called during mode initialization.
This adds a [Menu name] menu to your menu bar.  By default the menu contains a
list of all procedures, sections and pages in your program.  You can go
directly to any item on the menu by selecting it.  You can control what
appears on this menu by modifying `tacl-imenu-expression-alist'.  You must turn
imenu on for this to work.  See `imenu' in the Emacs reference manual for more
information.  Personally I recommend customizing `imenu-sort-function' to sort
by name."
  :type  '(choice :tag "Menu Name" (string :tag "Menu Name") (const nil))
  :group 'tacl
)
(defvar tacl-imenu-syntax-alist '((":"."w"))
  "Overrides to tacl-mode-syntax-table used during
imenu-generic-expression search."
)
(defcustom tacl-imenu-expression-alist
  `((nil ,(concat "^\\?SECTION +\\(\\w+\\s-+"
		     (regexp-opt tacl-keywords-var-types t)
		     "\\)\\b") 1)
    (nil ,(concat "^ \\{0,2\\}\\[#def\\s-+\\(\\w+\\s-+"
		     (regexp-opt tacl-keywords-var-types t)
		     "\\)\\b") 1)
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
  :group 'tacl
)
(defcustom tacl-display-which-function t
  "This option depends on `imenu'.  Displays current proc on mode line.
`Which-func' is a package that causes the current function, section or page
to be displayed on the mode line.  Each imenu entry points to a position
in the current buffer.  The name associated with the greatest position
less than the current cursor point is what is displayed on the mode
line. See `tacl-imenu-expression-alist' for more information."
  :type 'boolean
  :group 'tacl
)
(defun tacl-setup-imenu ()
  "Installs tacl-imenu-generic-expression & tacl-imenu-syntax-alist."
  ; imenu doc says all 3 are buffer-local by default
  (setq imenu-generic-expression tacl-imenu-expression-alist)
  (setq imenu-syntax-alist tacl-imenu-syntax-alist)
  (setq imenu-case-fold-search t)
  (when tacl-imenu-menubar
    (if (condition-case ()
            (progn (require 'imenu) t)
          (error nil))
        (imenu-add-menubar-index)
      (message "tal-imenu-menubar set but imenu feature not available.")
    )
  )
  (when tacl-display-which-function
    (if (condition-case ()
            (progn (require 'which-func) t)
          (error nil))
        (which-function-mode t)
      (message "tal-display-which-function set but which-func not available")
    )
  )
)

 ;;; Adaptive fill

(defun tacl-setup-adaptive-fill ()
  "Sets up the TACL-MODE adaptive-fill variables"
  (set (make-local-variable 'comment-start) "{")
  (set (make-local-variable 'comment-end) " }")
   (set (make-local-variable 'comment-start-skip) "\\(==\\|{\\)\\s-*")
)

;;; Indentation
   
(defun tacl-indent-line ()
  "Indent current line of Tacl code. - work in progress don't use"
  (interactive)
  (let ((savep (> (current-column) (current-indentation)))
	(indent (condition-case nil (max (tacl-calculate-indentation) 0)
		  (error 0))))
    (if savep
	(save-excursion ;;;(indent-line-to indent))
          (indent-relative-maybe))
      (indent-relative-maybe)
;;;      (indent-line-to indent)
    )  )
)

(defun tacl-calculate-indentation ()
  "Return appropriate indentation for current line as TACL code.
   In usual case returns an integer: the column to indent to.
   If the value is nil, that means don't change the indentation
   because the line starts inside a string."
  4     ; some day, hopefully soon
)


;;; Language Skeletons -- Feel free to add more of your own!

(defcustom tacl-keywords-case 'camel
  "*Indicates if keywords in skeletons should be all UPPER CASE, all
lower case or Camel Case (First Char Upper & Rest Lower)."
  :type  '(choice (const :tag "ALL CAPS"   'upper)
                  (const :tag "all small"  'lower)
                  (const :tag "Camel Case" 'camel))
  :group 'tacl
)
(defun tacl-skel-transform ( element )
  "Used to insure skeleton's are inserted using the requested capitalization."
  (if (stringp element)
    (cond
     ((eq tacl-keywords-case 'upper) (upcase element))
     ((eq tacl-keywords-case 'lower) (downcase element))
     ( t                             (capitalize element))
    )
    element
  )
)
(define-skeleton tacl-if-skel
  "Inserts a standard TACL if/then statement skeleton."
  nil "[IF (" _ ")"
      \n > "  |THEN|" _ "  "
      \n > -2 "]"
)
(define-skeleton tacl-if-else-skel 
  "Inserts a standard TACL #if|then| statement skeleton."
  nil "[IF (" _ ")"
       \n > "  |THEN|" _
       \n >   "|ELSE|" _ "  "
       \n > -2 "]"
)
(define-skeleton tacl-case-skel 
  "Inserts a standard TACL Case -> statement skeleton."
  nil "[CASE " _ 
      \n > "  |" _ " |" _
      \n >   "|OTHERWISE|" _ "  "
      \n > -2 "]"
)

;;; Movement by ...

;(defvar tacl-outline-regexp
;...)

;;;###autoload
(defun tacl-mode ()
  "A major mode for editing TACL language files.
Customization options are available via
M-x customize-group <ret> TACL <ret>

This mode provides TACL specific support for the following packages:
    `font-lock-mode'            `show-paren-mode'
    `imenu'                     `which-function'
    `skeleton-insert'           `auto-fill-mode'
    `adaptive-fill-mode'        `abbrev-mode'

It also implements the following commands  M-x ... commands

tacl-mode          activates this mode for the current buffer
tacl-case-skel     inserts a labeled case statement skeleton
tacl-if-skel       inserts an if/then statement skeleton
tacl-if-else-skel  inserts an if/then/else statement skeleton

Use  C-h b  to see key bindings.  
"
  (interactive)
  (kill-all-local-variables)
  (set (make-local-variable 'major-mode) 'tacl-mode)
  (set (make-local-variable 'mode-name) "TACL")
  (set (make-local-variable 'make-backup-files) nil) ;necessary for now
  (use-local-map tacl-mode-map)
  (set-syntax-table tacl-mode-syntax-table)
  (tacl-setup-font-lock)
  (tacl-setup-adaptive-fill)
  (tacl-setup-abbrevs)
  (tacl-setup-imenu)
  (set (make-local-variable 'indent-line-function) 'indent-relative-maybe)
  (set (make-local-variable 'skeleton-transformation) 'tacl-skel-transform)
;  (set (make-local-variable 'outline-regexp) tacl-outline-regexp)
  (show-paren-mode 1)
  (run-hooks 'tacl-mode-hook)
)

(provide 'tacl-mode)

;;; tacl-mode.el ends here.