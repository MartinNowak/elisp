;; coding: mule-utf-8-unix
;; filedb.el --- Database of filetypes and their File-Names, File-Formats,l
;; Properties, Available Operations, and other Metadata, etc. Replaces the
;; libraries `run-assoc' etc.

;; Author: Per Nordlöw.
;; Ref: http://www.garykessler.net/library/file_sigs.html. TODO: Add more from this source.

;; todo: Integrate with `magic-mode-alist' entries
;; See: ~/matlab/extern/examples/mex
;; See: http://www.mathworks.com/help/techdoc/ref/mex.html
;; See: http://www.gnu.org/software/octave/doc/interpreter/Getting-Started-with-Mex_002dFiles.html
;; See: http://www.obihiro.ac.jp/~suzukim/masuda/octave/html3/octave_195.html

;; See: TrID - File Identifier: http://mark0.net/soft-trid-e.html

;; TODO: (add-to-list 'revert-without-query "tags" "TAGS") for all Uneditable files

;; TODO: Integrate `completion-ignored-extensions'.

;; TODO: Register files of types and add some of them as Uneditable .\#\* \*\~ \*.bin \*.lbin \*.so \*.a \*.ln \*.blg \*.bbl \*.elc \*.lof \*.glo \*.idx \*.lot \*.fmt \*.tfm \*.class \*.fas \*.lib \*.mem \*.x86f \*.sparcf \*.dfsl \*.pfsl \*.d64fsl \*.p64fsl \*.lx64fsl \*.lx32fsl \*.dx64fsl \*.dx32fsl \*.fx64fsl \*.fx32fsl \*.sx64fsl \*.sx32fsl \*.wx64fsl \*.wx32fsl \*.fasl \*.ufsl \*.fsl \*.dxl \*.lo \*.la \*.gmo \*.mo \*.toc \*.aux \*.cp \*.fn \*.ky \*.pg \*.tp \*.vr \*.cps \*.fns \*.kys \*.pgs \*.tps \*.vrs \*.pyo

;; TODO: Merge in file types and presentations from dired-filetype-face.el
;; TODO: Import configs from quickrun.el
;; TODO: Integrate all patterns relangs.el
;; TODO: Add :import-pattern
;; C/C++: (lambda (x) (rx-to-string "#include" (| "<$X>" "\"$X\"")))
;; Haskell: (lambda (x &optional y) (rx-to-string "import" x "as" y))
;; VHDL: (lambda (x) (rx "import" " " x))

;; FIXME: This return '(C-Source) and not nil: (file-match-key-or-keylist-cached "~/g.c" 'C-Source nil 'name-or-contents-recog)
;; FIXME: This return '(C-Source) and not t: (fmd-match-uncached "~/g.c" 'C-Source 'name-recog)

;; FIXME: (file-match-cached "/bin/ls" t nil) should return `Uneditable'
;; along with `ELF' like (file-match-cached "/bin/ls" t nil t) does.

;; TODO: (fmd-expr-from-symbol 'Some-Strange-Key)

;; TODO: What to do about non-existing files in this case?
;; This errors: (file-match "/bin/ls" 'GUD-Debuggable) => nil
;; This errors: (file-match "/bin/nobody" 'GUD-Debuggable) => nil
;; This errors: (file-match-cached "/bin/nobody") => nil
;; This errors: (file-match-cached "/bin/nobody" t) errors

;; TODO: Define :relations/:related matcher.
;; - emacs-lisp-mode: $X.elc depends on $X.el
;; - sh-mode: "source $X"
;; - c-common-mode: #include "X", #include <X>
;; Use in file
;; - delete (`delete-buffer-and-maybe-file', `dired-delete-file')
;; - rename/move (`rename-buffer-and-maybe-file'). Reuse functions `rename-refs' and rename-.* in cc-assist.el
;; - copy
;; TScan Optionally Supports Display:
;; - "References"
;; - "Referenced by"

;; TODO: See filedb-TODO.org

;; TODO: Checksums: moserial-2.30.0.X where X can be either: md5sum sha1sum sha256sum
;; e0a71d54b239ed7f0dee50d745c05658c800ae51de342d827f6e3edc7a9c2646  moserial-2.30.0.tar.bz2
;; 6c6d45ae78c3026f1b72e05f193d55e67221e17dce2cf84c3c315f817bf6ffd7  moserial-2.30.0.tar.gz

;; TODO: Doesn't (file-match-keys-all "/bin/ls" '(Java Pascal) '(C C++ Java) nil t) => (Java)

;; TODO: Matcher for C/C++/Objective-C Dep file.

;; TODO: `file-compressed-p' does not work. Fix.
;;       - 1. (file-match "/usr/share/info/gzip.info.gz" 'GNU-zip)
;;       - 2. (fmd-compressed-p "/usr/share/info/gzip.info.gz" 'GNU-zip)
;;       EDebug cscan functions. What decoding is used and what does the buffer contain?

;; TODO: Reuse package executable.el.
;; TODO: When doing or-matching (or KEYS), used in discardals such as `file-uneditable-regular-p' sort on
;; 1. RECOG:
;;    1. name-and-contents:
;;    1. name-or-contents:
;;    2. contents
;;    3. name
;; We may need to have a `respect-order-flag' if we want to match them in a specific order.
;; Check performance improvement using uneditable.

;; TODO: Add support for :build and :execute and running Matlab and Octave Extensions written in C/C++:
;; - Octave Oct: shell: mkoctfile file
;; - Octave Mex: shell: mkoctfile --mex file
;; - Matlab: shell: mex file
;; - Octave/Matlab: mex file
;; - Octave/Matlab: mexext file
;;
;; TODO: Merge with dired-filetype-face.el
;; TODO: Reuse `string-list-to-regexp' in `combinations.el' in construction of name and content matchers.
;; TODO: Auto-detect paths in .list
;; TODO: Support .jigdo and .zsync .manifest and .template
;;       Examples in directory: http://cdimage.ubuntu.com/dvd/current/
;; TODO: Use filedb-magic to display a more descriptive buffer-file explanation in mode-line.

(eval-when-compile (require 'cl))
(require 'rx)
(require 'file-utils)
(require 'file-execute)
(require 'power-utils)
(require 'obarray-utils)
(require 'pnw-regexps)
(require 'cscan)
(require 'combinations)
(require 'file-magic)
(require 'cc-patterns)
(require 'chain-predicates)
(require 'fcache)
(require 'elk-test)
(require 'auto-build)
(require 'tags-update)
(require 'wact)

(defun open-office ()
  (or (executable-find "loffice")
      (executable-find "soffice")))
(defun open-writer ()
  (or (executable-find "lowriter")
      (executable-find "oowriter")))
(defun open-calc ()
  (or (executable-find "localc")
      (executable-find "oocalc")))
(defun open-impress ()
  (or (executable-find "loimpress")
      (executable-find "ooimpress")))

;; TODO: Reuse filedb registry logic.
(defun file-productions (filename)
  "Return list of files generated from FILENAME."
  (let* ((bare-old (file-name-sans-extension filename)))
    (cond
     ((file-match filename 'Emacs-Lisp 'name-recog)
      (list (concat bare-old ".elc")))
     ((file-match filename 'Python 'name-recog)
      (list (concat bare-old ".pyc")))
     ((file-match filename 'Java 'name-recog)
      (list (concat bare-old ".javac")))
     ((file-match filename '(C C++ Objective-C Ada-Body) 'name-recog)
      (let ((l (list
                (let ((obj (concat bare-old ".o"))) ;Object File
                  (when (file-elf-p obj nil nil t)
                    obj)
                  )
                (let ((obj (concat bare-old ".ko"))) ;Kernel Object
                  (when (file-elf-p obj nil nil t)
                    obj)
                  )
                (let ((obj (concat bare-old ".out")))
                  (when (file-elf-p obj nil nil t)
                    obj)
                  ))))
        (setq l (delete nil l)))))))
;; Use: (file-productions (elsub "mine/pnw-dot-emacs.el")
;; Use: (file-productions "~/cognia/semnet/alt.cpp")

(when nil
  (with-temp-buffer
    ;; TODO: Merge with (set-buffer (get-buffer-create "*magic.ttn-do-magic*"))
    (insert-file-contents-literally (elsub "magic/magic.ttn-do-magic"))
    (goto-char (point-min))
    (forward-line 3)
    (setq magic-list nil)
    (while (ignore-errors (re-search-forward "^\\((0 0 .*)\\)$"))
      (setq magic-list (cons (match-string-no-properties 1) magic-list))))
  )

(defgroup filedb nil
  "Emacs File DB (filedb) configuration."
  :prefix "fmd-"
  :group 'tools)

;; TODO: Use Shorter: n-recog e-recog c-recog nac-recog noc-recog;
(defvar fmd-recogs
  (list
   '("Name" name-recog)  ;Recognize File Type solely through its @em name.
   '("Exist" exist-recog) ;Recognize File Type through its name and @em presence on file system.
   '("Contents" contents-recog) ;Recognize File Type by through its @em contents.
   '("Name or Contents" name-or-contents-recog)
   '("Name and Contents" name-and-contents-recog)
   '("Default" nil) ;Note: Use Preferred Recognition Type defined by `fmd-types' entry.
   )
  "Types of File Recognitions used by filedb.")

(defun fmd-read-recog ()
  "Read File Recognition Type from minibuffer."
  (assoc
   (completing-read "File Recognition Type: " fmd-recogs nil t nil nil "Name")
   fmd-recogs))
;; Use: (cadr (fmd-read-recog))

;; ---------------------------------------------------------------------------

;; ToDo: Note: How can we make this work for byte-compiled functions?
(defun symbol-function-expression (symbol)
  "Return the expression part of symbol's function definition.
Error if that is void."
  (let ((fun (symbol-function symbol)))
    (if (stringp (nth 2 fun))
        (nth 3 fun)
      (nth 2 fun))))
;; Use: (ignore-errors (symbol-function-expression 'file-gnu-global-directory-p)) => nil

;; ---------------------------------------------------------------------------

(defvar mplayer-command "mplayer -ao pulse -vo vdpau"
  "MPlayer Shell Command.")

;; ---------------------------------------------------------------------------

(defconst ectags-magic
  "!_TAG_FILE_FORMAT	2	/extended format; --format=1 will not append ;"
  )

;; ---------------------------------------------------------------------------

;; Semantic Tag Style Accessing of Attributes
(defsubst ftype-key (ftype) "Get KEY part of FTYPE." (aref ftype 0))
(defsubst ftype-name/doc (ftype) "Get Name/Doc of FTYPE."
  (let ((name (aref ftype 1)))
    (or (car-safe name)                 ;if name is a list pick its first
        name)))                         ;otherwise just pick name
(defsubst ftype-category (ftype) "Get Category of FTYPE." (aref ftype 2))

(defsubst ftype-ptype (ftype) "Get Pattern Type of FTYPE." (aref ftype 3))

(defsubst ftype-match (ftype) "Get Matcher of FTYPE." (aref ftype 4))
(defsubst ftype-nmatch (ftype) "Get Name Matcher of FTYPE." (plist-get (ftype-match ftype) :name))
(defsubst ftype-cmatch (ftype) "Get Contents Matcher of FTYPE." (plist-get (ftype-match ftype) :contents))
(defsubst ftype-rmatch (ftype) "Get Reference Matcher of FTYPE." (plist-get (ftype-match ftype) :refs))
(defsubst ftype-precog (ftype) "Get Preferred Recognition of FTYPE." (plist-get (ftype-match ftype) :precog))
(defsubst ftype-attributes (ftype) "Get Attributes of FTYPE." (plist-get (ftype-match ftype) :attributes))
(defsubst ftype-mime (ftype) "Get MIME of FTYPE." (plist-get (ftype-match ftype) :mime))
(defsubst ftype-drecog (ftype) "Get Default Recognition of FTYPE."
  (cond ((and (ftype-nmatch ftype)
              (ftype-cmatch ftype))
         'name-and-contents-recog)
        ((ftype-nmatch ftype)
         'name-recog)
        ((ftype-cmatch ftype)
         'contents-recog)
        (t
         (message "Warning: Filetype ftype %s has no name nor contents matcher." (faze ftype 'type))
         'exist-recog)
        ))

;;; TODO: Sort on 1. FTYPE, 2. RECOG, if precog are both `name-recog' put `lit' before `re'
(defun ftype-simplicity-rank (ftype)
  "Get Recognition Rank of FTYPE."
  (let ((precog (or (ftype-precog ftype) ;if given
                    (ftype-drecog ftype)
                    )))
    ;; Note: fastest first
    (cond ((eq precog 'name-recog) 0)
          ((eq precog 'name-or-contents-recog) 1)
          ((eq precog 'name-and-contents-recog) 2)
          ((eq precog 'exist-recog) 3)
          ((eq precog 'contents-recog) 4)
          (t 5)
          )))
(defun ftype-simplicity-rank-lessp (t1 t2)
  (< (ftype-simplicity-rank t1)
     (ftype-simplicity-rank t2)))
(defun ftype-key-precog-rank-lessp (k1 k2)
  (ftype-simplicity-rank-lessp (fmd-get-type k1)
                               (fmd-get-type k2)))
;; Use: (ftype-key-precog-rank-lessp 'S-Lang 'JavaScript)

(defsubst ftype-mode (ftype) "Get Mode of FTYPE." (aref ftype 5))
(defsubst ftype-creation (ftype) "Get Creation of FTYPE." (aref ftype 6))
(defsubst ftype-ops (ftype) "Get Operations of FTYPE." (when (>= (length ftype) 8) ;range checked aref
                                                         (aref ftype 7)))

(defsubst fmatch-fmt (m) "Get Format (FMT) of matcher M." (car m))
(defsubst fmatch-val (m) "Get Value (VAL) of matcher M." (cadr m))
(defsubst fmatch-ctx (m) "Get (Syntactic) Context (CTX) of matcher M." (nth 2 m))
(defsubst fmatch-casef (m) "Get Case Format of matcher M." (nth 3 m))
(defsubst fmatch-limit (m) "Get Limit of matcher M." (nth 4 m))
(defsubst fmatch-doc (m) "Get Documentation of matcher M." (nth 5 m))

(when nil
  (let ((ftype (fmd-get-type 'C-Header)))
    (list
     (ftype-key ftype)
     (ftype-category ftype)
     (ftype-ptype ftype)
     (ftype-nmatch ftype)
     (ftype-cmatch ftype)
     (ftype-precog ftype)
     (ftype-mode ftype)
     (ftype-creation ftype)
     (ftype-ops ftype)
     ))
  )

(defun file-debug-with-gdb (filename build-type compilation-window working-directory &optional args)
  (ignore-errors
    (let ((filename (expand-file-name filename))) ;NOTE: GDB needs this!
      (gdb (concat gud-gdb-command-name
                   " -q"                ;quiet
                   " -e " filename
                   ;; TODO: Fix this!
                   ;; " -ex run"
                   ;; (concat
                   ;;  " -ex 'run"
                   ;;  "'")
                   (when args
                     (concat " " (mapconcat 'identity args " ")))
                   " " filename
                   ))))
  (let ((io-buffer (ignore-errors (gdb-get-buffer-create 'gdb-inferior-io))))
    (when io-buffer
      (with-current-buffer io-buffer
        (erase-buffer))))
  (gdb-restore-windows)
  (when (and gud-comint-buffer
             (buffer-live-p gud-comint-buffer))
    (with-current-buffer gud-comint-buffer
      (eob)
      (unless (looking-back "run[[:space:]]*")
        (insert (concat "start")))
      (comint-send-input))))
;; Use: (file-debug-with-gdb "/bin/ls")

;; ---------------------------------------------------------------------------

(defcustom fmd-types nil
  "Database of file-types.

WARNING: IMPORTANT: A Name or Content Matcher must NOT be an
INVERTED matcher.  Example of such an inverted matcher could be:
\"all non-backup files\". Inverted Matchers are expressed using
standard lisp-sexps using not, and, or and lists of type class
key strings.

- List of File Type Entries. Each entry has the format:
    (KEY [NAME CATEGORY PTYPE MATCH MODE CREATION PROGS HITS])
    where MATCH is form (:name NMATCH :contents CMATCH :precog PRECOG :mime MIME)

- KEY: Key String used to index list usually with assoc()

- NAME: File Type Name

- CATEGORY: File Category Name

- PTYPE specifies the type of (files system) pattern. Can be
  either `file' (or `t'), `dir', `file-or-dir', `txt' for textual
  file, utf-8 textual UTF-8 encoded file, `bin' for binary file,
  `box' for container files (compressed or archive file) that
  should not be auto-unfolded nor auto-decompressed by Emacs's
  `auto-compression-mode' when matched, or nil for undefined.

- NMATCH: Name Pattern Matcher in the format (NFMT NVAL NCTX NCASEF NLIMIT).
  - NFMT: A Literal Symbol describing Name Matcher Format:
    - Literal String: `lit'
    - Regexp: `re'
    - Symbolic Regexp: `rx'. See: http://www.emacswiki.org/emacs/rx
  - NVAL: The Name Value as a string (regexp), list of strings (regexps) or function (lambda).
    - NVAL-TYPE: `any', `all'
  - NCTX: Name Context:
    - Anywhere: `any' which is the default if not given (nil)
    - Begin: `beg'
    - End: `end'
    - Extension: `ext', `ext'
    - Full (Complete/Exact): `full'
    - Position (Offset) (numberp). If negative means offset from file end: POS
    - Position (Offset) and Length: (POS LEN)
  - NCASEF: Case-Fold Name Match: t if case-fold search, nil if exact match.
  - NLIMIT: Name Matches Limit (Offset)

- CMATCH: Contents Pattern Matcher in the format (CFMT CVAL CCTX CCASEF CLIMIT CDOC)
  - CFMT: A literal describing Content Matcher Format:
    - Literal String: `lit'
    - Regexp: `re'
    - Symbolic Regexp: `rx'. See: http://www.emacswiki.org/emacs/rx
  - CVAL: Content Value as a string (regexp), list of strings (regexps) or function (lambda).
  - CCTX: Content Context:
    - Anywhere: `any'
    - Begin: `beg' which is the default if not given (nil)
    - End: `end'
    - Extension: `ext', `ext'
    - Full (Complete/Exact): `full'

    - Code (using `syntax-ppss'): `code'
    - Comment (using `syntax-ppss'): `comment'
    - String (using `syntax-ppss'): `string'

    - Symbol (\"\\_<\" \"\\_>\" in regexps) (in Source Code Language): `symbol'
    - Keyword (implies `code' and `symbol') (in Source Code Language): `keyword'
    - Include (in Source Code Language): `include'
    - Position (numberp): POS.
    - Region (cons of Position and Length) (list-of-numbers-p): (POS . LEN)
  - CCASEF: Case-Fold Contents Match: t if case-fold search, nil if exact match.
  - CLIMIT: Content Matches Limit (Offset)
  - CDOC: Content Matches Documentation (MATCH-DOC...) where each
    FMATCH-DOC is of the format (DOC-INDEX DOC-STRING). Same as
    file format (magic) properties. CDOC is a list of hits where
    each hit is a list whose car is the match result index to put
    into.

- PRECOG: Preferred Recognitioning: See `fmd-recogs' for details.

- MODE: Emacs Mode (if not defined we let Emacs try to detect it by opening file and use variable 'major-mode)

- CREATION: Creation Mechanism:
  - Manual: `man'
  - (Auto-)Generated: `gen'
  Normally means that we only want to edit manually (man) created files.

- PROGS: Property-List of programs that Read, Compile, Debug,
  Interpret, Modify, Write, etc files of this type.

- HITS: List of existing directories or files (strings) that are of this type.
"
  :type '(repeat
          (list :tag "Properties"
                (string :tag "Key (KEY)")
                (string :tag "Name (NAME)")
                (string :tag "Category (CATEGORY)")
                (choice :tag "File Class (PTYPE)"
                        (function-item :tag "File" :value file)
                        (function-item :tag "Directory" :value dir)
                        (function-item :tag "File or Directory" :value file-or-dir)
                        (function :tag "Your choice, take care...")
                        )
                (vector :tag "Name Matcher in the format [NFMT NVAL NCTX NCASEF]"
                        (choice :tag "Name Format (NFMT)"
                                (function-item :tag "Literal" :value lit)
                                (function-item :tag "Regexp" :value re)
                                (function-item :tag "Symbolic Regexp" :value rx)
                                )
                        (choice :tag "Name Value (NVAL)"
                                (string :tag "Name Value String")
                                (list :tag "Name Value List")
                                )
                        (choice :tag "Name Context (NCTX)"
                                (function-item :tag "Anywhere" :value any)
                                (function-item :tag "Beginning" :value beg)
                                (function-item :tag "End" :value end)
                                (function-item :tag "Extension" :value ext)
                                (function-item :tag "Full (Complete/Exact)" :value full)
                                (number :tag "Position")
                                (list :tag "Region"
                                      (number :tag "Position")
                                      (number :tag "Length")
                                      )
                                )
                        (choice :tag "Name Case-Fold (NCASEF)"
                                )
                        (choice :tag "Name Documentation (NDOC)"
                                )
                        )
                (vector :tag "Contents Matcher in the format [CFMT CVAL CCTX CCASEF]"
                        (choice :tag "Contents Format (CFMT)"
                                (function-item :tag "Literal" :value lit)
                                (function-item :tag "Regexp" :value re)
                                (function-item :tag "Symbolic Regexp" :value rx)
                                )
                        (choice :tag "Contents Value (CVAL)"
                                (string :tag "Contents Value String")
                                (list :tag "Contents Value List")
                                )
                        (list :tag "Contents Context List (CCTXS)"
                              (choice :tag "Contents Context (CCTX)"
                                      (function-item :tag "Anywhere" :value any)
                                      (function-item :tag "Beginning" :value beg)
                                      (function-item :tag "End" :value end)
                                      (function-item :tag "Extension" :value ext)
                                      (function-item :tag "Full (Complete/Exact)" :value full)
                                      (function-item :tag "Code" :value code)
                                      (function-item :tag "String" :value string)
                                      (function-item :tag "Comment" :value comment)
                                      (function-item :tag "Symbol" :value symbol)
                                      (function-item :tag "Keyword" :value keyword)
                                      (number :tag "Position")
                                      (list :tag "Region"
                                            (number :tag "Position")
                                            (number :tag "Length")
                                            )
                                      ))
                        (choice :tag "Contents Case-Fold (CCASEF)"
                                )
                        (choice :tag "Contents Documentation (CDOC)"
                                )
                        )
                (symbol :tag "Mode (MODE)")
                (choice :tag "Creation Mechanism (CREATION)"
                        (function-item :tag "Manual" :value man)
                        (function-item :tag "Automatic" :value gen)
                        )
                (list :tag "Programs (PROGS): Property List of Programs (either string or lambda-expression taging filename as argument) that can read this type.")
                ))
  :group 'filedb
  )

(defcustom fmd-script-type-magic-limit 64
  "Maximum size of script file header magic"
  :group 'filedb)

(defconst microsoft-office-applications-magic-header
  (unibyte-string #xd0 #xcf #x11 #xe0 #xa1 #xb1 #x1a #xe1)
  "Microsoft Office Applications Magic Header Data")

(defconst elf-magic-header
  (unibyte-string #x7f #x45 #x4c #x46)
  ;; (unibyte-string #x7f #x45 #x4c #x46 #x02 #x01 #x01 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00)
  ;; (unibyte-string #x7f #x45 #x4c #x46 #x01 #x01 #x01 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00)
  "ELF Magic Header Data. See:
  http://www.linuxforums.org/articles/understanding-elf-using-readelf-and-objdump_125.html.")
(defconst elf-magic-gcc-version-regexp "\0GCC: \\(.*\\)\0"
  "ELF GCC Version Matcher Regex.")

(defconst dos-mz-header
  "MZ"
  "MS-DOS/Windows PE (EXE) Magic Header Data.")

(defconst pe-magic-header
  "PE"
  "MS-DOS/Windows PE (EXE) Magic Header Data.")

(defconst coff-i386/32-magic-header
  (unibyte-string #x4c #x01)
  "COFF i386 32-bit Magic Header Data.")

(defconst jpeg-magic-header
  "\377\330"
  "JPEG Magic Header Data.")

(defcustom ftype-image-show "shotwell" "Program that shows an image."
  :group 'filedb)

(defcustom ftype-document-show "evince" "Program that shows a document."
  :group 'filedb)

(defvar ftypes-gud-debuggable-file-keys
  '(ELF Bash-Script Zsh-Script Shell-Script Python Perl Ruby Env-Script)
  "File types that are debuggable inside Emacs using GUD.")

(defconst ftypes-uneditable-file-keys
  '(
    ;; Executable
    ELF
    PE/COFF DOS-MZ COFF-i386/32 GPCH
    Ada-Library

    ;; Archives
    AR TAR JAR RAR

    ;; Images
    JPEG JPEG-2000 PNG GIF TIFF XPM XBM PBM PGM PPM PNM
    BMP Apple-Icon ICO-Icon ICO-Cursor XCF ;TODO: Replace with super class key `Binary-Image'
    CRW TGA PIC PIF SEA YTR

    ;; Sound
    WAV AMR MP3 KOZ MPEG-v4 M3U M3U8

    ;; Documents
    PDF DVI Microsoft-Excel Microsoft-Powerpoint

    ;; Compiled Code
    Emacs-Lisp-Compiled Java-Class-Compiled
    Python-Compiled Python-Optimized Python-Dynamic-Module Mono.Addin
    Emacs-Backup Emacs-Autosave Standard-Backup Emacs-Session

    ;; Caches
    Semantic-Cache
    Dependency-File
    Undo-File

    ;; Tags
    EBrowse Idutils

    ;; Disk Images
    VirtualBox-Disk-Image

    ;; Caches
    Autoconf-log Autoconf-status Autotools-dependency Autoconf-configure-script
    Autoconf-config.h Autoconf-confdefs.h Autoconf-config.h-timestamp
    Automake-generated
    sconsign

    ;; logs
    Doxygen-Error-Log

    ;; Databases
    Berkeley-DB SQLite

    ;; IDE/Code/Tags Files
    Exuberant-Ctags Emacs-tags GNU-GLOBAL CScope Idutils EBrowse VCPCH VSIDB Borland-IDE Matlab-MAT Matlab-License

    ;; File System Images
    ISO UDF

    ;; Checksums
    SFV

    Aspell-rowl

    Vector-Font

    Cryptographic-Certificate
    Cryptographic-Signature
    )
  "Uneditable file type keys.")

(defconst ftypes-uneditable-dir-keys
  '(
    ;; Backup and Version Control Stuff
    Backup-Directory
    TRAMP-Backup-Directory
    VC-Db-Dir
    CVS-Backup
    Undo-Directory

    ;; Build Tool Caches
    Automake-cache
    SConf-temp
    Dependencies-Directory
    WAF-Cache

    ;; Windows
    Windows-thumbnail-cache
    Windows-System-Volume-Information

    ;; Mac OS X
    Apple-Mac-OS-X-Trashcan
    Apple-Mac-OS-X-Desktop-Services-Store

    Trashcan

    ;; Virtual Machines
    VirtualBox-Settings

    ;; File-System Stuff
    lost+found
    )
  "Uneditable directory type keys.")

(defconst ftypes-executable-script-file-keys
  '(Script Shell-Script A-Script Bash-Script Csh-Script Tcsh-Script Zsh-Script
           JavaScript S-Lang Python Perl Ruby Lua Scheme Awk
           Env-Script
           Emacs-Lisp)
  "Executable Script file type keys.")

(defconst ftypes-script-file-keys
  (append ftypes-executable-script-file-keys
          '(SConstruct Rakefile Jamfile CMakeList.txt premake Makefile Automake-input Automake-cache Cook))
  "Script file type keys.")

(defconst ftypes-build-script-file-keys
  '(SConstruct Rakefile Jamfile CMakeList.txt premake Makefile Cook)
  "Build Script file type keys.")

(defconst c-deps-contents-begin-regexp
  ".*\\.o[[:space:]]*:[[:space:]]+.*$"
  "C/C++ Dependencies File Contents Regexp.")

;; ---------------------------------------------------------------------------

(defun fmd-add (key name category ptype match mode &optional creation ops hits homepage)
  "Register file type (KEY NAME CATEGORY PTYPE MATCH MODE CREATION OPS HITS) (ftype) to `fmd-types'."
  (setq fmd-types
        (cons `[,key ,name ,category ,ptype ,match ,mode ,creation ,ops ,hits ,homepage] fmd-types)))
;; Use: (fmd-add 'README "README" "Special Text" t '((re "README\\(?:\\..*\\)?" full) nil) 'text-mode 'man)

(defun fmd-add-ftype (ftype)
  "Register FTYPE to `fmd-types'."
  (when ftype
    (setq fmd-types
          (cons ftype fmd-types))))
;; Use: (fmd-add-ftype '[README "README" "Special Text" t ((re "README\\(?:\\..*\\)?" full) nil) 'text-mode man])

;; ---------------------------------------------------------------------------

(defun gud-pdb-command-name-fn (filename &rest args)
  (let ((args (delq nil args)))
    (pdb (concat (if (executable-find gud-pdb-command-name) gud-pdb-command-name "python -m pdb")
                 " " filename
                 (when args " ") args))))
;; Use: (gud-pdb-command-name-fn "~/bin/fib.py")

(defvar gud-ipdb-command-name "ipdb" "Python ipdb command name.")
(defun gud-ipdb-command-name-fn (filename &rest args)
  (let ((args (delq nil args)))
    (pdb (concat (if (executable-find gud-ipdb-command-name) gud-ipdb-command-name "python -m ipdb")
                 " " filename
                 (when args " ") args))))
;; Use: (gud-ipdb-command-name-fn "~/bin/fib.py")

(defcustom desktop-open (or (executable-find "xdg-open")
                            (executable-find "gnome-open")
                            (executable-find "open") ;Mac OS X
                            )
  "Standard command for opening files the desktop way."
  :group 'filedb)

(defun c-header-to-d (in &optional out c++)
  "Convert C/C++ Header IN to D Module OUT.
See http://dlang.org/htod.html"
  (let* ((out (or out (concat (file-name-sans-extension in) ".d")))
         (out (when (file-exists-p out)
                (read-file-name
                 (format "D Module File %s already exists. Enter another name:" out)
                 nil out))))
    (if c++ ;;(file-C++-header-p in)
        (start-process "htod" nil "htod" "-cpp" in out)
      (start-process "htod" nil "htod" in out))))

(defun c++-header-to-d (in &optional out)
  "Convert C++ Header IN to D Module OUT.
See http://dlang.org/htod.html"
  (c-header-to-d in out t))

(defun oclint (in &optional out)
  "Run OCLint Code Analysis on C/C++ Input Source File(s) IN.
See http://oclint.org/"
  (let ((prefix "/tmp/oclint-report_")) ;temporary filename prefix
    (cond ((stringp in)
           (let* ((out (or out (concat (make-temp-name (concat prefix
                                                               (file-name-sans-directory
                                                                (file-name-sans-extension in)))) ".html")))
                  (out (if (file-exists-p out)
                           (read-file-name
                            (format "Output HTML File %s already exists. Enter another name:" out)
                            nil out)
                         out)))
             (start-process "oclint" nil "oclint" "-report-type" "html" "-o" out "--" "-c" in)))
          ((listp in)
           (let ((out (concat (make-temp-name prefix) ".html")))
             `(start-process "oclint" nil "oclint" "-report-type" "html" "-o" out "--" "-c" ,@in))))))

(defun fmd-add-defaults ()
  "Register default file types to `fmd-types'."

  (setq fmd-types nil)

  ;; See: Wikipedia: http://en.wikipedia.org/wiki/FourCC:
  ;; A FourCC (literally, four-character code) is a sequence of four
  ;; bytes used to uniquely identify data formats.

  ;; Special Text Filesassoc
  ;; See: http://en.wikipedia.org/wiki/FILE_ID.DIZ and http://www.textfiles.com/artscene/information/faq-file_id.html
  (fmd-add 'FILE_ID.DIZ "FILE_ID.DIZ (Description In Zipfile)" "Description" 'txt
           '(:name (lit "file_id.diz" full)) 'text-mode 'man)
  (fmd-add 'README "README" "Special Text" 'txt
           '(:name (re "README\\(?:\\..*\\)?" full)) 'text-mode 'man)
  (fmd-add 'INSTALL "INSTALL" "Special Text" 'txt
           '(:name (re "INSTALL\\(?:\\..*\\)?" full)) 'text-mode 'man)
  (fmd-add 'TODO "TODO" "Special Text" 'txt
           '(:name (re "TODO\\(?:\\..*\\)?" full)) 'text-mode 'man)
  (fmd-add 'LICENSE "LICENSE" "Special Text" 'txt
           '(:name (re "LICENSE\\(?:\\..*\\)?" full)) 'text-mode 'man)
  (fmd-add 'Changelog "Changelog" "Special Text" 'txt
           '(:name (re "Change[lL]og\\(?:\\..*\\)?" full)) 'change-log-mode 'man)

  ;; Text Files
  (fmd-add 'Plain-Text "Plain Text" "Text" 'txt
           '(:name (lit "txt" ext)) 'text-mode 'man)
  (fmd-add 'Org-mode "Org-Mode" "Text" 'txt
           '(:name (lit "org" ext)) 'org-mode 'man '("emacs"))

  ;; Emacs-Lisp
  (fmd-add 'Emacs-Lisp "Emacs-Lisp" "Source Code"
           'txt
           '(:name (lit "el" ext)
                   :contents (lit "#!/usr/bin/emacs --script" 0))
           'emacs-lisp-mode 'man '((:execute "emacs --script")))
  (fmd-add 'Emacs-Lisp-Compiled "Emacs-Lisp Byte Code" "Byte Code"
           'bin
           '(:name (lit "elc" ext)
                   :contents (lit ";ELC\27\0\0\0" 0)
                   :precog contents-recog)
           nil 'gen)

  ;; Java
  (fmd-add 'Java "Java" "Source Code"
           'txt
           '(:name (lit "java" ext))
           'java-mode 'man '((:build "javac")))
  (fmd-add 'Java-Class-Compiled "Java Byte Code" "Byte Code"
           'bin
           '(:name (lit "class" ext)
                   :contents (lit "\xca\xfe\xba\xbe" 0) ;"cafebabe"
                   :precog contents-recog)
           nil 'gen '((:execute "java")
                      (:debug (lambda (filename &optional build-type compilation-window working-directory args)
                                (jdb (concat gud-jdb-command-name " " filename))))))

  (fmd-add 'JavaScript "JavaScript Code" "Script Code"
           'txt
           '(:name (lit "js" ext))
           'javascript-generic-mode 'man)
  (fmd-add 'JSON "JavaScript Object Notation" "Data interchange"
           'txt
           '(:name (lit "json" ext))
           'js-mode 'man)

  ;; Matlab and Octave
  (fmd-add 'Matlab "Matlab" "Script Code" 'txt
           '(:name (lit "m" ext)
                   :content (lit "function" 0))
           'matlab-mode 'man
           '((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                         (find-file filename)
                         (matlab-shell-save-and-go)))
             (:profile (lambda (filename &optional build-type compilation-window working-directory args)
                         (find-file filename)
                         (save-window-excursion
                           (matlab-shell-collect-command-output "profile on"))
                         (matlab-shell-save-and-go)
                         (save-window-excursion
                           (matlab-shell-collect-command-output "profile viewer"))
                         (when (y-or-n-p "Save profile?")
                           (let ((dir (read-directory-name "Profile write directory: ")))
                             (matlab-shell-collect-command-output
                              (format "profsave(profile('info'),'%s')"
                                      dir)))
                           )
                         ))
             (:execute-shell (lambda (filename &optional build-type compilation-window working-directory args)
                               (shell-command-silent
                                (concat "matlab -nodisplay < "
                                        filename))))
             ;; (:profile-shell (lambda (filename &optional build-type compilation-window working-directory args)
             ;;                   (shell-command-silent
             ;;                    (concat "matlab -nodisplay < "
             ;;                            filename))))
             (:debug (lambda (filename &optional build-type compilation-window working-directory args)
                       ))
             (:check "mlint")))
  ;; TODO: Activate ".m" extension and distinguish from Matlab by checking, for example, comment style.
  ;; TODO: Call something like `octave-shell-save-and-go'.
  (fmd-add 'Octave "Octave" "Script Code" 'txt
           '(:name (lit "octave" ext))
           'octave-mode 'man
           '("octave" (run-octave)))

  (fmd-add 'Matlab-MAT "Matlab MAT-file" "Binary Data" 'bin
           '(:name (lit "mat" ext)
                   :contents (re "MATLAB [0-9]\.0 MAT-file" 0)
                   :precog contents-recog)
           nil nil nil)

  (fmd-add 'Matlab-License "Matlab License passcode" "Text Data" 'txt
           '(:name (lit "lic" ext)
                   :contents (lit "MathWorks license passcode file" any)
                   :precog contents-recog)
           nil nil nil)

  ;; http://docs.julialang.org/en/latest/manual/getting-started/
  (fmd-add 'Julia "Julia" "Script Code" 'txt
           '(:name (lit "jl" ext))
           'julia-mode 'man
           '((:execute "julia")
             (:evaluate "julia -e")  ;TODO: Support eval-region in julia-mode.el
             ))

  ;; Script Code
  (fmd-add 'Script "Script" "Script Code" 'txt
           `(:contents (re "#[[:space:]]*![[:space:]]*\\(?:/.*\\)" 0 nil ,fmd-script-type-magic-limit) ;Note: match-1 is interpreter to use
                       :precog contents-recog
                       :generalize (Shell-Script Perl Python Ruby Lua Awk)
                       )
           nil 'man nil nil "http://en.wikipedia.org/wiki/Shebang_(Unix)") ;TODO: 1 means to use contents-matcher (match-string 1) as interpreter

  (fmd-add 'A-Script "A-Shell" "Script Code" 'txt
           `(:name (lit "ash" ext)
                   :contents (re ,(rx "#!"
                                      (* space)
                                      "/bin/ash") 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog)
           'sh-mode 'man '((:execute "ash")))

  (fmd-add 'Bash-Script "Bash" "Script Code" 'txt
           `(:name (lit "bash" ext)
                   :contents (re "#![[:space:]]*/bin/bash" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog
                   :extend Shell-Script)
           'sh-mode 'man
           '((:execute "bash")
             (:debug (lambda (filename &optional build-type compilation-window working-directory args)
                       (bashdb (concat gud-bashdb-command-name " " filename))))))

  (fmd-add 'Csh-Script "csh" "Script Code" 'txt
           `(:name (lit "csh" ext)
                   :contents (re "#![[:space:]]*/bin/csh" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog
                   :extend Shell-Script)
           'sh-mode 'man '((:execute "csh")))

  (fmd-add 'Tcsh-Script "Tcsh" "Script Code" 'txt
           `(:name (lit "tcsh" ext)
                   :contents (re "#![[:space:]]*/bin/tcsh" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog
                   :extend Shell-Script)
           'sh-mode 'man '((:execute "tcsh")))

  (fmd-add 'Zsh-Script "Zsh" "Script Code" 'txt
           `(:name (lit "zsh" ext)
                   :contents (re "#![[:space:]]*/bin/zsh" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog
                   :extend Shell-Script)
           'sh-mode 'man '((:execute "zsh")))

  (fmd-add 'Shell-Script "Shell" "Script Code" 'txt
           `(:name (lit "sh" ext)
                   :contents (re "#![[:space:]]*\\(/bin/.*sh\\)" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog)
           'sh-mode 'man
           '((:execute "sh")
             (:debug (lambda (filename &optional build-type compilation-window working-directory args)
                       (bashdb (concat gud-bashdb-command-name " " filename))))))

  ;; Compile Languages

  (fmd-add 'C "C" "Source Code" 'txt
           `(:name (re ,(rx (in "c" "h")) ext)
                   :contents (rx (| ,@c-keywords-list
                                    (regexp ,cpp-statement-regexp))
                                 (any code))
                   :generalize (C-Header
                                C-Source)
                   (:oclint oclint)
                   )
           'c-mode 'man `((:build auto-build-c-file)
                          (:indent "indent")))

  (fmd-add 'C-Header "C Header" "Source Code" 'txt
           `(:name (lit "h" ext)
                   :contents (rx (| ,@c-keywords-list
                                    (regexp ,cpp-statement-regexp)
                                    ,cpp-ifndef-regexp)
                                 (any code))
                   :specialize C)
           'c-mode 'man `((:build auto-build-c-file)
                          (:indent "indent")
                          (:convert-to-ada-spec "g++ -c -fdump-ada-spec -C")
                          (:preprocess "gcc -E")
                          (:convert-to-d c-header-to-d)
                          (:oclint oclint)
                          ))

  (fmd-add 'C-Source "C Source" "Source Code" 'txt
           `(:name (lit "c" ext)
                   :contents (rx (| ,@c-keywords-list
                                    (regexp ,cpp-statement-regexp))
                                 (any code))
                   :specialize C)
           'c-mode 'man `((:build auto-build-c-file)
                          (:indent "indent")
                          (:preprocess "gcc -E")
                          (:cppcheck (lambda (filename &optional build-type compilation-window working-directory args)
                                       (compile (concat "cppcheck" " " filename))))
                          (:oclint oclint)
                          ))

  (fmd-add 'C++ "C++" "Source Code" 'txt
           `(:name (re ,(rx (| "cpp" "hpp" "c++" "h++" "cxx" "hxx" "cc" "hh" "C" "H")) ext)
                   :contents (rx (| ,@c++-keywords-list
                                    (regexp ,cpp-statement-regexp))
                                 (any code))
                   :extend C
                   ;; :generalize (C++-Header C++-Source)
                   )
           'c++-mode 'man `((:build auto-build-c++-file)
                            (:indent "indent")
                            (:preprocess "g++ -E")
                            (:cppcheck (lambda (filename &optional build-type compilation-window working-directory args)
                                         (compile (concat "cppcheck" " " filename))))
                            (:oclint oclint)
                            ))

  (fmd-add 'C++-Header "C++ Header" "Source Code" 'txt
           `(:name (re ,(rx (| "hp" "hpp" "HPP" "h++" "hxx" "hh" "H" "tcc")) ext)
                   :contents (rx (| ,@c++-keywords-list
                                    (regexp ,cpp-statement-regexp)
                                    (regexp ,cpp-ifndef-regexp))
                                 (any code))
                   :specialize C++)
           'c++-mode 'man `((:build auto-build-c++-file)
                            (:convert-to-ada-spec "g++ -c -fdump-ada-spec -C")
                            (:preprocess "g++ -E")
                            (:convert-to-d c++-header-to-d)
                            (:oclint oclint)
                            ))

  (fmd-add 'C++-Source "C++ Source" "Source Code" 'txt
           `(:name (re ,(rx (| "cp" "cpp" "CPP" "c++" "cxx" "cc" "C")) ext)
                   :contents (rx (| ,@c++-keywords-list
                                    (regexp ,cpp-statement-regexp))
                                 (any code))
                   :specialize C++)
           'c++-mode 'man `((:build auto-build-c++-file)
                            (:preprocess "g++ -E")
                            (:oclint oclint)
                            ))

  (fmd-add 'Objective-C "Obj-C" "Source Code" 'txt
           `(:name (lit ("mm" "M") ext)
                   :contents (re ,cpp-statement-regexp (any code))
                   :extend C)
           'objc-mode 'man `((:build auto-build-objc-file)))
  (fmd-add 'Objective-C-Interface "Obj-C Interface" "Source Code" 'txt
           `(:name (lit ("mm" "M") ext)
                   :contents (re "@implementation" (any code))
                   :specialize Objective-C)
           'objc-mode 'man `((:build auto-build-objc-file)))
  (fmd-add 'Objective-C-Implementation "Obj-C Implementation" "Source Code" 'txt
           `(:name (lit ("mm" "M") ext)
                   :contents (re "@implementation" (any code))
                   :specialize Objective-C)
           'objc-mode 'man `((:build auto-build-objc-file)))

  (fmd-add 'C-Sharp "C#" "Source Code" 'txt
           `(:name (lit "cs" ext)) 'csharp-mode 'man nil)

  (fmd-add 'D "D" "Source Code" 'txt
           `(:name (lit "d" ext))
           'd-mode 'man
           '((:build auto-build-d-file)
             (:execute (executable-find "rdmd"))
             (:execute-alt "dmd -run")
             (:generate-interface-file "dmd -H") ;http://dlang.org/dmd-linux.html#interface_files
             (:build-library (lambda (filename &optional build-type compilation-window working-directory args)
                               (concat "dmd -lib " (mapconcat files))))
             )
           nil "http://www.digitalmars.com/d/") ;D Programming Language
  (fmd-add 'D-Interface "D Interface" "Source Code" 'txt
           `(:name (lit "di" ext))
           'd-mode 'man
           '()
           nil "http://www.digitalmars.com/d/") ;D Programming Language

  (fmd-add 'Go "Go" "Source Code" 'txt
           `(:name (lit "go" ext))
           'go-mode 'man
           '((:build auto-build-go-file))
           nil "http://golang.org/")

  (fmd-add 'Rust "Rust" "Source Code" 'txt
           `(:name (lit "rs" ext))
           'rust-mode 'man
           '((:build auto-build-rust-file))
           nil "http://http://www.rust-lang.org/")

  (fmd-add 'Ada-Specification "Ada Specification" "Source Code" 'txt
           `(:name (lit "ads" ext))
           'ada-mode 'man
           nil
           nil)

  (fmd-add 'Ada-Body "Ada Body" "Source Code" 'txt
           `(:name (lit "adb" ext))
           'ada-mode 'man
           '(:build auto-build-ada-file)
           nil)

  (fmd-add 'Ada "Ada" "Source Code" 'txt
           `(:name (re ,(rx (| "ads" "adb" "ada")) ext)
                   ;; :generalize (Ada-Specification Ada-Body)
                   )
           'ada-mode)

  (fmd-add 'Ada-Library "Ada Library" "Library" 'txt
           `(:name (lit "ali" ext)
                   :contents ("V \"GNAT Lib"))
           'ada-mode 'man
           '(:link auto-link-ali-file)
           nil)

  (fmd-add 'Go "Go" "Source Code" 'txt
           `(:name (lit "go" ext))
           'go-mode 'man `((:build auto-build-go-file))
           nil "http://golang.org/")

  (fmd-add 'Pascal "Pascal" "Source Code" 'txt
           `(:name (lit ("pas" "p") ext))
           'pascal-mode 'man nil)

  (fmd-add 'Fortran "Fortran" "Source Code" 'txt
           `(:name (re ("[fF]" "for" "ftn" "[fF]77" "[fF]90" "[fF]95" "FOR" "FTN") ext))
           'fortran-mode 'man
           `((:execute ("gfortran" "g77" "g95"))))
  (fmd-add 'Fortran-77 "Fortran 77" "Source Code" 'txt
           `(:name (re ("[fF]" "for" "ftn" "[fF]77" "[fF]90" "[fF]95" "FOR" "FTN") ext))
           'fortran-mode 'man
           `((:execute ("gfortran" "g77"))))
  (fmd-add 'Fortran-90 "Fortran 90" "Source Code" 'txt
           `(:name (re ("[fF]90" "[fF]95") ext))
           'fortran-mode 'man
           `("gfortran" "g95"))

  (fmd-add 'BETA "BETA" "Source Code" 'txt
           `(:name (lit "bet" ext))
           'beta-mode 'man `((:execute "beta")))
  (fmd-add 'Cobol "Cobol" "Source Code" 'txt
           `(:name (lit ("cbl" "cob" "cbl" "COB") ext))
           'cobol-mode 'man `((:execute "cobol")))
  (fmd-add 'Eiffel "Eiffel" "Source Code" 'txt
           `(:name (lit ("e") ext))
           'eiffel-mode 'man `("eiffel"))
  (fmd-add 'Erlang "Erlang" "Source Code" 'txt
           `(:name (lit ("erl" "ERL" "hrl" "HRL") ext))
           'erlang-mode 'man `((:execute "erlang")))
  (fmd-add 'REXX "REXX" "Source Code" 'txt
           `(:name (lit ("cmd" "rexx" "rx") ext))
           'rexx-mode 'man `((:execute "rexx")))

  ;; Interpreted Languages

  (fmd-add 'S-Lang "Script" "Script Code" 'txt
           `(:name (lit "sl" ext)
                   (re "#![[:space:]]*/slsh" 0 nil ,fmd-script-type-magic-limit))
           'slang-mode 'man `((:execute "slsh")))

  (fmd-add 'Python "Python" "Script Code"
           'txt
           `(:name (lit ("py" "python") ext)
                   :contents (re "#![[:space:]]*\\(/usr/bin/python\\|/usr/bin/env[[:space:]]+python\\)\\([0-9.]?\\)" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog)
           'python-mode 'man `((:build (lambda (filename &optional build-type compilation-window working-directory args)
                                         ;; TODO: Use wine python.exe setup.py py2exe[/color] to build Window binaries.
                                         ))
                               (:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                           (find-file filename)
                                           ;; TODO: Choose between pypy.* or python.* using `read-executables-filename'.
                                           (if (region-active-p)
                                               (py-execute-region (region-beginning)
                                                                  (region-end)) ;TODO: Use ASYNC?
                                             (py-execute-buffer) ;TODO: Use ASYNC?
                                             )))
                               (:debug-pdb gud-pdb-command-name-fn)
                               (:debug-ipdb gud-ipdb-command-name-fn)
                               ;; \see http://wiki.python.org/moin/DebuggingWithGdb
                               ;; \see https://fedoraproject.org/wiki/Features/EasierPythonDebugging
                               ;; \see http://bugs.python.org/issue8032
                               (:debug-gdb (lambda (filename &optional build-type compilation-window working-directory args)
                                             (gdb (concat "gdb python ")) ;and (gdb) run <PROGRAMNAME>.py <ARGUMENTS>
                                             ;; or command-line: gdb python <PID-OF-RUNNING-PROCESS>
                                             ))
                               (:convert-to-c++ (lambda (filename &optional build-type compilation-window working-directory args)
                                                  (compile (concat "pythran" " " filename args)) ;at git://github.com/serge-sans-paille/pythran.git
                                                  ))
                               ))
  (fmd-add 'Cython "Cython" "Script Code"
           'txt
           `(:name (lit ("pyx"          ;Implementation
                         "pxd"          ;Definition
                         "pxi"          ;Include
                         ) ext))
           'python-mode nil nil nil "docs.cython.org/src/reference/language_basics.html")

  (fmd-add 'PythonW "Python GUI" "Script Code"
           'txt
           `(:name (lit ("pyw") ext)
                   :contents (re "#![[:space:]]*/usr/bin/python" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog)
           'python-mode 'man `((:execute "pythonw")
                               (:debug gud-pdb-command-name-fn)))

  (fmd-add 'Python-Compiled "Python Byte Code" "Byte Code"
           'bin
           `(:name (lit ("pyc") ext)
                   :contents (lit "\x0d\x0a" 2)
                   :precog name-or-contents-recog)
           nil 'gen `((:execute "python")
                      (:debug gud-pdb-command-name-fn)))

  (fmd-add 'Python-Optimized "Python Optimized Byte Code" "Byte Code"
           'bin
           `(:name (lit ("pyo") ext))
           nil 'gen `((:execute "python")
                      (:debug gud-pdb-command-name-fn)))

  (fmd-add 'Python-Dynamic-Module "Python Dynamic Module" "Byte Code"
           'bin
           `(:name (lit ("pyd") ext))
           nil 'gen nil)

  (fmd-add 'Mono.Addin "Mono.Addin" "Byte Code" 'txt
           `(:name (lit "maddin" ext)
                   :contents (lit "\x01\x04\x00\x00\x00\x46" 0)
                   :precog contents-recog)
           nil 'man nil)

  (fmd-add 'Perl "Perl" "Script Code"
           'txt
           `(:name (lit ("perl") ext)
                   :contents (re "#![[:space:]]*/usr/bin/perl" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog)
           'perl-mode 'man `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                         (concat "perl -cw " filename)))))

  (fmd-add 'Ruby "Ruby" "Script Code"
           'txt
           `(:name (lit ("ruby" "rb") ext)
                   :contents (re "#![[:space:]]*/usr/bin/ruby" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog)
           'ruby-mode 'man `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                         (concat "ruby -cw " filename)))))

  (fmd-add 'Lua "Lua" "Script Code"
           'txt
           `(:name (lit "lua" ext)
                   :contents (re "#![[:space:]]*/usr/bin/lua" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog)
           'lua-mode 'man `((:execute "lua")))

  (fmd-add 'Scheme "Scheme" "Script Code"
           'txt
           `(:name (lit "scheme" ext "scm" "SCM" "sm" "SM" "sch"))
           'scheme-mode 'man `((:execute "guile")))

  (fmd-add 'Clojure "Clojure" "Script Code"
           'txt
           `(:name (lit "clj" ext))
           'clojure-mode 'man `((:execute "clojure")))

  (fmd-add 'Haskell "Haskell" "Code"
           'txt
           `(:name (lit ("hs" "lhs") ext))
           'haskell-mode 'man
           `( ;;(:build auto-build-haskell-file)
             (:load (lambda (filename &optional build-type compilation-window working-directory args)
                      (find-file filename)
                      (call-interactively 'inferior-haskell-load-file)))
             (:reload (lambda (filename &optional build-type compilation-window working-directory args)
                        (find-file filename)
                        (call-interactively 'inferior-haskell-reload-file)))
             (:execute (lambda (filename &optional build-type compilation-window working-directory args)
                         (find-file filename)
                         (call-interactively 'inferior-haskell-load-and-run)))
             (:check (lambda (filename &optional build-type compilation-window working-directory args)
                       (find-file filename)
                       (call-interactively 'hs-lint)
                       ;; (call-interactively 'haskell-check)
                       )
                     )))

  (fmd-add 'Assembler "Assembler" "Source Code"
           'txt
           `(:name (re ("asm" "ASM" "[sS]" "A51" "29[kK]" "[68][68][kKsSxX]" "[xX][68][68]") ext))
           nil 'man `((:execute "nasm" "gas")))

  (fmd-add 'Awk "Awk" "Script Code"
           'txt
           `(:name (re "[gm]?awk" ext))
           'awk-mode 'man `((:execute ("awk" "gawk"))))

  (fmd-add 'GLSL-Vertex-Program "GLSL Vertex" "Source Code" 'txt
           `(:name (lit ".vp" ext)
                   :contents (re "gl_Position[[:space:]]+=" (any code)))
           'glsl-mode 'man nil)
  (fmd-add 'GLSL-Fragment-Program "GLSL Fragment" "Source Code" 'txt
           `(:name (lit ".fp" ext)
                   :contents (re "gl_FragColor[[:space:]]+=" (any code)))
           'glsl-mode 'man nil)

  ;; NVIDIA Cg
  (fmd-add 'Cg "Cg" "Source Code" 'txt
           `(:name (lit ".cg" ext))
           'glsl-mode 'man `((:execute "cgc")) nil "http://developer.nvidia.com/page/cg_main.html")
  ;; NVIDIA CUDA
  ;; See: http://lifeofaprogrammergeek.blogspot.com/2008/05/cuda-development-in-ubuntu.html
  (fmd-add 'CUDA "CUDA" "Source Code" 'txt
           `(:name (lit "cu" ext))
           'cuda-mode 'man `((:execute "nvcc")))

  ;; Markup Languages
  ;; TODO: Or use `browse-url'?
  (fmd-add 'TexInfo "TexInfo" "Document Source Code" 'txt
           `(:name (lit "texi" ext))
           'texinfo-mode 'man `((:execute ("makeinfo %f" "texi2pdf %f" "texi2dvi %f"))))
  (fmd-add 'config_spec "config_spec" "Markup Source Code" 'txt
           `(:name (lit "config_spec.xml" full)
                   :specialize XML)
           'xml-mode 'man `((:wact (lambda (filename &optional build-type compilation-window working-directory args)
                                     (let ((cmd (read-wact-command)))
                                       (when (executable-find "wact")
                                         (mapconcat 'identify '("wact" cmd "-c" filename) " ")))))
                            (:sort (lambda (filename &optional build-type compilation-window working-directory args)
                                     (when (executable-find "sort_config_spec.py")
                                       (mapconcat 'identify '("sort_config_spec.py" "-c" filename) " "))))))
  (fmd-add 'KML "KML" "Keyhole Markup Language" 'txt
           `(:name (lit "kml" ext))
           'xml-mode 'man `((:show "google-earth")))
  (fmd-add 'KMZ "KMZ" "Keyhole Markup Language Zipped" 'box
           `(:name (lit "kmz" ext))
           'xml-mode 'man `((:show "google-earth")))
  (fmd-add 'SML "SML" "Markup Source Code" 'txt
           `(:name (lit "sml" ext))
           nil 'man nil)
  (fmd-add 'XML "XML" "Markup Source Code" 'txt
           `(:name (lit "xml" ext)
                   :contents (lit "<?xml" 0)
                   :precog contents-recog)
           'xml-mode 'man `((:show ,desktop-open)
                            (:browse ,desktop-open)
                            (:view ,desktop-open)
                            (:check "xmllint")))
  (fmd-add 'HTML "HTML" "Markup Source Code" 'txt
           `(:name (re "htm[l]?" ext))
           'html-mode 'man `((:show ,desktop-open)
                             (:browse ,desktop-open)
                             (:view ,desktop-open)))
  (fmd-add 'PHP "PHP" "Markup Source Code" 'txt
           `(:name (re ("php3?" "phtml") ext))
           'php-mode 'man `((:execute "php -l %f")))
  (fmd-add 'ASP "ASP" "Markup Source Code" 'txt
           `(:name (re "as[ap]" ext))
           'asp-mode 'man nil)
  (fmd-add 'Cascading-Style-Sheets "CSS" "Markup Source Code" 'txt
           `(:name (lit "css" ext))
           'css-mode 'man nil)
  (fmd-add 'Nroff "Nroff" "Markup Source Code" 'txt
           `(:name (lit "nroff" ext)
                   :contents (lit (".TH" ".SH" ".PP" ".TS" ".TE" ".TP" ".B") keyword)
                   :precog contents-recog)
           'xml-mode 'man `((:execute "nroff")))
  (fmd-add 'CHM '("CHM" "Compressed HTML Archive") "Document" 'txt
           `(:name (lit "chm" ext))
           'html-mode 'man `((:show "gnochm")))

  (fmd-add 'SQL "SQL" "Database Query" 'txt
           `(:name (lit "sql" ext))
           'sql-mode 'man nil)

  (fmd-add 'SQLite "SQLite" "Database" 'txt
           `(:name (lit ("sql" "localstorage") ext)
                   :contents (lit "SQLite format 3\0" 0)
                   :precog contents-recog)
           'sql-mode 'man nil)

  (fmd-add 'TCL "TCL" "GUI Source Code" 'txt
           `(:name (lit ("tcl" "tk" "wish" "itcl") ext))
           'tcl-mode 'man nil)
  (fmd-add 'Vera "Vera" "Hardware Source Code" 'txt `((lit ("vr" "vri" "vrh") ext))
           'vera-mode 'man nil)
  (fmd-add 'Verilog "Verilog" "Hardware Source Code" 'txt
           `(:name (lit "v" ext))
           'verilog-mode 'man nil)
  (fmd-add 'VHDL "VHDL" "Hardware Source Code" 'txt
           `(:name (lit "vhdl" ext))
           'vhdl-mode 'man nil)
  (fmd-add 'Vim "Vim" "Text Editor Language" 'txt
           `(:name (lit "vim" ext))
           nil 'man nil)

  (fmd-add 'Flex "Flex" "Source Code" 'txt
           `(:name (re "f?lex" ext))
           'flex-mode 'man `((:execute "flex")))
  (fmd-add 'YACC "YACC/Bison" "Source Code" 'txt
           `(:name (lit "y" ext))
           'bison-mode 'man `((:execute "bison")))

  ;; Build Tools

  (fmd-add 'Build-Tool-Script "Build Tool Script" "Group" 't
           '(:generalize (SConstruct
                          SConscript
                          Makefile
                          Rakefile
                          Jamfile
                          CMakeList.txt
                          premake
                          waf
                          Cook
                          Visual-Studio-Makefile
                          Visual-Studio-Solution))
           nil nil nil)

  ;; See:
  ;; http://retropaganda.info/~bohan/work/sf/psycle/branches/bohan/wonderbuild/benchmarks/time.xml
  ;; for performance comparison of different build tools
  (fmd-add 'SConstruct "Build Tool Script Code" "Build Tool Script Code" 'txt

           `(:name (lit "SConstruct" full))
           'scons-mode 'man `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                          (concat (executable-find "scons") " -f " filename)))
                              (:targets 'sconstruct-targets)))
  (fmd-add 'SConscript "Build Tool Script Code" "Build Tool Script Code" 'txt

           `(:name (lit "SConscript" full))
           'scons-mode 'man `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                          (concat (executable-find "scons") " -f " filename)))
                              (:targets 'sconstruct-targets)))
  (fmd-add 'Rakefile "Build Tool Script Code" "Build Tool Script Code" 'txt

           `(:name (re "[rR]akefile.*" full))
           'rake-mode 'man `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                         (concat (executable-find "rake") " -f " filename)))))
  (fmd-add 'Jamfile "Build Tool Script Code" "Build Tool Script Code" 'txt

           `(:name (re "[jJ]amfile.*" full)
                   :contents (re (or "^project "
                                     "^import "
                                     "^alias "
                                     "^install "
                                     "^explicit ") (any code))
                   :precog name-recog)
           'bjam-mode 'man `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                         (concat "bjam" " " filename)))))
  (fmd-add 'CMakeList.txt "Build Tool Script Code" "Build Tool Script Code" 'txt
           `(:name (lit "CMakeList.txt" full))
           'cmake-mode 'man `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                          (concat "cmake "
                                                  (file-name-directory filename) ;CMake wants the directory
                                                  )))))
  (fmd-add 'premake "Build Tool Script Code" "Build Tool Script Code" 'txt
           `(:name (lit "premake.lua" full))
           'premake-mode 'man `((:execute "premake")) nil "http://premake.sourceforge.net")

  (fmd-add 'Cook "Cookbook" "Build Tool Script Code" 'txt
           `(:name (or (lit "Howto.cook" full)
                       (re "[Cc]ook[.]?file" full)
                       (lit "cook" ext)
                       (re ("cook[.]?rc") ext))
                   :precog name-recog)
           'cook-mode 'man `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                         (concat (executable-find "cook") " -Book " filename)))
                             (:targets 'cook-targets)))

  (fmd-add 'waf "WAF" "Build Tool Script Code" 'txt
           `(:name (lit "wscript" full))
           'python-mode 'man `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                           (concat (executable-find "waf") " -f " filename)))))

  (fmd-add 'Makefile "Build Tool Script Code" "Build Tool Script Code" 'txt
           `(:name (re ,(rx (| "GNUmakefile"
                               "Makefile"
                               "makefile"
                               "posix.mak")
                            (opt "." (regexp ".*")))
                       full)
                   :contents (re "^[[:space:]]*\\(?:[a-zA-Z0-9-_y]+\\):[[:space:]]$" any)
                   :precog name-recog)
           'makefile-mode 'man `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                                             (concat (or ;; TODO: Enable when we know how to check whether (executable-find "remake") is available on remote compilation host
                                                         (executable-find "gmake")
                                                         (executable-find "make")) " -f " filename)))
                                 (:targets 'makefile-targets)
                                 (:convert-to-cook (lambda (filename) (concat "make2cook " filename)))))

  (fmd-add 'Visual-Studio-Makefile "Visual Studio NMake makefile" "Build Tool Script Code" 'txt
           `(:name (lit ("mak" "nmake") ext))
           'nmake-mode 'man
           `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                         (concat "nmake.exe /f " filename)))))
  (fmd-add 'Visual-Studio-Solution "Build Tool Script Code" "Build Tool Script Code" 'txt
           `(:name (lit ("sln" "suo") ext))
           'vcmake-mode 'man
           `((:execute (lambda (filename &optional build-type compilation-window working-directory args)
                         (concat "vcmake.exe /f " filename)))))

  ;; Documentation Tool

  ;; Doxygen
  (fmd-add 'Doxyfile "Doxygen File" "Documentation Tool" 'txt
           `(:name (re ("\\`Doxyfile" "\\.doxygen\\'") any))
           'conf-mode 'man `((:execute "doxygen")))
  (fmd-add 'Doxygen-Error-Log "Doxygen Error Log" "Log" 'txt
           `(:name (lit "doxygen-error-log.txt" full)
                   )
           nil 'gen nil)
  (fmd-add 'Ddoc "D Documentation" "Documentation Tool" 'txt
           `(:name (lit "dd" ext))
           nil 'gen nil)

  ;; Automake
  (fmd-add 'Automake-input "Automakefile" "Build Tool Script Code"
           'txt
           `(:name (re "[mM]akefile\\.am" full))
           'makefile-automake-mode 'man `((:execute "automake")))
  (fmd-add 'Automake-generated "Automake Makefile" "Build Tool Script Code"
           'txt
           `(:name (lit ("Makefile" "Makefile.in") full)
                   :contents (lit "# Makefile.in generated by automake" 0)
                   :precog contents-recog)
           'makefile-mode 'gen `((:execute "automake")))
  (fmd-add 'Automake-cache "Automake Cache" "Build Tool Script Code" 'dir
           `(:name (lit "autom4te.cache" full))
           nil 'gen `((:execute "automake")))

  ;; SCons
  (fmd-add 'SConf-temp "SCons Conf" "SCons Configuration" 'dir
           `(:name (lit ".sconf_temp" full))
           nil 'gen `((:execute "scons")))
  (fmd-add 'sconsign "sconsign" "sconsign" 'bin
           `(:name (lit (".sconsign" ".sconsign.dblite") full)
                   :contents (lit ("\x7d\x71\x01\x28") 0)
                   :precog contents-recog)
           nil 'gen `((:print "sconsign")))

  ;; EDE
  (fmd-add 'EDE-Generated-Makefile "EDE Makefile" "Makefile"
           'txt
           `(:name (lit "Makefile" full)
                   :contents (lit "# Automatically Generated Makefile by EDE." 0)
                   :precog contents-recog)
           nil 'gen nil)

  ;; Emacs Session file
  (fmd-add 'Emacs-Session "Emacs session" "Configuration"
           'txt
           `(:name (lit "session" full)
                   :contents (lit ";;; Automatically generated" 0)
                   )
           nil 'gen nil)

  ;; Autoconf
  (fmd-add 'Autoconf-input-template "Autoconf Template" "Autoconf Input"
           'txt
           `(:name (re "configure\\.\\(?:in\\|ac\\)" full)
                   :contents (lit "AC_INIT(\\[\\(?:.*?\\)\\],\\[\\(?:.*?\\)\\])" any) ;TODO: Use match-data: ((1 "Project Name") (2 "Version"))
                   )
           'autoconf-mode 'man `((:execute "autoconf")))
  (fmd-add 'Autoconf-log "Autoconf Log" "Log" 'txt
           `(:name (lit "config.log" full)
                   :contents (re "[Gg]enerated by GNU Autoconf" bol))
           nil 'gen nil)
  (fmd-add 'Autoconf-status "Autoconf Status" "" 'txt
           `(:name (lit "config.status" full)
                   :contents (re ".*\n# Generated by configure" 0))
           nil 'gen nil)
  (fmd-add 'Autoconf-config.h "Autoconf config.h" "" 'txt
           `(:name (lit "config.h" full)
                   :contents (lit "/* config.h.  Generated from config.h.in by configure.  */" 0)
                   :precog contents-recog)
           nil 'gen nil)
  (fmd-add 'Autoconf-confdefs.h "Autoconf confdefs.h" "" 'txt
           `(:name (lit "confdefs.h" full)
                   :precog contents-recog)
           nil 'gen nil)
  (fmd-add 'Autoconf-config.h-timestamp "Autoconf Timestamp" "" 'txt
           `(:name (lit "stamp-h1" full)
                   :contents (lit "timestamp for config.h" 0))
           nil 'gen nil)
  (fmd-add 'Autotools-dependency "Autoconf Dependency" "" 'txt
           `(:name (lit "Po" ext)
                   :contents (re ,c-deps-contents-begin-regexp 0))
           nil 'gen nil)
  (fmd-add 'Autoconf-configure-script "Autoconf configure" "Configure Script" 'txt

           `(:name (lit "Po" ext)
                   :contents (lit "#! /bin/sh\n# Guess values for system-dependent variables and create Makefiles.\n# Generated by GNU Autoconf" 0))
           nil 'gen nil)

  ;; Autogenerated
  (fmd-add 'Auto-generated "Auto-generated" "Auto-generated" 'txt `(:contents (re ".*\n# Generated by GNU" 0))
           nil 'gen nil)

  ;; Backups
  (fmd-add 'Emacs-Backup "Emacs Backup" "Backup" 't
           `(:name (re "~" end))
           nil 'gen nil)
  (fmd-add 'Emacs-Autosave "Emacs Autosave" "Backup" 't
           `(:name (re "\\.?#.*" full))
           nil 'gen nil)
  (fmd-add 'Standard-Backup "Backup" "Backup" 't
           `(:name (lit "bak" ext))
           nil 'gen nil)
  (fmd-add 'Backup-Directory "Backup Directory" "Backup Dir" 'dir
           `(:name (lit ".backups" full))
           nil 'gen nil)                ;Emacs Backups
  (fmd-add 'TRAMP-Backup-Directory "TRAMP Backup Directory" "Backup Dir" 'dir
           `(:name (lit ".tramp-backups" full))
           nil 'gen nil)                ;Emacs TRAMP Backups
  (fmd-add 'CVS-Backup "CVS Backup" "Backup" 'dir
           `(:name (re ".*,v" full))
           nil 'gen nil)
  (fmd-add 'Dependencies-Directory "Dependencies" "Dependency" 'dir
           `(:name (lit ".deps" full))
           nil 'gen nil)
  (fmd-add 'Dependency-File "Object-Dependency" "Dependency" 'txt
           `(:name (re "\..*\.deps" full)
                   :contents (re ,c-deps-contents-begin-regexp 0)
                   :precog contents-recog)
           nil 'gen nil)
  (fmd-add 'WAF-Cache "Temporary" "Temporary" 'dir
           `(:name (re ,(rx (: bos
                               ".waf"
                               "-" (+ (in ?. (?0 . ?9)))
                               "-" (+ hex)
                               )
                            ) full))
           nil 'gen nil)
  (fmd-add 'Undo-File "Undo-File" "Undo" 'txt
           `(:name (re ,(rx (: "."
                               (* anything)
                               "."
                               (| "undo"
                                  "undo-tree"
                                  "undo-list")
                               eos))) full)
           nil 'gen nil)
  (fmd-add 'Undo-Directory "Undo-Directory" "Undo" 'dir
           `(:name (lit (".undo") full))
           nil 'gen nil nil)

  ;; GNOME Desktop Entry
  (fmd-add 'Desktop-Entry "Desktop" "Desktop" 'txt
           `(:name (lit "desktop" ext)
                   :contents (lit "[Desktop Entry]" (0 eol))
                   :precog name-or-contents-recog)
           nil 'gen nil)

  ;; GNOME Theme Package

  ;; TODO: It contains a theme_name directory that includes an index.theme file
  ;; and gtk and metacity directories. It is saved in a gzip-compressed-tar
  ;; format.
  (fmd-add 'GNOME-Theme-Package "GNOME-Theme-Package" "Theme" 'txt
           `(:name (lit "gtp" ext)
                   :specialize (GNU-zip TAR) ;TODO: Express using Layers
                   )
           nil 'gen nil)

  ;; System Thumbnails and Meta Data
  (fmd-add 'Apple-Mac-OS-X-Desktop-Services-Store "Thumbnail" "Thumbnail" 'dir
           `(:name (lit ".DS_Store" full))
           nil 'gen nil nil "http://en.wikipedia.org/wiki/.DS_Store")
  (fmd-add 'Windows-thumbnail-cache "Thumbnail" "Thumbnail" 'dir
           `(:name (lit "thumbs.db" full))
           nil 'gen nil)                ;See: )
  (fmd-add 'Apple-Mac-OS-X-Trashcan "Thumbnail" "Thumbnail" 'dir
           `(:name (lit (".Trashes" "._.Trashes") full))
           nil 'gen nil nil "http://en.wikipedia.org/wiki/Windows_thumbnail_cache")
  (fmd-add 'Trashcan "Trash" "Trash" 'dir
           `(:name (lit (".trash") full))
           nil 'gen nil nil)
  (fmd-add 'VirtualBox-Settings "Temporary" "Temporary" 'dir
           `(:name (lit ".VirtualBox" full))
           nil 'gen nil)
  (fmd-add 'Windows-System-Volume-Information "System Data" "System Data" 'dir
           `(:name (lit ("System Volume Information") full))
           nil 'gen nil)
  (fmd-add 'lost+found "System Data" "System Data" 'dir
           `(:name (lit ("lost+found") full))
           nil 'gen nil)

  ;; If the first 512 bytes contain any character of 0-7,
  ;; 14-26,28-31, the file is basically considered to be a
  ;; binary. This is GNU GLOBAL way of detecting binary data.
  (fmd-add 'Binary "Binary" "Generic Binary Data"
           'bin `(nil
                  (re ,(rx (| (in 0 7)
                              (in 14 26)
                              (in 28 31)))
                      0 ;TODO: Add support for this context (CTX) of type consp by changing context to (0 . 512)
                      )
                  contents-recog)
           nil nil nil)

  ;; HDF
  (fmd-add 'HDF "HDF" "Binary Data" 'bin
           `(:name (lit ("hdf" "h4" "hdf4" "h5" "hdf5" "he4" "he5") ext))
           nil 'man nil)                ; Hierarchical Data Format

  ;; ================ Object Machine Code ================

  (fmd-add 'ELF '("ELF" "Executable and Linkable Format") "Object Machine Code"
           'bin
           `(:name (lit ("o" "so" "out") ext)
                   :contents (lit ,elf-magic-header 0)
                   :precog contents-recog
                   :attributes ((re ,elf-magic-gcc-version-regexp) . "GCC Version"))
           'hexl-mode 'gen (append
                            `((:execute file-execute-without-filter))
                            (when (executable-find "gdb")
                              `((:debug file-debug-with-gdb)))
                            (when (executable-find "valgrind")
                              `((:check-and-debug (lambda (filename &optional build-type compilation-window working-directory args)
                                                    (when (require 'valgrind nil t)
                                                      (valgrind-gdb-run filename args))))))
                            (when (executable-find "strace")
                              `((:strace file-execute-through-strace)))
                            (when (executable-find "apitrace")
                              `((:apitrace-opengl file-execute-through-apitrace)))
                            (when (executable-find "qapitrace")
                              `((:qapitrace-opengl file-execute-through-qapitrace)))
                            (when (executable-find "ltrace")
                              `((:strace file-execute-through-ltrace)))
                            (when (executable-find "valgrind")
                              `((:check (lambda (filename &optional build-type compilation-window working-directory args)
                                          (when (require 'valgrind nil t)
                                            (valgrind-run filename args))))))
                            (when (executable-find "perf")
                              `((:perf file-execute-through-perf)))
                            (when (executable-find "oprofile")
                              `((:profile (lambda (filename &optional build-type compilation-window working-directory args)
                                            (when (require 'oprofile nil t)
                                              (oprofile-start-single filename args))))))
                            (when (executable-find "optirun")
                              `((:optirun-opengl file-execute-through-optirun))
                              )
                            (when (and (executable-find "oprofile")
                                       (executable-find "optirun"))
                              `((:profile-optirun-opengl file-execute-through-oprofile-optirun))
                              )
                            ))

  (fmd-add 'COFF-i386/32 '("PE/COFF" "Common Object File Format") "Object Machine Code"
           'bin
           `(:name (lit ("o") ext)
                   :contents (lit ,coff-i386/32-magic-header 0)
                   :precog contents-recog)
           'hexl-mode 'gen `((:execute "wine")) nil "http://en.wikipedia.org/wiki/COFF")

  (fmd-add 'DOS-MZ '("DOS-MZ" "MS-DOS, OS/2 or MS Windows executable") "Object Machine Code"
           'bin
           `(:name (lit ("exe") ext)
                   :contents (lit ,dos-mz-header 0)
                   :precog contents-recog)
           'hexl-mode 'gen `((:execute "wine")) nil "http://en.wikipedia.org/wiki/DOS_MZ_executable")

  ;; See: http://www.codeproject.com/kb/system/inject2exe.aspx
  ;; PE-formatet is based on the COFF-formatet which is used in Unix.
  (fmd-add 'PE/COFF '("PE/COFF" "Portable Executable") "Object Machine Code"
           'bin
           `(:name (lit ("cpl" "exe" "dll" "ocx" "sys" "scr" "drv" "obj") ext)
                   :contents (and (lit ,dos-mz-header 0)
                                  (lit ,pe-magic-header #x80))
                   :extend 'DOS-MZ)
           'hexl-mode 'gen `((:execute "wine")) nil "http://en.wikipedia.org/wiki/Portable_Executable")

  (fmd-add 'Kernel-Object "Kernel Object" "Object Machine Code"
           'bin
           `(:name (lit "ko" ext)
                   :contents (lit ,elf-magic-header 0)
                   :extend ELF)
           'hexl-mode 'gen nil)
  (fmd-add 'Shared-Library-Object "Object Code" "Object Code"
           'bin
           `(:name (lit "so" ext)
                   :contents (lit ,elf-magic-header 0)
                   :extend ELF)
           'hexl-mode 'gen `((:link ("ld" "libtool"))))
  (fmd-add 'Static-Library-Archive "Archive of Object Code" "Archive of Object Code"
           'bin
           `(:name (lit "a" ext))
           'hexl-mode 'gen `((:link ("ld" "libtool"))))
  (fmd-add 'GNU-prof-performance-data "Code Profile Data" "Code Profile Data"
           'bin
           `(:name (lit "gmon.out" full))
           'hexl-mode 'gen `((:create "gprof"))) ;gprof

  (fmd-add 'GPCH "GPCH" "GCC Precompiled Header" 'bin
           `(:name (re ("gp?ch") ext)
                   :contents (re "gpch\\([Co+O]\\)\\([0-9]\\{3\\}\\)" 0) ;either C,Objective-C,C++ or Objective-C++ and 3-digit version
                   :precog contents-recog
                   :matches (lambda (filename &optional build-type compilation-window working-directory args)
                              ;;(language version)
                              (concat (let ((ch (string-to-char (match-string 1))))
                                        (case ch
                                          (?C "C")
                                          (?o "Objective-C")
                                          (?+ "C++")
                                          (?O "Objective-C++")
                                          (otherwise "Unknown-Language")))
                                      "-"
                                      (match-string 2))))
           nil 'man nil)

  ;; ================ IDE Tags/Databases ================

  ;; A state file, containing dependency information between source files
  ;; and class definitions, which can be used by the compiler during
  ;; minimal rebuild and incremental compilation.
  (fmd-add 'VSIDB '("VSIDB" "Visual Studio Intermediate Debug File") "Compilation Object"
           'bin
           `(:name (lit ("idb") ext)
                   :contents (lit "Microsoft C/C++ program database" 0))
           'hexl-mode 'gen nil)

  (fmd-add 'Borland-IDE '("Borland-IDE" "Borland C++ Project File") "IDE Project"
           'bin
           `(:name (lit ("ide") ext)
                   :contents (lit "\x42\x6f\x72\x6c\x61\x6e\x64\x20\x43\x2b\x2b\x20\x50\x72\x6f\x6a\x65\x63\x74\x20\x46\x69\x6c\x65\x0a\x00\x1a" 0))
           'hexl-mode 'gen nil)

  ;; ================ Symbol Tags ================

  (fmd-add 'VCPCH '("VCPCH" "VCPCH") "Visual Studio PreCompiled Header"
           'bin
           `(:name (lit ("pch") ext)
                   :contents (lit "VCPCH0" 0))
           'hexl-mode 'gen nil nil "http://filext.com/file-extension/PCH")

  (fmd-add 'EBrowse "Tags-Db" "Tags-Db" 'bin
           `(:name (lit "BROWSE" full))
           nil 'gen nil)
  (fmd-add 'Idutils "Tags-Db" "Tags-Db" 'bin
           `(:name (lit "ID" full)
                   :contents (lit "\311\304" 0))
           nil 'gen nil "mkid")
  (fmd-add 'Emacs-tags "Tags-Db" "Tags-Db" 'bin
           `(:name (lit "TAGS" full)
                   :contents (lit "\C-l" 0))
           nil 'gen `((:update ,etags-update-command)))
  (fmd-add 'Exuberant-Ctags "Tags-Db" "Tags-Db" 'bin
           `(:name (lit "tags" full)
                   :contents (lit ,ectags-magic 0)
                   :precog contents-recog)
           nil 'gen `((:update ,ectags-update-command)))
  (fmd-add 'CScope "Tags-Db" "Tags-Db" 'bin
           `(:name (lit ("cscope.out" "cscope.in.out" "cscope.po.out") full)
                   )
           nil 'gen nil `((:create "cscope -b -k")))

  (fmd-add 'Berkeley-DB "Database" "Database" 'bin `(:contents (lit "b1\5\0" 0)
                                                               :precog contents-recog)
           nil 'gen nil)

  (fmd-add 'GNU-GLOBAL-Directory "GNU-GLOBAL" "Tags" 'dir `file-gnu-global-directory-p
           nil 'man `((:global-create "gtags")
                      (:global-update "global -u")))

  (fmd-add 'GNU-GLOBAL "GNU GLOBAL Database" "Tags-Db" 'bin
           `(:name (lit ("GTAGS" "GRTAGS" "GPATH" "GSYMS") full)
                   :contents (lit "b1\5\0" 0))
           nil 'gen nil)
  (fmd-add 'GNU-GLOBAL-GTAGS "GNU GLOBAL Tags Defs" "Tags-Db" 'bin
           `(:name (lit "GTAGS" full)
                   :contents (lit "b1\5\0" 0))
           nil 'gen nil)
  (fmd-add 'GNU-GLOBAL-GRTAGS "GNU GLOBAL Tags Refs" "Tags-Db" 'bin
           `(:name (lit "GRTAGS" full)
                   :contents (lit "b1\5\0" 0))
           nil 'gen nil)
  (fmd-add 'GNU-GLOBAL-GPATH "GNU GLOBAL Paths" "Tags-Db" 'bin
           `(:name (lit "GPATH" full)
                   :contents (lit "b1\5\0" 0))
           nil 'gen nil)
  (fmd-add 'GNU-GLOBAL-GSYMS "GNU GLOBAL Symbols" "Tags-Db" 'bin
           `(:name (lit "GSYMS" full)
                   :contents (lit "b1\5\0" 0))
           nil 'gen nil)

  ;; CEDET Semantic Database (SemanticDB)
  (fmd-add 'Semantic-Cache "Tags-Db" "Tags-Db" 'txt
           `(:name (re "\\.?semantic.cache" full)
                   :contents (re ";; Object .*\n;; SEMANTICDB Tags save file" 0)
                   :precog contents-recog)
           nil 'gen nil)

  ;; Project
  ;; `[Project "Project" "Project Root Directory" dir (file-project-root-directory-p)
  ;;           nil gen nil]

  ;; Version Control
  (fmd-add 'VC-Db-Dir "VC-Db" "VC-Database" 'dir
           `(:name (lit ,vc-directory-exclusion-list full))
           nil 'gen nil) ;TODO: Must be case-sensitive! (let (case-fold-flag) ..)
  (fmd-add 'GIT-Ignore "GIT Ignore" "VC-Config" 't
           `(:name (lit ".gitignore" full))
           nil 'gen nil)
  (fmd-add 'Version-Controlled-Directory "VC" "VC" 'dir `file-vc-root-directory-p
           nil 'man
           `((:vc-dir (lambda (filename &optional build-type compilation-window working-directory args) (vc-dir filename)))
             (:vc-update (lambda (filename &optional build-type compilation-window working-directory args) (vc-update filename)))))

  (fmd-add 'Ubuntu-Mirror-Root "Ubuntu Mirror" "Ubuntu Mirror" 'dir `file-ubuntu-mirror-root-directory-p
           nil 'gen `((:sync (lambda (filename &optional build-type compilation-window working-directory args)
                               (shell-command (format "debmirror %s "
                                                      (faze (file-name-directory filename) 'file)))))))

  ;; Compressed
  (fmd-add 'CompressedZ "CompressedZ" "Compressed" 'box
           `(:name (lit ("z") ext)
                   :contents (lit "\037\235" 0))
           nil 'gen nil)
  (fmd-add 'GNU-zip "GNU-Zip" "Compressed" 'box
           `(:name (lit ("gz" "gzip" "dz") ext)
                   :contents (lit "\037\213" 0))
           nil 'gen nil)
  (fmd-add 'BZip "BZip" "Compressed" 'box
           `(:name (lit ("bzip2" "bz" "bz2" "tbz2") ext)
                   :contents (lit "BZh" 0))
           nil 'gen nil)
  (fmd-add 'XZ "XZ/7-Zip)" "Compressed" 'box
           `(:name (lit ("xz" "txz"
                         "7z" "t7z"
                         "lzma" "tlzma"
                         "lz" "tlz") ext)
                   :contents (lit ("\3757zXZ\0") 0)
                   :mime "application/x-7z-compressed")
           nil 'gen nil)
  (fmd-add 'LZIP "LZip" "Compressed" 'box
           `(:name (lit ("lzip") ext))
           nil 'gen nil)
  (fmd-add 'LZX "LZX" "Compressed" 'box
           `(:name (lit ("lzx") ext)
                   :contents (lit ("LZX")))
           nil 'gen nil)
  (fmd-add 'SZip "Compressed" "Compressed" 'box
           `(:name (lit ("szip") ext)
                   :contents (lit ("SZ\x0a\4")))
           nil 'gen nil)
  (fmd-add 'Zip "pkZip" "Compressed" 'box
           `(:name (lit ("zip" "zipx") ext)
                   :contents (lit "\x50\x4b\x03\x04" 0))
           nil 'gen nil nil "http://en.wikipedia.org/wiki/ZIP_(file_format)")

  (fmd-add 'ISC "Install Shield v5.x or 6.x compressed file" "Compressed" 'box
           `(:name (lit ("cab" "hdr") ext)
                   :contents (lit "ISc(" 0)
                   :precog name-and-contents-recog)
           nil 'gen nil nil nil)
  (fmd-add 'MSCF-CAB "Microsoft cabinet file" "Compressed" 'box
           `(:name (lit ("cab") ext)
                   :contents (lit "MSCF" 0)
                   :precog name-and-contents-recog)
           nil 'gen nil nil nil)
  (fmd-add 'MSCF-PPZ "Powerpoint Packaged Presentation" "Compressed" 'box
           `(:name (lit ("ppz") ext)
                   :contents (lit "MSCF" 0)
                   :precog name-and-contents-recog)
           nil 'gen nil nil nil)
  (fmd-add 'MSCF-SNP "Microsoft Access Snapshot Viewer file" "Compressed" 'box
           `(:name (lit ("snp") ext)
                   :contents (lit "MSCF" 0)
                   :precog name-and-contents-recog)
           nil 'gen nil nil nil)

  (fmd-add 'Compressed "Compressed" "Group" 't `(:generalize (CompressedZ GNU-zip BZip XZ LZIP LZX SZip Zip ISC MSCF-CAB MSCF-PPZ MSCF-SNP))
           nil 'gen nil)

  ;; TODO: Replace with super class key `Image'
  (fmd-add 'Bitmap-Image "Bitmap Image" "Binary Data" 'bin nil
           nil 'gen nil)

  ;; Bitmap Images
  ;; See: http://www.astro.keele.ac.uk/oldusers/rno/Computing/File_magic.html

  (fmd-add 'Apple-Icon "Apple-Icon" "Bitmap Images" 'bin
           `(:name (lit ("icns") ext)
                   :contents (lit "icns" 0))
           nil 'gen `((:show ,ftype-image-show)) nil "http://en.wikipedia.org/wiki/Apple_Icon_Image")

  (fmd-add 'ICO-Icon "ICO-Icon" "Bitmap Images" 'bin
           `(:name (lit ("ico") ext)
                   :contents (lit "\x00\x00\x01\x00" 0))
           nil 'gen `((:show ,ftype-image-show)) nil "http://en.wikipedia.org/wiki/ICO_(file_format)")
  (fmd-add 'ICO-Cursor "ICO-Cursor" "Bitmap Images" 'bin
           `(:name (lit ("ico") ext)
                   :contents (lit "\x00\x00\x02\x00" 0))
           nil 'gen `((:show ,ftype-image-show)))

  (fmd-add 'BMP '("BMP" "Bitmap") "Bitmap Image" 'bin
           `(:name (lit ("bmp" "dib") ext)
                   :contents (lit "BM" 0)
                   :precog contents-recog)
           nil 'gen `((:show ,ftype-image-show)) nil "http://en.wikipedia.org/wiki/BMP_file_format")

  (fmd-add 'XCF '("XCF" "GIMP XCF (eXperimental Computing Facility)") "Bitmap Image" 'bin

           `(:name (lit ("xcf") ext)
                   :contents (lit "gimp xcf" 0)
                   :precog contents-recog)
           nil 'gen `((:show "gimp")) nil "http://en.wikipedia.org/wiki/XCF_(file_format)")

  ;; TODO: Support typical directories: '(:system-dir "/usr/share/inkscape/palettes/" :config-dir "~/.config/inkscape/")
  (fmd-add 'GPL '("GPL" "GIMP Palette") "Palette" 'txt

           `(:name (lit ("gpl") ext)
                   :contents (lit "GIMP Palette" 0)
                   :precog contents-recog)
           nil 'gen `((:show ("gimp" "inkscape"))))

  (fmd-add 'JPEG '("JPEG" "Joint Pictures Expert Group") "Bitmap Image" 'bin
           `(:name (lit ("jpg" "jpeg" "jpe") ext)
                   :contents (lit ,jpeg-magic-header 0)
                   :precog contents-recog)
           nil 'gen `((:show ,ftype-image-show)))
  (fmd-add 'JPEG-2000 "JPEG 2000" "Bitmap Image" 'bin
           `(:name (lit ("jp2" "j2k") ext)
                   :contents (lit "\x00\x00\x00\x0C\x6A\x50\x20\x20\x0D\x0A" 0)
                   :precog contents-recog)
           nil 'gen `((:show ,ftype-image-show)))

  (fmd-add 'PNG '("PNG" "Portable Network Graphics") "Bitmap Image" 'bin
           `(:name (lit ("png") ext)
                   :contents (lit "\x89PNG\x0d\x0a\x1a\x0a" 0)
                   :precog contents-recog)
           nil 'gen `((:show ,ftype-image-show)))
  (fmd-add 'GIF '("GIF" "Graphical Interface Format") "Bitmap Image" 'bin
           `(:name (lit ("gif") ext)
                   :contents (lit "GIF8" 0)
                   :precog contents-recog)
           nil 'gen `((:show ,ftype-image-show)))
  (fmd-add 'TIFF "TIFF" "Bitmap Image" 'bin
           `(:name (lit ("tiff" "tif") ext)
                   :contents (lit "\x4d\x4d\x00\x2a" 0)
                   :precog contents-recog)
           nil 'gen `((:show ,ftype-image-show)))

  (fmd-add 'XPM '("XPM" "X PixMap") "Bitmap Image" 'bin
           `(:name (lit ("xpm") ext)
                   :contents (lit "/* XPM */" 0)
                   :precog contents-recog)
           nil 'gen `((:show ,ftype-image-show)))
  (fmd-add 'XBM '("XBM" "X BitMap") "Bitmap Image" 'bin
           `(:name (lit ("xbm") ext))
           nil 'gen `((:show ,ftype-image-show)))

  (fmd-add 'PBM "PBM" "Bitmap Image" 'bin
           `(:name (lit ("pbm") ext))
           nil 'gen `((:show ,ftype-image-show)))
  (fmd-add 'PGM "PGM" "Bitmap Image" 'bin
           `(:name (lit ("pgm") ext))
           nil 'gen `((:show ,ftype-image-show)))
  (fmd-add 'PPM "PPM" "Bitmap Image" 'bin
           `(:name (lit ("ppm") ext))
           nil 'gen `((:show ,ftype-image-show)))
  (fmd-add 'PNM "PNM" "Bitmap Image" 'bin
           `(:name (lit ("pnm") ext))
           nil 'gen `((:show ,ftype-image-show)))

  (fmd-add 'GPG "GPG" "Bitmap Image" 'bin
           `(:name (lit ("gpg") ext))
           nil 'gen `((:show ,ftype-image-show)))

  (fmd-add 'DjVu "DjVu" "DjVU" 'bin
           `(:name (lit ("djv" "djvu") ext)
                   :contents (lit ("AT&TFORM\0") 0)
                   :mime "image/vnd.djvu")
           nil 'gen `((:show ,ftype-image-show)))

  ;; Vector Images
  (fmd-add 'SVG '("SVG" "Scalable Vector Graphics") "Vector Image" 'txt
           `(:name (lit ("svg") ext))
           'xml-mode 'man nil)
  (fmd-add 'REJ "REJ" "Vector Image" 't
           `(:name (lit ("rej") ext))
           nil 'man nil)

  ;; Open Documents
  (fmd-add 'ODT '("ODT" "Open Document Type") "Document" 'bin
           `(:name (lit ("odt") ext))
           nil 'gen `((:show ,(open-writer))
                      (:edit ,(open-writer))))
  (fmd-add 'RTF '("RTF" "Rich Text Format") "Document" 'bin
           `(:name (lit ("rtf") ext))
           nil 'gen `((:show ("abiword" ,(open-writer)))))
  (fmd-add 'DOCX '("DOCX" "Microsoft Office Open XML Format Document") "Document" 'bin
           `(:name (lit ("docx") ext))
           nil 'gen `((:show ,(open-writer))))
  (fmd-add 'PDF '("PDF" "Portable Document Format") "Document" 'bin
           `(:name (lit ("pdf") ext))
           nil 'gen `((:show ,ftype-document-show)))
  (fmd-add 'DVI '("DVI" "Device independent file format ") "Document" 'bin
           `(:name (lit ("dvi") ext)
                   :contents (lit ("\xf7\x02") 0))
           nil 'gen `((:show ,ftype-document-show)) nil "http://en.wikipedia.org/wiki/Device_independent_file_format")
  (fmd-add 'PostScript "Postscript" "Document" 'txt
           `(:name (lit ("ps" "eps") ext))
           nil 'man `((:show ,ftype-document-show)))

  ;; Microsoft Documents
  (fmd-add 'Microsoft-Word '("Word" "Microsoft Word Document") "Document" 'bin
           `(:name (lit ("doc") ext))
           nil 'gen `((:show "antiword")
                      (:edit ,(open-writer))))

  ;; Spreadsheet	.xls	Main spreadsheet format which holds data in worksheets, charts, and macros
  ;; Add-in (VBA)	.xla	Adds custom functionality; written in VBA
  ;; Toolbar	.xlb	The file extension where Microsoft Excel custom toolbar settings are stored.
  ;; Chart	.xlc	A chart created with data from a Microsoft Excel spreadsheet that only saves the chart. To save the chart and spreadsheet save as .XLS. XLC is not supported in Excel 2007 or in any newer versions of Excel.
  ;; Dialog	.xld	Used in older versions of Excel.
  ;; Archive	.xlk	A backup of an Excel Spreadsheet
  ;; Add-in (DLL)	.xll	Adds custom functionality; written in C++/C, Visual Basic, Fortran, etc. and compiled in to a special dynamic-link library
  ;; Macro	.xlm	A macro is created by the user or pre-installed with Excel.
  ;; Template	.xlt	A pre-formatted spreadsheet created by the user or by Microsoft Excel.
  ;; Module	.xlv	A module is written in VBA (Visual Basic for Applications) for Microsoft Excel
  ;; Library	.DLL	Code written in VBA may access functions in a DLL, typically this is used to access the Windows API
  ;; Workspace	.xlw	Arrangement of the windows of multiple Workbooks

  (fmd-add 'Microsoft-Excel '("Excel" "Microsoft Excel Document") "Document" 'bin
           `(:name (lit ("xls" "xla" "xlb" "xlc" "xld" "xlk" "xll" ".xlm" ".xlt" ".xlv" ".xlw") ext)
                   :contents (lit ,microsoft-office-applications-magic-header 0))
           nil 'gen `((:show ,(open-calc))))
  (fmd-add 'Microsoft-Powerpoint '("Powerpoint" "Microsoft Powerpoint Document") "Document" 'bin
           `(:name (lit ("ppt") ext)
                   :contents (lit ,microsoft-office-applications-magic-header 0))
           nil 'gen `((:show ,(open-impress))))
  (fmd-add 'OOXML-Excel '("Office Open XML Excel" "Microsoft Excel Document") "Document" 'bin
           `(:name (lit ("xlsx" "xlsm" "xlsb" "xltm" "xlam") ext)
                   :specialize XML)
           nil 'gen `((:show ,(open-calc))))

  (fmd-add 'mdb "" "" 't
           `(:name (lit ("mdb") ext))
           nil 'gen nil)
  (fmd-add 'adb "" "" 't
           `(:name (lit ("adb") ext))
           nil 'gen nil)

  ;; Fonts
  (fmd-add 'Vector-Font "Vector Font" "Vector Font" 'bin
           `(:name (lit ("sfd" "sfdir" "ttf" "otf") ext))
           nil 'gen `((:show "gnome-font-viewier")
                      (:edit "fontforge")))

  ;; Certificate
  (fmd-add 'Cryptographic-Certificate "Certificate" "Text" 'txt
           `(:name (lit ("crt" "pem" "0") ext)
                   :contents (lit ("-----BEGIN CERTIFICATE-----") 0)
                   ;; TODO: Make this work
                   ;; :contents (and (lit ("-----BEGIN CERTIFICATE-----") 0)
                   ;;                (lit ("-----END CERTIFICATE-----") -1))
                   :precog contents-recog)
           nil 'gen nil)
  ;; Signature
  (fmd-add 'Cryptographic-Signature "Signature" "Text" 'txt
           `(:name (lit ("sig") ext)
                   :contents (re ("-----BEGIN \\([A-Z]+\\) SIGNATURE-----") 0)
                   ;; TODO: Make this work
                   ;; :contents (and (lit ("-----BEGIN \\([A-Z]+\\) SIGNATURE-----") 0)
                   ;;                (lit ("-----BEGIN \\([A-Z]+\\) SIGNATURE-----") -1))
                   :precog contents-recog)
           nil 'gen nil)

  ;; Disk Images
  (fmd-add 'ISO '("ISO" "ISO (9960) Optical Disk Image") "Disk Image" 'bin
           `(:name (lit ("iso" "img") ext)
                   :contents (and (lit "CD001" 32769)
                                  (not (lit "NSR0" 38913)))
                   :extend CD001)
           nil 'gen nil)
  (fmd-add 'UDF '("UDF" "UDF Optical Disk Image") "Disk Image" 'bin

           `(:name (lit ("udf") ext)
                   :contents (and (lit "CD001" 32769)
                                  (lit "NSR0" 38913))
                   :extend CD001)
           nil 'gen nil)
  (fmd-add 'VirtualBox-Disk-Image "VirtualBox Disk Image" "Disk Image" 'bin

           `(:name (lit ("vdi") ext)
                   :contents (lit "<<< Sun VirtualBox Disk Image >>>\n\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0" 0)
                   :precog contents-recog)
           nil 'gen `((:execute "VirtualBox")))

  ;; Archives
  (fmd-add 'AR "AR" "Archive" 'bin
           `(:name (lit ("ar") ext))
           nil 'gen
           `((:extract (lambda (filename &optional build-type compilation-window working-directory args) (format "ar xf %s " filename)))
             (:list (lambda (filename &optional build-type compilation-window working-directory args) (format "ar tf %s " filename)))))
  (fmd-add 'TAR '("TAR" "Tape Archive") "Archive" 'bin
           `(:name (lit ("tar") ext)
                   :contents (lit ("ustar") 257))
           nil 'gen
           `((:extract (lambda (filename &optional build-type compilation-window working-directory args) (format "tar xf %s " filename)))
             (:list (lambda (filename &optional build-type compilation-window working-directory args) (format "tar tf %s " filename)))))

  ;; TODO: Defiene `GZIP-TAR' `BZIP-TAR' `XZ-TAR' and turn `Compressed-TAR' into a `:generalize' of these.
  (fmd-add 'Compressed-TAR '("Compressed-TAR" "Compressed Tape Archive") "Compressed-Archive" 'bin
           `(:name (lit ("tgz" "tar.gz" "tar.z" "tar.Z"
                         "tbz" "tbz2" "tar.bz" "tar.bz2"
                         "txz" "tar.xz"
                         ) ext)
                   )
           nil 'gen
           `((:extract (lambda (filename &optional build-type compilation-window working-directory args) (format "tar xf %s " filename)))
             (:list (lambda (filename &optional build-type compilation-window working-directory args) (format "tar tf %s " filename)))))
  (fmd-add 'JAR '("JAR" "Java Archive") "Archive" 'bin
           `(:name (lit ("jar") ext))
           nil 'gen
           `((:extract (lambda (filename &optional build-type compilation-window working-directory args) (format "jar xf %s " filename)))
             (:list (lambda (filename &optional build-type compilation-window working-directory args) (format "tar xf %s " filename)))))

  ;; TODO: Support File Set: X.rar, x.r00, x.r01, x.r02, ... and check that their name and content-CRC32 matches contents of X.sfv
  ;; Use function `file-rar-set-count'
  (fmd-add 'RAR '("RAR" "RAR Archive") "Archive" 'bin
           `(:name (lit ("rar") ext))
           nil 'gen
           `((:extract (lambda (filename &optional build-type compilation-window working-directory args) (format "rar e %s " filename)))
             (:list (lambda (filename &optional build-type compilation-window working-directory args) (format "rar l %s " filename)))))
  (fmd-add 'Archive "Archive" "Group" 't `(:generalize (AR TAR JAR RAR))
           nil 'gen nil)
  (fmd-add 'Compressed-Archive "Compressed-Archive" "Group" 't `(:generalize (Compressed-TAR))
           nil 'gen nil)

  (fmd-add 'M3U "M3U" "Multimedia Playlist" 'txt
           `(:name (lit ("m3u") ext))
           nil 'gen nil nil "http://en.wikipedia.org/wiki/M3U")

  (fmd-add 'M3U8 "M3U8" "Multimedia Playlist (UTF-8)" 'utf-8
           `(:name (lit ("m3u8") ext))
           nil 'gen nil nil '("http://en.wikipedia.org/wiki/M3U8"
                              "http://filext.com/file-extension/M3U8"))

  (fmd-add 'WAV "WAV" "Waveform Audio File Format" 'bin
           `(:name (lit ("wav") ext)
                   :contents (re ("RIFF....WAVEfmt") 0)
                   :precog contents-recog)
           nil 'gen nil nil '("http://en.wikipedia.org/wiki/WAV"
                              "http://en.wikipedia.org/wiki/Resource_Interchange_File_Format"))

  (fmd-add 'AMR "AMR" "Adaptive Multi-Rate audio codec" 'bin
           `(:name (lit ("amr") ext)
                   :contents (lit "#!AMR\x0a" 0)
                   :precog contents-recog)
           nil 'gen nil nil '("http://en.wikipedia.org/wiki/Adaptive_Multi-Rate_audio_codec"))

  (fmd-add 'MP3 "MP3" "MPEG2 Layer 3" 'bin
           `(:name (lit ("mp3") ext)
                   :contents (lit ("ID3") 0)
                   :precog contents-recog)
           nil 'gen nil nil "http://en.wikipedia.org/wiki/MP3")

  (fmd-add 'KOZ "KOZ" "Sprint Music Store audio file (for mobile devices)" 'bin
           `(:name (lit ("koz") ext)
                   :contents (lit ("ID3\x03\x00\x00\x00") 0)
                   :precog contents-recog)
           nil 'gen nil nil nil)

  (fmd-add 'CRW "CRW" "Canon digital camera RAW file" 'bin
           `(:name (lit ("crw") ext)
                   :contents (lit ("\x49\x49\x1A\x00\x00\x00\x48\x45\x41\x50\x43\x43\x44\x52\x02\x00") 0)
                   :precog contents-recog)
           nil 'gen nil nil nil)

  (fmd-add 'TGA "TGA" "Truevision Targa Graphic file" 'bin
           `(:name (lit ("tga") ext)
                   :contents (lit ("\x54\x52\x55\x45\x56\x49\x53\x49\x4F\x4E\x2D\x58\x46\x49\x4C\x45\x2E\x00") end)
                   :precog contents-recog)
           nil 'gen nil nil nil)

  (fmd-add 'PIC "PIC" "IBM Storyboard bitmap file" 'bin
           `(:name (lit ("pic") ext)
                   :contents (lit ("0") 0)
                   :precog name-and-contents-recog)
           nil 'gen nil nil nil)
  (fmd-add 'PIF "PIF" "Windows Program Information File" 'bin
           `(:name (lit ("pif") ext)
                   :contents (lit ("0") 0)
                   :precog name-and-contents-recog)
           nil 'gen nil nil nil)
  (fmd-add 'SEA "SEA" "Mac Stuffit Self-Extracting Archive" 'bin
           `(:name (lit ("sea") ext)
                   :contents (lit ("0") 0)
                   :precog name-and-contents-recog)
           nil 'gen nil nil nil)
  (fmd-add 'YTR "YTR" "IRIS OCR data file" 'bin
           `(:name (lit ("ytr") ext)
                   :contents (lit ("0") 0)
                   :precog name-and-contents-recog)
           nil 'gen nil nil nil)

  (fmd-add 'MPEG-v4 "MPEG-v4" "MPEG-v4" 'bin
           `(:name (lit ("m4a") ext)
                   :contents (lit ("\x00\x00\x00\x20\x66\x74\x79\x70\x4d\x34\x41\x20\x00\x00\x00\x00") 0)
                   :precog contents-recog)
           nil 'gen nil)

  (fmd-add 'EBML "EBML" "Extensible Binary Meta Language" 'bin
           `(:name (lit ("ebml") ext)
                   :contents (lit "\x1a\x45\xdf\xa3" 0))
           nil 'gen nil nil "http://en.wikipedia.org/wiki/Extensible_Binary_Meta_Language")

  (fmd-add 'Matroska "MKV" "Matroska Media Container" 'bin
           `(:name (lit ("mkv" "mka" "mks") ext)
                   :contents (lit "\x1a\x45\xdf\xa3" 0)
                   :extend EBML)
           nil 'gen nil nil "http://en.wikipedia.org/wiki/Matroska")

  (fmd-add 'AVI "AVI" "Audio Video Interleave" 'bin
           `(:name (lit ("avi") ext)
                   )
           nil 'gen nil nil "http://en.wikipedia.org/wiki/Audio_Video_Interleave")

  (fmd-add 'MP4 "MP4" "MPEG-4 Part 14" 'bin
           `(:name (lit ("mp4") ext)
                   :contents (re "RIFF[.\n]{4,4}AVILIST" 0))
           nil 'gen nil)

  (fmd-add 'SFV "SFV" "Simple file verification" 'txt
           `(:name (lit ("sfv") ext)
                   :contents (re (".*[0-9]+$") 0))
           nil 'gen nil nil "http://en.wikipedia.org/wiki/Simple_file_verification")

  (fmd-add 'Aspell-rowl "Aspell-rowl" "Aspell-rowl" 'bin
           `(:name (lit ("rws") ext)
                   :contents (lit ("aspell default speller rowl") 0))
           nil 'gen nil)

  ;; Note: Put this at the end as fallback *after* language-specific matchers have been tried.
  (fmd-add 'Env-Script "Env" "Script Code" 'txt
           `(:name (lit "sh" ext)
                   :contents (re "#![[:space:]]*\\(/usr/bin/env[[:space:]]+\\)" 0 nil ,fmd-script-type-magic-limit)
                   :precog name-or-contents-recog)
           'sh-mode 'man `((:execute "sh")))

  ;; (Un)Editable File
  (fmd-add 'Uneditable "Uneditable" "Group" 't `(:generalize ,ftypes-uneditable-file-keys) nil 'gen nil)
  (fmd-add 'Editable "Editable" "Group" 't `(:not Uneditable) nil 'gen nil)

  ;; (Un)Editable Directory
  (fmd-add 'Uneditable-Dir "Uneditable Directory" "Group" 'dir `(:generalize ,ftypes-uneditable-dir-keys) nil 'gen nil)
  (fmd-add 'Editable-Dir "Editable Directory" "Group" 'dir `(:not Uneditable-Dir) nil 'gen nil)

  ;; Script Files
  (fmd-add 'Any-Script "Any Script" "Group" 't `(:generalize ,ftypes-script-file-keys) nil 'gen nil)
  (fmd-add 'Executable-Script "Executable Script" "Group" 't `(:generalize ,ftypes-executable-script-file-keys) nil 'gen nil)

  (fmd-add 'GUD-Debuggable "GUD Debuggable" "Group" 't `(:generalize ,ftypes-gud-debuggable-file-keys) nil 'gen nil)

  ;; Special Devices
  (fmd-add 'Serial-Device "Serial Device" "Special Device" 'serial
           `(:name (re ("/dev/ttyS[0-9]+") full)) nil 'gen nil)
  (fmd-add 'Block-Device "Block Device" "Special Device" 'block
           `(:name (lit ("/dev/") beg)) nil 'gen nil)

  (delete-dups fmd-types)               ;remove any duplicates

  (setq fmd-types (nreverse fmd-types))
  )

;; ---------------------------------------------------------------------------

(defvar fmd-type-keys nil
  "List of all registered type keys.")

(defvar fmd-type-key-hash (make-hash-table :size (length fmd-types)
                                           :test 'eq) ;Note: equal because we compare symbols
  "Hash table that maps key symbols to its entry in `fmd-types'.")

(defun fmd-remake-types-stat ()
  "Remake statistics about `fmd-types'.
Extracts keys into `fmd-type-keys'.  Remake all Name and Contents
Matchers to lambda-expressions and put them at the GMATCH
position in `fmd-type-key-hash'."
  (setq fmd-type-keys nil)
  (clrhash fmd-type-key-hash)
  (dolist (ftype fmd-types)             ;for each ftype in fmd-types
    (let ((fkey (ftype-key ftype)))
      (setq fmd-type-keys (cons fkey fmd-type-keys))
      (puthash fkey ftype fmd-type-key-hash)
      )))
;; Use: (describe-hash-table 'fmd-type-key-hash)
;; Use: (gethash 'README fmd-type-key-hash)
;; Use: (fmd-get-type 'README)
;; Use: fmd-type-keys

;; ---------------------------------------------------------------------------

(defun fmd-get-type (ksym)
  "Lookup ftype using KSYM and return it."
  (let ((val (gethash ksym fmd-type-key-hash)))
    (unless val
      (message "Warning: Unregistered type key symbol `%s'" ksym)
      (sit-for 1))
    val))
;; Use: (fmd-get-type 'JPEG)
;; Use: (fmd-get-type 'JPG)
;; Use: (fmd-get-type 'README)
;; Use: (fmd-get-type 'C-Header)
;; Use: (fmd-get-type 'C++-Header)
;; Use: (fmd-get-type 'C++-Source)
;; Use: (fmd-get-type 'ELF)
;; Use: (fmd-get-type 'Semantic-Cache)
;; Use: (fmd-get-type 'VC-Db-Dir)
;; Use: (fmd-get-type 'Semantic-Cache)
;; Use: (fmd-get-type 'quote)
;; Use: (fmd-get-type nil)

;; ---------------------------------------------------------------------------

(defvar ftypes-matchers
  (make-hash-table :size (* 10 (length fmd-types))
                   :test 'equal) ;Note: equal because we compare structures
  "Hash table that maps a list of file type strings (KEY) to a
  file or contents matcher taking filename as argument. Note: All
  machers are currently stored in symbolic (non-byte-compiled)
  form.")
;; Use: (describe-hash-table 'ftypes-matchers)
;; Use: (clrhash ftypes-matchers)
;; Use: (gethash '(README name-recog) ftypes-matchers)
;; Use: (gethash '(README contents-recog) ftypes-matchers)
;; Use: (gethash '(README name-or-contents-recog) ftypes-matchers)

(defun fmd-remake-single-matchers ()
  "Remake all Name and Contents Matchers to lambda-expressions
  and put them at the GMATCH position in fmd-table."
  (interactive)
  (clrhash ftypes-matchers)
  (dolist (ftype fmd-types)             ;for each ftype in fmd-types
    (let ((fkey (ftype-key ftype)))
      (fmd-matcher fkey 'name-recog)
      (fmd-matcher fkey 'exist-recog)
      (fmd-matcher fkey 'contents-recog)
      (fmd-matcher fkey 'name-or-contents-recog)
      (fmd-matcher fkey 'name-and-contents-recog)
      )))

;; ---------------------------------------------------------------------------

;; ToDo: Merge with `regexp-gen-literal'.
(defun fmd-match-regexp (val &optional regexp-flag embrace-flag)
  (cond ((stringp val)                 ;format is string
         (if regexp-flag                ;if regexp
             val                       ;just return it
           (regexp-quote val)))        ;otherwise quote it
        ((eq 'rx (car val))            ;and equal to 'rx
         (eval (if regexp-flag          ;if regexp
                   `(rx ,@(cdr val))         ;alt of regexps
                 `(rx (regexp ,@(cdr val)))))) ;alt of regexp-quoted strings
        ((sequence-of-strings-p val)   ;format is sequence of strings
         (if regexp-flag                ;if regexp
             (regexp-from-alts val embrace-flag) ;alt of regexps
           (regexp-quote-alts val)))
        ))
;; Use: (fmd-match-regexp '("a" "b") nil t)
;; Use: (fmd-match-regexp '("a." "b.") nil t)
;; Use: (fmd-match-regexp '("a." "b.") t t)
;; Use: (fmd-match-regexp '(rx "." "b") t t)
;; Use: (fmd-match-regexp '(rx (regexp ".") ".") t t)

(defun fmd-nmatch-expr-lit-list (nmatch val ctx casef)
  (let ((uval (regexp-opt val)))
    (when uval
      (cond ((symbolp ctx) ;symbol context
             (case ctx
               (any `(let ((case-fold-search ,casef)) (string-match ,uval relname)))
               ((beg +0) `(let ((case-fold-search ,casef)) (string-match ,(concat "\\`" uval) relname)))
               ((end -1) `(let ((case-fold-search ,casef)) (string-match ,(concat uval "\\'") relname)))
               (ext `(let ((case-fold-search ,casef)) (string-match ,(concat "\\." uval "\\'") relname)))
               (bol `(let ((case-fold-search ,casef)) (string-match ,(concat "^" uval) relname)))
               (eol `(let ((case-fold-search ,casef)) (string-match ,(concat uval "$") relname)))
               (full `(let ((case-fold-search ,casef)) (string-match ,(concat "\\`" uval "\\'") relname)))
               (t `(let ((case-fold-search ,casef)) (string-match ,uval relname))) ;default to anywhere in relname
               ))
            ((numberp ctx) ;number context
             (error "Context numberp %s not yet implemented for nmatch %s!" ctx nmatch))
            ((listp ctx)
             (error "Context listp (%s) not yet implemented for nmatch %s!" ctx nmatch)
             (cond
              ((list-of-numbers-p ctx)
               (error "Context list-of-numbers-p (%s) not yet implemented for nmatch %s!" ctx nmatch))
              ))
            (t
             (error "Context other (%s) not yet implemented for nmatch %s!" ctx nmatch))
            ))))

(defun fmd-nmatch-expr-lit-string (nmatch val ctx casef)
  (cond ((symbolp ctx) ;symbol context
         (case ctx
           (any `(let (case-fold-search ,casef)
                   (string-match ,(regexp-quote val) relname)))
           ((beg +0) `(eq t (string-prefix-p ,val relname ,casef)))
           ((end -1) `(eq t (string-suffix-p ,val relname ,casef)))
           (ext `(eq t (ignore-errors (compare-strings relname (- (length relname)
                                                                  ,(1+ (length val))) nil
                                                                  ,(concat "." val) 0 nil ,casef))))
           (bol `(let (case-fold-search ,casef)
                   (string-match ,(concat "^" (regexp-quote val)) relname)))
           (eol `(let (case-fold-search ,casef)
                   (string-match ,(concat (regexp-quote val) "$") relname)))
           (full (if casef
                     `(eq t (compare-strings relname 0 nil
                                             ,val 0 nil t))
                   `(string-equal relname ,val)))
           (t `(let (case-fold-search ,casef)
                 (string-match ,(regexp-quote val) relname))) ;default to anywhere in relname
           ))
        ((numberp ctx) ;number context
         (error "Context numberp %s not yet implemented for nmatch %s!" ctx nmatch))
        ((listp ctx)
         (error "Context listp (%s) not yet implemented for nmatch %s!" ctx nmatch)
         (cond
          ((list-of-numbers-p ctx)
           (error "Context list-of-numbers-p (%s) not yet implemented for nmatch %s!" ctx nmatch))
          ))
        (t
         (error "Context other (%s) not yet implemented for nmatch %s!" ctx nmatch))
        ))

(defun fmd-nmatch-expr-re-string (nmatch val ctx casef)
  (when val
    (cond ((symbolp ctx) ;symbol context
           (case ctx
             (any `(let ((case-fold-search ,casef)) (string-match ,val relname)))
             ((beg +0) `(let ((case-fold-search ,casef)) (string-match ,(concat "\\`" val) relname)))
             ((end -1) `(let ((case-fold-search ,casef)) (string-match ,(concat val "\\'") relname)))
             (ext `(let ((case-fold-search ,casef)) (string-match ,(concat "\\." val "\\'") relname)))
             (bol `(let ((case-fold-search ,casef)) (string-match ,(concat "^" val) relname)))
             (eol `(let ((case-fold-search ,casef)) (string-match ,(concat val "$") relname)))
             (full `(let ((case-fold-search ,casef)) (string-match ,(concat "\\`" val "\\'") relname)))
             (t `(let ((case-fold-search ,casef)) (string-match ,val relname))) ;default to anywhere in relname
             ))
          ((numberp ctx) ;number context
           (error "Context numberp %s not yet implemented for nmatch %s!" ctx nmatch))
          ((listp ctx)
           (error "Context listp (%s) not yet implemented for nmatch %s!" ctx nmatch)
           (cond
            ((list-of-numbers-p ctx)
             (error "Context list-of-numbers-p (%s) not yet implemented for nmatch %s!" ctx nmatch))
            ))
          (t
           (error "Context other (%s) not yet implemented for nmatch %s!" ctx nmatch))
          )))

(defun fmd-nmatch-expr (nmatch &optional expr-fmt)
  "Construct a File Name Matcher Expression using NMATCH.
If EXPR-FMT is t return expression only otherwise lambda expression."
  (let ((expr
         (if (functionp nmatch)                 ;if already a function
             `(,nmatch filename)                ;return its expression directly
           (let* ((fmt (fmatch-fmt nmatch))     ;format
                  (val (fmatch-val nmatch))     ;value
                  (ctx (fmatch-ctx nmatch))     ;context
                  (casef (fmatch-casef nmatch)) ;case-fold
                  (limit (fmatch-limit nmatch)) ;limit
                  )
             (when (and (not (eq fmt 'rx))
                        (listp val) (= 1 (length val))) ;if list with one element
               (setq val (car val)))                    ;pick that element
             (case fmt
               (lit                     ;literal format
                (cond ((listp val)      ;list of literal strings
                       (fmd-nmatch-expr-lit-list nmatch val ctx casef))
                      ((stringp val)    ;literal string
                       (fmd-nmatch-expr-lit-string nmatch val ctx casef)
                       )))
               (re                      ;regexp format
                (fmd-nmatch-expr-re-string nmatch (concat "\\(?:" (fmd-match-regexp val t t) "\\)") ctx casef))
               (rx                      ;`rx' format
                (fmd-nmatch-expr-re-string nmatch (rx-to-string val) ctx casef))
               )))))
    (when expr
      (if expr-fmt expr `(lambda (filename) ,expr))))) ;return plain or lambda expression
;; Use: (fmd-nmatch-expr (ftype-nmatch (fmd-get-type 'MP3)) t)
;; Use: (fmd-nmatch-expr (ftype-nmatch (fmd-get-type 'ELF)) t)
;; Use: (fmd-nmatch-expr (ftype-nmatch (fmd-get-type 'C++)) t)
;; Use: (fmd-nmatch-expr (ftype-nmatch (fmd-get-type 'README)) t)
;; Use: (fmd-nmatch-expr (ftype-nmatch (fmd-get-type 'README)) t)
;; Use: (fmd-nmatch-expr (ftype-nmatch (fmd-get-type 'VC-Db-Dir)) t)
;; Use: (fmd-nmatch-expr (ftype-nmatch (fmd-get-type 'Version-Controlled-Directory)) t)
;; Use: (fmd-nmatch-expr (ftype-nmatch (fmd-get-type 'GNU-GLOBAL-Directory)) t)

;; NOTE: WARNING: This is the reverse stategy so I disabled this for now!
(when nil
  (when (eq 'bol cctx) (setq key (concat "^" key)) (setq regexp-flag t)) ;beginning of line
  (when (eq 'eol cctx) (setq key (concat key "$")) (setq regexp-flag t)) ;end of line
  )

(defun fmd-cmatch-expr (cmatch &optional expr-fmt ptype)
  "Construct a File Contents Matcher Expression using CMATCH.
If EXPR-FMT is t return expression only otherwise lambda expression."
  (let ((expr
         (cond
          ((functionp cmatch)              ;if already a function
           `(,cmatch filename))             ;return its expression
          ((memq (car-safe cmatch) '(and or not)) ;if a logical expression starting with `and`, `or' or `not'.
           `(,(car cmatch)                 ;copy operator symbol as is
             ;; recurse each argument
             ,@(mapcar (lambda (sub)
                         (fmd-cmatch-expr sub t ptype))  ;Note: May reuse ftypes-matchers!
                       (cdr cmatch))))
          (t
           (let* ((fmt (fmatch-fmt cmatch))  ;format
                  (val (fmatch-val cmatch))  ;value
                  (ctx (fmatch-ctx cmatch))   ;context
                  (casef (fmatch-casef cmatch)) ;case-fold
                  (limit (or (fmatch-limit cmatch) 1024)) ;limit search up to this file offset
                  (regexp-flag (when (memq fmt '(re rx)) t))
                  vstr                  ;value as string
                  )

             ;; Note: calculate vstr and if needed force regexp
             (cond
              ((listp val)
               (if (== (length val) 1)   ;if only one element in list
                   (setq vstr (car val)) ;just pick that
                 (setq vstr (concat "\\(?:" (fmd-match-regexp val (eq 're fmt) t) "\\)"))
                 (setq regexp-flag t)
                 ))
              ((stringp val)
               (setq vstr val))
              (t
               (error "unsupported val format: %s\n" val)))

             ;; Note: try to strip regexp chars and convert/merge them with context ctx
             (when (and regexp-flag
                        (>= (length vstr) 1))
               (let ((re-bol (eq ?^ (elt vstr 0))) ;if first char is a hat ^
                     (re-eol (eq ?$ (elt vstr (1- (length vstr)))))) ;if last char is a dollar $
                 (when re-bol
                   (cond ((or (eq ctx 'beg)
                              (and (listp ctx)
                                   (memq 'beg ctx)))
                          ;; bol has no effect if ctx is already 'beg
                          (setq vstr (substring vstr 1))) ;strip first char
                         ((memq ctx '(any nil))
                          (setq ctx 'bol) ;'any => 'bol
                          (setq vstr (substring vstr 1))) ;strip first char
                         ))
                 (when re-eol
                   (cond ((or (eq ctx 'end)
                              (and (listp ctx)
                                   (memq 'end ctx)))
                          ;; eol has no effect if ctx is already 'end
                          (setq vstr (substring vstr 0 (1- (length vstr))))) ;strip last char
                         ((memq ctx '(any nil))
                          (setq ctx 'eol) ;'any => 'eol
                          (setq vstr (substring vstr 0 (1- (length vstr))))))))) ;strip last char

             ;; Note: finally if vstr contains not regexp characters we don't regexp-search
             (when (and regexp-flag
                        (not (string-regexp-p vstr))) ;if no regexp characters present in string
               (setq regexp-flag nil)) ;we can interpret it as a non-regexp (literal) string instead

             (cond
              ((memq fmt '(lit re))     ;string or regexp format
               (when vstr
                 (let ((decoding (cond ((eq ptype 'bin) 'unbox-bin) ;uncompress boxed binary files
                                       ((eq ptype 'txt) 'unbox-txt) ;uncompress boxed text files
                                       ((eq ptype 'box) 'bin) ;skip decompression for boxed binary files
                                       (t 'bin) ;default to raw decoding
                                       )))
                   (cond ((symbolp ctx)  ;context a symbol
                          (case ctx
                            ;; if we scan for contents we should chase the links to get the right modification time and size
                            (any `(cscan-file filename ,vstr ',ctx ,regexp-flag ,casef ',decoding nil ,limit))
                            ((beg 0) `(cscan-file filename ,vstr 0 ,regexp-flag ,casef ',decoding nil ,limit))
                            (end `(cscan-file filename ,vstr ',ctx ,regexp-flag ,casef ',decoding nil ,limit))
                            (bol `(cscan-file filename ,vstr ',ctx ,regexp-flag ,casef ',decoding nil ,limit))
                            (eol `(cscan-file filename ,vstr ',ctx ,regexp-flag ,casef ',decoding nil ,limit))
                            (full `(cscan-file filename ,vstr ',ctx ,regexp-flag ,casef ',decoding nil ,limit))
                            (t `(cscan-file filename ,vstr 0 ,regexp-flag ,casef ',decoding nil ,limit))
                            ))
                         ((numberp ctx) ;context a number (file position. offset from beginning >= 0, from end otherwise
                          `(cscan-file filename ,vstr ,ctx ,regexp-flag ,casef ',decoding nil ,limit))
                         ((listp ctx)    ;context is a list of the above
                          `(cscan-file filename ,vstr ',ctx ,regexp-flag ,casef ',decoding nil ,limit)
                          ))))
               )))))))
    (when expr
      (if expr-fmt expr `(lambda (filename) ,expr))))) ;return plain or lambda expression
;; Use: (fmd-cmatch-expr (ftype-cmatch (fmd-get-type 'ELF)))
;; Use: (fmd-cmatch-expr (ftype-cmatch (fmd-get-type 'C)))
;; Use: (fmd-cmatch-expr (ftype-cmatch (fmd-get-type 'ISO)))
;; Use: (fmd-cmatch-expr (ftype-cmatch (fmd-get-type 'PE/COFF)))
;; Use: (fmd-cmatch-expr (ftype-cmatch (fmd-get-type 'UDF)))
;; Use: (fmd-cmatch-expr '(not (lit ("NSR0") 38913)))
;; Use: (nth 2 (fmd-cmatch-expr (ftype-cmatch (fmd-get-type 'ELF))))

(defun fmd-ptype-types-expr (ptype &optional expr-fmt)
  "Construct a File Class Matcher of type PTYPE.
If EXPR-FMT is t return expression only otherwise lambda expression."
  (let* ((file-expr
          (case ptype
            (reg `(file-regular-p filename)) ;regular
            (dir `(file-directory-p filename))   ;directory
            (symlink `(file-symlink-p filename)) ;symbolic link
            (t `(file-regular-p (file-chase-links filename))) ;default to chased regular
            ))
         (fcache-expr
          (case ptype
            (reg `(fcache-regular-p filename)) ;regular
            (dir `(fcache-directory-p filename))   ;directory
            (symlink `(fcache-symlink-p filename)) ;symbolic link
            (t `(fcache-chased-regular-p filename)) ;default to chased regular
            ))
         (expr `(if (fcachep filename)
                    ,fcache-expr
                  ,file-expr)))
    (if expr-fmt
        expr                            ;plain expression
      `(lambda (filename) ,expr))))     ;lambda expression
;; Use: (fmd-ptype-types-expr (fmd-get-type 'ELF) t)
;; Use: (fmd-ptype-types-expr (fmd-get-type 'C) t)
;; Use: (fmd-ptype-types-expr (fmd-get-type 'VC-Db-Dir))
;; Use: (fmd-ptype-types-expr (fmd-get-type 'GNU-zip) t)
;; Use: (fmd-ptype-types-expr (ftype-ptype (fmd-get-type 'Editable)) t)
;; Use: (fmd-ptype-types-expr (ftype-ptype (fmd-get-type 'Editable-Dir)) t)

(defun fmd-fexpr (ftype &optional expr-fmt) (fmd-ptype-types-expr (ftype-ptype ftype) expr-fmt))
(defun fmd-nexpr (ftype &optional expr-fmt) (fmd-nmatch-expr (ftype-nmatch ftype) expr-fmt))
(defun fmd-cexpr (ftype &optional expr-fmt) (fmd-cmatch-expr (ftype-cmatch ftype) t `,(ftype-ptype ftype)))
;; Use: (fmd-fexpr (fmd-get-type 'FILE_ID.DIZ) t)
;; Use: (fmd-fexpr (fmd-get-type 'ELF) t)

(defun fmd-expr-from-symbol (ksym &optional recog)
  "Construct a File Matcher that from the type-key symbol KSYM
using recognizer RECOG and return it. If RECOG is nil default to
a sloppy behavior where use whatever matchers, and only if no
matchers at all available return nil. "
  (let* ((ftype (fmd-get-type ksym)) ;file type entry
         (matcher (ftype-match ftype))
         )
    (if (functionp matcher)
        `(,matcher filename)
      (when ftype
        (let* ((fexpr (fmd-fexpr ftype t)) ;class matcher
               (nexpr (fmd-nexpr ftype t)) ;name matcher
               (cexpr (fmd-cexpr ftype t)) ;contents matcher
               )
          (unless fexpr
            (error "Could not lookup fexpr for ksym: %s" ksym))
          (unless recog                       ;if no recog given
            (setq recog (ftype-precog ftype))) ;try preferred recog (precog)
          (case recog
            (name-recog
             (when nexpr `,nexpr))
            (exist-recog
             (when nexpr `(and ,nexpr ,fexpr)))
            (contents-recog
             (when cexpr `(and ,fexpr ,cexpr)))
            (name-and-contents-recog
             (when (and nexpr cexpr) `(and ,nexpr ,fexpr ,cexpr)))
            (name-or-contents-recog
             (cond ((and nexpr cexpr) `(and ,fexpr (or ,nexpr ,cexpr)))
                   (nexpr `(and ,nexpr ,fexpr))
                   (cexpr `(and ,fexpr ,cexpr))))
            (t
             ;; use what we have
             (cond ((and nexpr cexpr) `(and ,nexpr ,fexpr ,cexpr)) ;use both (`name-and-contents-recog')
                   (nexpr `(and ,nexpr ,fexpr))  ;use name (`name-recog')
                   (cexpr `(and ,cexpr ,fexpr)))) ;use content (`contents-recog')
            ))))))
;; Use: (fmd-expr-from-symbol 'C 'name-recog)
;; Use: (fmd-expr-from-symbol 'C 'contents-recog)
;; Use: (fmd-expr-from-symbol 'C nil)
;; Use: (fmd-expr-from-symbol 'GNU-zip)
;; Use: (fmd-expr-from-symbol 'GNU-zip 'contents-recog)
;; Use: (fmd-expr-from-symbol 'README)
;; Use: (fmd-expr-from-symbol 'README 'name-recog)
;; Use: (fmd-expr-from-symbol 'README 'exist-recog)
;; Use: (fmd-expr-from-symbol 'README 'contents-recog)
;; Use: (fmd-expr-from-symbol 'README 'name-or-contents-recog)
;; Use: (fmd-expr-from-symbol 'README 'name-and-contents-recog)
;; Use: (fmd-expr-from-symbol 'Uneditable)
;; Use: (fmd-expr-from-symbol 'Editable)
;; Use: (fmd-expr-from-symbol 'GNU-GLOBAL-Directory)

(defun fmd-expr-from-key-list (comb-op ksyms &optional recog)
  `(,comb-op     ;Note: comb-op needs its arguments spliced:
    ,@(delq nil ;Note: splice an evaluated value into the resulting list.
            (mapcar (lambda (tkey)
                      (fmd-matcher tkey recog nil t))  ;Note: May reuse ftypes-matchers!
                    ksyms))))
;; Use: (fmd-expr-from-key-list 'or '(C C++) 'name-recog)
;; Use: (fmd-expr-from-key-list 'or '(C C++) 'contents-recog)
;; Use: (fmd-expr-from-key-list 'or '(C C++) 'name-or-contents-recog)
;; Use: (fmd-expr-from-key-list 'or '(C C++) 'name-and-contents-recog)
;; Use: (fmd-expr-from-key-list 'or '(C C++) nil)

(defun fmd-parallel-expr-from-key-list (comb-op ksyms &optional recog)
  (let (nlit                            ;name literal strings list
        nre                             ;name regexp strings list
        nrx                             ;name `rx' expressions list
        nfun                            ;name functions list
        clit                            ;contents literal strings list
        cre                             ;content regexp strings list
        crx                             ;contents `rx' expressions list
        cfun                            ;contents functions list
        comb-nre                        ;combined name matcher regexp
        comb-cre)                     ;combined content matched regexp
    ;; TODO: Use `regexp-opt-depth' on each element in `ksyms' and emit "error "Skipping ksym %s because it contains regexp groups" ksym) if (not (= depth 0))
    (case comb-op
      (or
       `(or          ;Note: comb-op needs its arguments spliced:
         ,@(delq nil ;Note: splice an evaluated value into the resulting list.
                 (mapcar (lambda (tkey)
                           (fmd-matcher tkey recog nil t))  ;Note: May reuse ftypes-matchers!
                         ksyms))))
      (and
       `(and        ;Note: comb-op needs its arguments spliced:
         ,@(delq nil ;Note: splice an evaluated value into the resulting list.
                 (mapcar (lambda (tkey)
                           (fmd-matcher tkey recog nil t))  ;Note: May reuse ftypes-matchers!
                         ksyms))))
      (t
       (error "Unsupported Combination Operator %s" comb-op)))))
;; Use: (fmd-parallel-expr-from-key-list 'or '('C 'C++) 'contents-recog)

(defun fmd-expr-from-list (kexpr &optional recog)
  "Construct a matcher expression from KEXPR of type RECOG."
  (let ((comb-op 'or))            ;default combination operation to or
    (if (= (length kexpr) 1)            ;list of only 1 key
        (fmd-matcher (car kexpr) recog nil t) ;Note: May reuse ftypes-matchers!
      ;; otherwise list of several keys
      (when (and (symbolp (car kexpr)) ;first is the symbol: 'or, 'not, 'and. TODO: use `fboundp'() instead.
                 (memq (car kexpr) '(not null or and)))     ;first is logic operator
        (setq comb-op (car kexpr))     ;change default comb-op
        (setq kexpr (cdr kexpr)))       ;skip past op
      (let ((kexpr-copy (copy-tree kexpr)))
        (when (eq comb-op 'or)          ;if or
          ;; we want to put the fastest keys first
          (setq kexpr-copy               ;needed to preserve structure
                (sort kexpr-copy 'ftype-key-precog-rank-lessp))) ;sort keys
        (fmd-expr-from-key-list comb-op kexpr-copy recog)))))
;; Use: (fmd-expr-from-list nil)
;; Use: (fmd-expr-from-list '(C C++) 'name-recog)
;; Use: (fmd-expr-from-list '(GNU-zip C++) 'name-recog)
;; Use: (fmd-expr-from-list ftypes-uneditable-file-keys)

(defun fmd-matcher-uncached (kexpr &optional recog expr-fmt)
  "Construct a File Matcher that from the type-key-expression
KEXPR using recognizer RECOG and return it.
If EXPR-FMT is t return expression only otherwise lambda expression."
  (interactive (list (completing-read "File Type: " fmd-types)
                     (cadr (fmd-read-recog))))
  (unless kexpr (error "kexpr is nil!"))
  ;; no matcher present yet
  (let ((expr
         (cond
          ((symbolp kexpr)             ;type key (symbol)
           (fmd-expr-from-symbol kexpr recog))
          ((listp kexpr)               ;list of type keys
           (fmd-expr-from-list kexpr recog)))))
    (if expr-fmt expr `(lambda (filename) ,expr)))) ;return plain or lambda expression
;; Use: (fmd-matcher-uncached '(not C) 'name-recog)
;; Use: (fmd-matcher-uncached 'README 'name-recog)
;; Use: (fmd-matcher-uncached '(not README) 'name-recog)
;; Use: (fmd-matcher-uncached 'Plain-Text 'name-recog)
;; Use: (fmd-matcher-uncached 'Plain-Text 'contents-recog)
;; Use: (fmd-matcher-uncached 'Plain-Text 'name-and-contents-recog)
;; Use: (fmd-matcher-uncached '(or README Plain-Text) 'name-recog)
;; Use: (fmd-matcher-uncached '(and README Plain-Text) 'name-recog)
;; Use: (fmd-matcher-uncached 'ELF 'name-recog)
;; Use: (fmd-matcher-uncached 'ELF 'contents-recog)
;; Use: (fmd-matcher-uncached 'ELF 'name-or-contents-recog)
;; Use: (fmd-matcher-uncached 'C 'name-recog)
;; Use: (fmd-matcher-uncached 'C 'name-or-contents-recog)
;; Use: (fmd-matcher-uncached 'C++ 'name-or-contents-recog)
;; Use: (fmd-matcher-uncached '(C) 'name-recog)
;; Use: (fmd-matcher-uncached 'C++ 'name-recog)
;; Use: (fmd-matcher-uncached '(and C C++) 'name-recog)
;; Use: (fmd-matcher-uncached '(or C C++) 'name-recog)
;; Use: (fmd-matcher-uncached '(not (or C C++)) 'name-recog)
;; Use: (fmd-matcher-uncached '(C C++) 'name-or-contents-recog)
;; Use: (fmd-matcher-uncached '(GNU-GLOBAL-Directory) 'name-recog)
;; Use: (byte-compile (fmd-matcher-uncached '(GNU-GLOBAL-Directory) 'name-recog))
;; Use: (fmd-matcher-uncached '(or) 'name-recog)
;; Use: (fmd-matcher-uncached '(and) 'name-recog)
;; Use: (fmd-matcher-uncached '(not C++) 'contents-recog)
;; Use: (fmd-matcher-uncached nil 'contents-recog)
;; Use: (fmd-matcher-uncached '(ELF Shell-Script Bash-Script))
;; Use: (fmd-matcher-uncached ftypes-uneditable-file-keys)
;; Use: (fmd-matcher-uncached 'Uneditable)

;; Use: (cscan-file-uncached (elsub "mine/cscan-test.txt" "TRUEVISION-XFILE. " 'end nil 'unbox-bin nil 1024)

(defun fmd-benchmark-ftype ()
  (let ((filename "/etc/.git"))
    (list
     (benchmark-run 100 (file-regular-p filename))
     (benchmark-run 100 (string-equal ".git" filename))
     (benchmark-run 100 (string-match "\.git" filename))
     (benchmark-run 100 (and (> (length filename) (length ".git"))
                             (string-equal (substring filename -4) ".git")))
     (benchmark-run 100 (string-equal (ignore-errors (substring filename -4)) ".git"))
     (benchmark-run 100 (cscan-file filename "ELF         " 0 nil nil 'unbox-bin nil 1024)))
    )
  )

(defun fmd-matcher (kexpr &optional recog compile-flag expr-fmt)
  "Get a (cached or new) a matcher function that matches
all (NOT-FLAG is nil) or none (if NOT-FLAG is non-nil) of the
files of type KEXPR using recognizer RECOG and return it. If
EXPR-FMT equals 'interactive then return a lambda matcher with
an optional argument QUERY-PROMPT that queries (with
QUERY-PROMPT) the user if the match should be performed."
  (interactive (list (completing-read "File Type: " fmd-types)
                     (cadr (fmd-read-recog))))
  (let* ((matcher (gethash `(,kexpr ,recog) ftypes-matchers))) ;try lookup matcher
    (unless matcher                     ;if no matcher generated yet
      ;; no matcher present yet
      (setq matcher (fmd-matcher-uncached kexpr recog t))
      (puthash `(,kexpr ,recog) matcher ftypes-matchers) ;cache the matcher
      )
    (if (eq 'interactive expr-fmt)
        (setq matcher `(lambda (filename)
                         (when (y-or-n-p (format "Enter %s %s? "
                                                 (if (file-directory-p filename) "directory" "file")
                                                 (if (file-directory-p filename) (faze filename 'dir) (faze filename 'file))
                                                 ))
                           ,matcher)))
      (unless expr-fmt (setq matcher `(lambda (filename) ,matcher))))
    (if compile-flag (byte-compile matcher) matcher)))
;; Use: (fmd-matcher 'C 'name-recog)
;; Use: (fmd-matcher 'Makefile 'name-recog)
;; Use: (fmd-matcher 'C 'name-recog nil t)
;; Use: (fmd-matcher 'C 'name-recog nil 'interactive)
;; Use: (fmd-matcher '(not C) 'name-recog)
;; Use: (fmd-matcher 'C++ 'name-recog)
;; Use: (fmd-matcher 'C++ 'name-recog t)
;; Use: (fmd-matcher 'C++ 'contents-recog)
;; Use: (fmd-matcher 'C++ 'contents-recog t)
;; Use: (fmd-matcher '(not C++) 'contents-recog)
;; Use: (fmd-matcher '(not C++) 'contents-recog t)
;; Use: (fmd-matcher 'Java 'name-recog)
;; Use: (fmd-matcher 'ELF 'contents-recog)
;; Use: (fmd-matcher 'ELF)
;; Use: (fmd-matcher '(C C++) 'name-recog)
;; Use: (fmd-matcher '(GNU-GLOBAL-Directory) 'name-recog)
;; Use: (fmd-matcher '(GNU-GLOBAL-Directory VC-Db-Dir) 'name-recog)
;; Use: (fmd-matcher '(VC-Db-Dir) 'name-recog)
;; Use: (fmd-matcher '(not'VC-Db-Dir) 'name-recog)
;; Use: (call-interactively 'fmd-matcher)
;; Use: (fmd-matcher 'GNU-zip)
;; Use: (fmd-matcher '(GNU-zip))
;; Use: (fmd-matcher 'GNU-zip 'name-and-contents-recog)
;; Use: (fmd-matcher ftypes-uneditable-file-keys)

;; Use: (fmd-matcher 'Exuberant-Ctags)
(defun fmd-read-single-matcher (&optional recog compile-flag)
  (let ((kexpr (completing-read "File Types: " fmd-types)))
    (fmd-matcher kexpr recog compile-flag)))
;; Use: (fmd-read-single-matcher 'name-recog)

(defun* fmd-read-multi-matcher (&optional recog compile-flag (prompt "File Types: "))
  (let ((kexpr (completing-read-multiple prompt fmd-types)))
    (fmd-matcher kexpr recog compile-flag)))
;; Use: (fmd-read-multi-matcher 'name-recog nil "Types: ")

;; WARNING: TODO: IN-COMPLETE!
(defun fmd-get-default-matcher (&optional matcher-type creation ptype)
  "Generate default matcher of type MATCHER-TYPE (currently
'function or 'regexp or nil for default) that matches files that
are created using CREATION which can be 'man or 'gen or nil for
all. File class PTYPE can be either 'dir, 'file, 'file-or-dir or nil for default."
  (interactive)
  (let ((npatts '((any-lit) (beg-lit) (end-lit) (ext-lit) (full-lit)
                  (any-re) (beg-re) (end-re) (ext-re) (full-re)
                  ))
        (cpatts '((any-lit) (beg-lit) (end-lit) (full-lit)
                  (any-re) (beg-re) (end-re) (full-re)
                  ))
        )
    (dolist (ftype fmd-types)
      (let* ((creation-2 (ftype-creation ftype)))
        (when (or (not creation) ; all creations
                  (eq creation-2 creation)) ; specific creation
          (let* ((nmatch (ftype-nmatch ftype)) ;name pattern
                 (nfmt (fmatch-fmt nmatch))    ;name pattern format
                 (nval (fmatch-val nmatch))    ;name pattern value
                 (nctx (fmatch-ctx nmatch))    ;name pattern context
                 (ftype (assoc nfmt npatts)))
            (if (and ftype nval)
                (setcdr ftype (append (cdr ftype) `(,nval)))))
          (let* ((cmatch (ftype-cmatch ftype))     ;contents pattern
                 (cfmt (fmatch-fmt cmatch))  ;contents pattern format
                 (cval (fmatch-val cmatch))  ;contents pattern value
                 (cctx (fmatch-ctx cmatch))  ;contents pattern context
                 (ftype (assoc cfmt cpatts)))
            (if (and ftype cval)
                (setcdr ftype (append (cdr ftype) `(,cval)))))
          )))
    (message-object 'npatts)
    (message-object 'cpatts)
    ))
;; Use: (fmd-get-default-matcher 'regexp 'man)
;; Use: (fmd-get-default-matcher 'regexp 'gen)
;; Use: (fmd-get-default-matcher 'regexp t)

(defun fmd-or-matcher (keys)
  "Get matcher for (or KEYS...)."
  ;; 1.
  ;; For each key get its nmatcher add it to `rx' as `group-n'
  ;; match filename using generated `rx'
  ;;
  ;; 2.
  ;; for each hit in `match-data'
  ;; if (eq recog `nrecog') return hit
  ;; else if (and (meq recog '(name-or-contents name-and-contents)) cmatch) return hit
  )

;; ---------------------------------------------------------------------------

(defun fmd-match-uncached (file-or-cache kexpr &optional recog)
  "Rematch FILE-OR-CACHE with KEXP using RECOG."
  (when kexpr
    (if (fcachep file-or-cache)
        (let ((relname (fcache-fname file-or-cache))) ;Note: Assumed to be defined in resulting matcher
          (funcall (fmd-matcher kexpr recog nil) (fcache-full-fname file-or-cache))
          )
      (let ((relname (file-name-nondirectory file-or-cache))) ;Note: Assumed to be defined in resulting matcher
        (funcall (fmd-matcher kexpr recog nil) file-or-cache)
        ))))
;; Use: (fmd-match-uncached "vec2f.h" 'C 'name-recog) (assert-nonnil)
;; Use: (fmd-match-uncached "vec2f.c" 'C 'name-recog) (assert-nonnil)
;; Use: (fmd-match-uncached "vec2f.cpp" 'C 'name-recog) (assert-nil)
;; Use: (fmd-match-uncached "vec2f.c" 'C++ 'name-recog) (assert-nil)
;; Use: (fmd-match-uncached "vec2f.c" 'C++ 'name-or-contents-recog) => nil
;; Use: (fmd-match-uncached "vec2f.hpp" 'C++ 'name-recog)
;; Use: (fmd-match-uncached "vec2f.hpp" 'C++ 'contents-recog)
;; Use: (fmd-match-uncached "vec2f.cpp" '(C C++) 'name-recog)
;; Use: (fmd-match-uncached "vec2f.hpp" '(C++-Header C-Header) 'name-recog)
;; Use: (fmd-match-uncached "foo.cpp" '(C++-Header C-Header) 'name-recog)
;; Use: (fmd-match-uncached "~/cognia/vec2.hpp" '(C++-Header) 'name-recog)
;; Use: (fmd-match-uncached "~/cognia/vec2.hpp" '(C++-Header) 'name-and-contents-recog)
;; Use: (fmd-match-uncached "/bin/ls" 'ELF 'contents-recog)
;; Use: (fmd-match-uncached "/usr/bin/emacs-snapshot-gtk" 'ELF 'contents-recog)
;; Use: (fmd-match-uncached "README" 'README 'name-recog)
;; Use: (fmd-match-uncached "README.NOW" 'README 'name-recog)
;; Use: (fmd-match-uncached "Changelog" 'Changelog 'name-recog)
;; Use: (fmd-match-uncached "Changelog.1" 'Changelog 'name-recog)
;; Use: (fmd-match-uncached "~/cognia/" 'GNU-GLOBAL-Directory 'name-and-contents-recog) => t
;; Use: (fmd-match-uncached "~/cognia/GTAGS" 'GNU-GLOBAL-Directory 'name-and-contents-recog) => nil
;; Use: (fmd-match-uncached "~/cognia/GTAGS" 'Berkeley-DB 'contents-recog) => '(1 5)
;; Use: (fmd-match-uncached "~/cognia/TAGS" 'Emacs-tags 'name-recog)
;; Use: (fmd-match-uncached "~/cognia/TAGS" 'Emacs-tags 'name-and-contents-recog)
;; Use: (fmd-match-uncached "~/cognia/.git" 'VC-Db-Dir 'contents-recog)
;; Use: (fmd-match-uncached "~/cognia/" 'Version-Controlled-Directory 'name-or-contents-recog)
;; Use: (fmd-match-uncached "~/.git" 'VC-Db-Dir 'name-recog)
;; Use: (fmd-match-uncached (elsub "mine/pnw-dot-emacs.elc") '(Emacs-Lisp-Compiled) 'contents-recog) =>
;; Use: (fmd-match-uncached "/usr/share/info/gzip.info.gz" 'GNU-zip) => t
;; Use: (fmd-match-uncached "/etc/alternatives/cc" 'ELF) => t
;; Use: (fmd-match-uncached "/etc/alternatives/c++" 'ELF) => t
;; Use: (fmd-match-uncached "/bin/ls" 'ELF) => t
;; Use: (fmd-match-uncached "/etc/passwd" 'ELF) => nil
;; Use: (fmd-match-uncached "/bin/ls" 'Desktop-Entry) => nil
;; Use: (fmd-match-uncached "/usr/share/applications/nautilus.desktop" 'Desktop-Entry) => t
;; Use: (fmd-match-uncached "/bin/ls" ftypes-gud-debuggable-file-keys) => t

;; Use: (fmd-match-uncached "~/pnw/images/circle.jpg" 'JPEG) => non-nil
;; Use: (fmd-match-uncached "~/pnw/images/12.png" 'PNG) => non-nil

;; Use: (fmd-match-uncached "/usr/lib/vmware/isoimages/windows.iso" 'ISO) => t
;; Use: (fmd-match-uncached "/usr/lib/vmware/isoimages/windows.iso" 'UDF) => nil
;; Use: (fmd-match-uncached (elsub "mine/ectags.elc") 'Emacs-Lisp-Compiled)

;; Use: (fmd-match-uncached "~/.wine/drive_c/MinGW/bin/cpp.exe" 'DOS-MZ)
;; Use: (fmd-match-uncached "~/.wine/drive_c/MinGW/bin/cpp.exe" 'PE/COFF)
;; Use: (fmd-match-uncached "~/.wine/drive_c/MinGW/bin/cpp.exe" 'Uneditable)

;; FIXME:
;; Use: (fcache-ftype (fcache-chase-links (fcache-of (elsub "mine/tscan-tests/dirlink/sub.rlink"))))
;; Use: (fmd-matcher 'ELF nil)
;; Use: (fmd-match-uncached (elsub "mine/tscan-tests/dirlink/sub.rlink") 'ELF)
;; Use: (fmd-match-uncached (elsub "mine/tscan-tests/recursive/up") 'ELF)

(defun fmd-key-match-cached-keys (key keys)
  "Return non-nil if KEYS is either `eq' to KEYS or `memq' in KEYS."
  (cond ((symbolp keys)               ;single cached key
         (eq key keys))
        ((listp keys)                   ;list of cached keys
         (memq key keys))
        (t (message "Unsupported format on keys") nil)))

(defun file-match-single-key (file-or-cache key ckeys &optional recog cached-only)
  "Return KEY if FILE-OR-CACHE matches it.
Use cached keys CKEYS when possible. If CACHED-ONLY is nil
append new CKEYS when needed."
  (when (or (fmd-key-match-cached-keys key ckeys) ;first try cache
            (unless cached-only
              (fmd-match-uncached file-or-cache key recog))) ;and then real match
    key))
;; Use: (file-match-single-key "/bin/ls" nil '(ELF))
;; (eval-when-compile (assert-eq 'ELF (file-match-single-key "/bin/ls" 'ELF nil nil)))
;; (eval-when-compile (assert-eq 'ELF (file-match-single-key "/bin/ls" 'ELF '(ELF) nil)))

(defun file-match-keys-first (file-or-cache keys &optional ckeys recog cached-only)
  "Return the first key in KEYS that match FILE-OR-CACHE.
Use cached keys CKEYS when possible. If CACHED-ONLY is nil
append new CKEYS when needed."
  (catch 'hit
    (dolist (key keys)
      (when (or (memq key ckeys)   ;either cached hit
                (and (not cached-only)
                     (fmd-match-uncached file-or-cache key recog))) ;or new hit
        (throw 'hit key)))))
;; Use: (file-match-keys-first "/bin/ls" '(Java) '(C C++ Java) nil t) => Java

(defun file-match-keys-many (file-or-cache keys &optional ckeys recog cached-only)
  "Return the first key in KEYS that match FILE-OR-CACHE.
Use cached keys CKEYS when possible. If CACHED-ONLY is nil
append new CKEYS when needed."
  (let ((hits))
    (dolist (key keys)
      (when (or (memq key ckeys)   ;either cached hit
                (and (not cached-only)
                     (fmd-match-uncached file-or-cache key recog))) ;or new hit
        (setq hits (cons key hits))))
    hits))
;; Use: (file-match-keys-many "/bin/ls" '(ELF))
;; Use: (file-match-keys-many (fcache-of "/bin/ls") '(ELF))

(defun file-match-keys-all (file-or-cache keys &optional ckeys recog cached-only)
  "Return KEYS if FILE-OR-CACHE match all the keys in the list KEYS.
Use cached keys CKEYS when possible. If CACHED-ONLY is nil
append new CKEYS when needed."
  (catch 'miss
    (dolist (key keys)
      (if cached-only
          (unless (memq key ckeys)
            (throw 'miss nil))
        (unless (fmd-match-uncached file-or-cache key recog)
          (throw 'miss nil))
        ))
    keys))
;; Use: (file-match-keys-all "/bin/ls" '(Java) '(C C++ Java) nil t) => (Java)
;; Use: (file-match-keys-all "/bin/ls" '(Java Pascal) '(C C++ Java) nil t) => nil
;; Use: (file-match-keys-all "/bin/ls" '(Java Pascal) '(C C++ Java Pascal) nil t) => (Java Pascal)

(defun file-match-key-or-keylist-cached (file-or-cache kexpr &optional ckeys recog cached-only hit-list)
  (let ((hit (cond ((memq kexpr ckeys)  ;if cached
                    kexpr)              ;return directly
                   ((eq kexpr t)        ;if all registered keys (shortcut)
                    (file-match-keys-many file-or-cache fmd-type-keys ckeys recog cached-only))
                   ((symbolp kexpr)     ;single key
                    (let* ((ftype  (fmd-get-type kexpr)))
                      (when ftype       ;if ftype exists
                        ;; (and ftype
                        ;;      (let ((filename (if (fcachep file-or-cache)
                        ;;                          (fcache-full-fname file-or-cache)
                        ;;                        file-or-cache)))
                        ;;        (or (eq recog 'name-recog) ;either only name recognition or
                        ;;            (eval (fmd-fexpr ftype t)))) ;right file type
                        ;;      )
                        (let ((generalize-expr (plist-get (ftype-match ftype) :generalize))
                              (specialize-expr (plist-get (ftype-match ftype) :specialize))
                              (not-expr (plist-get (ftype-match ftype) :not)))
                          (cond (generalize-expr ;if a group expression
                                 (let ((result (file-match-kexpr file-or-cache generalize-expr recog))) ;Note: Use cached matcher!
                                   (when result
                                     (append (list kexpr) result)))) ;append generalize-expr key to "sub-keys"
                                (specialize-expr ;if a group expression
                                 (let ((result (file-match-kexpr file-or-cache specialize-expr recog))) ;Note: Use cached matcher!
                                   (when result
                                     ;; do nothing `specialize'd for now
                                     )
                                   (file-match-single-key file-or-cache kexpr ckeys recog cached-only)
                                   ))
                                (not-expr ;if a not expression
                                 (let ((result (file-match-kexpr file-or-cache not-expr recog))) ;Note: Use cached matcher!
                                   (when (not result)
                                     kexpr))) ;just return the key
                                (t
                                 (file-match-single-key file-or-cache kexpr ckeys recog cached-only)))))))
                   ((listp kexpr)             ;list of keys
                    (if (eq (car kexpr) 'and) ;must match all
                        (file-match-keys-all file-or-cache (cdr kexpr) ckeys recog cached-only) ;all or nothing
                      (file-match-keys-first file-or-cache kexpr ckeys recog cached-only)))))) ;the first that matches
    (when hit
      (cond ((symbolp hit) `(,hit))     ;standardize hit format to be a list
            ((listp hit) hit)))))

(defun file-match-kexpr (file-or-cache &optional kexpr recog cached-only)
  "Return non-nil if FILE-OR-CACHE matches key expression KEXPR using RECOG.
FILE-OR-CACHE must be in expanded file (path) form. If KEXPR is of the
form `(KEYs) or `(or KEYs)' then return a (sub-)list of KEXPR
containing only the keys that matched FILE-OR-CACHE."
  (or (and kexpr (listp kexpr)        ;if a non-empty list
           (let ((lf (car kexpr))            ;first of list
                 (lr (cdr kexpr)))           ;rest of list
             (cond ((eq lf 'not)             ;begins with logical `not' operator
                    (not (file-match-kexpr file-or-cache lr recog cached-only)) ;inverse of rest of list
                    )
                   ((eq lf 'or)              ;begins with logical `or' operator
                    (file-match-kexpr file-or-cache lr recog cached-only) ;same as without any operator
                    )
                   ((not lr)                 ;list contains one element only
                    (file-match-kexpr file-or-cache lf recog cached-only) ;one key only
                    ))))
      (let* ((fcache (if (fcachep file-or-cache)
                         file-or-cache
                       (unless (eq recog 'name-recog) ;`name-recog' doesn't need `fcache'
                         (fcache-of file-or-cache))))
             (types (and fcache (fcache-get-types fcache))))
        (if types
            ;; types already exist
            (let* ((ckeys (cadr (assq recog types)))) ;cached keys for `recog'
              ;; do match with possible cached keys `ckeys'
              (cond ((memq kexpr ckeys) ;Note: most probable case
                     `(,kexpr))         ;that should be *fast*!
                    ((and (null kexpr)  ;if no kexpr
                          cached-only) ;and we only wanted cached keys
                     ckeys)            ;use all cached keys only
                    (t
                     (let ((new-hit (file-match-key-or-keylist-cached file-or-cache kexpr ckeys recog cached-only)))
                       (unless cached-only ;if more than just cached keys were searched for
                         (when new-hit ;fcache new keys
                           (if ckeys ;if previous cached keys exist
                               (progn
                                 (setq ckeys (append ckeys new-hit))
                                 (delete-dups ckeys)) ;TODO: Is there a eq variant of this?
                             (setq ckeys new-hit))
                           (when fcache
                             (fcache-set-types fcache `((,recog ,ckeys))))))
                       new-hit))))
          ;; no types exist
          (unless cached-only
            (let ((hit (file-match-key-or-keylist-cached
                        file-or-cache kexpr nil recog cached-only))) ;new match
              (when (and hit fcache)
                (fcache-set-types fcache `((,recog ,hit))) ;set new types
                )
              hit))))))
;; (eval-when-compile (assert-nil (file-match-cached "a.cpp" 'C++-Header 'name-recog)))

(defun file-match-cached (file-or-cache &optional kexpr recog cached-only noerror)
  "Return non-nil if FILE-OR-CACHE matches key expression KEXPR using RECOG.
If KEXPR is nil return no matches.  If KEXPR is t return all
matches.  Returns list of the keys that matched KEXPR.
If NOERROR is non-nil just return nil if file does not exist."
  (when (or (null noerror)              ;either no error-tolerance continue directly
            (if (stringp file-or-cache) ;otherwise if filename string
                (file-exists-p file-or-cache)) ;check that it exists
            (fcachep file-or-cache))
    (when (or kexpr cached-only)
      (if (and (not (eq recog 'name-recog))
               (stringp file-or-cache))
          (let ((fcache (fcache-of file-or-cache cached-only)))
            (if fcache                   ;if `file-or-cache' exists
                (file-match-kexpr fcache kexpr recog cached-only)
              (fmd-match-uncached file-or-cache kexpr recog) ;if file doesn't exist just match uncached
              ))
        (file-match-kexpr file-or-cache kexpr recog cached-only)))))
(defalias 'file-match 'file-match-cached)
;; (eval-when-compile (assert-eq 'ELF (car (file-match-cached "/bin/ls" 'ELF)))
;;                    (assert-eq 'ELF (car (file-match-cached "/bin/ls" '(ELF))))
;;                    (assert-nil (file-match-cached "/bin/ls" ))
;;                    (assert-nil (file-match-cached "/bin/nobody" nil))
;;                    (assert-error "" (file-match-cached "/bin/nobody" t))
;;                    (assert-eq 'C-Source (car (file-match-cached "/tmp/foo.c" 'C-Source 'name-recog)))
;;                    (assert-nonnil (file-match-cached "a.hpp" 'C++-Header 'name-recog))
;;                    ;;(assert-nil    (file-match-cached "a.cpp" 'C++-Header 'name-recog))
;;                    )

;; ---------------------------------------------------------------------------

(when nil
  (progn
    ;; This works
    (read-file-name "Find file: " "~/" nil t nil (lambda (filename) t))

    ;; Why does this work as expected
    (let ((icicle-must-pass-predicate (lambda (filename) nil)))
      (icicle-read-file-name "Find file: " "~/" nil t nil (lambda (filename) nil)))

    ;; but none of these?
    (read-file-name "Find file: " "~/" nil t nil (lambda (filename) nil))
    (icicle-read-file-name "Find file: " "~/" nil t nil (lambda (filename) nil))
    ))

;; ---------------------------------------------------------------------------

(defun directory-files-of-types (&optional directory kexpr recog format full sort-predicate)
  "Return a list of names of files in DIRECTORY all matching KEXPR using RECOG.
If FULL is non-nil, return absolute file names.  Otherwise return names
 that are relative to the specified directory."
  (delq nil
        (mapcar
         `(lambda (filename)
            (let ((hit (file-match filename ',kexpr ',recog)))
              (when hit
                (let ((fn (if full
                              filename
                            (file-name-sans-directory filename))))
                  (cond ((eq format 'type-and-file)
                         (cons hit fn))
                        ((eq format 'file-and-type)
                         (cons fn hit))
                        ((eq format 'type)
                         hit)
                        ((eq format 'file)
                         fn)
                        (t
                         fn))))))
         (sort
          (directory-files (or directory
                               default-directory) t
                               directory-files-no-dot-files-regexp
                               t)
          (or sort-predicate
              (lambda (x y)
                (> (float-time (file-modification-time x))
                   (float-time (file-modification-time y)))))))))
;; Use: (directory-files-of-types "~/cognia" 'Makefile)
;; Use: (directory-files-of-types "~/cognia" 'Makefile nil nil t)
;; Use: (directory-files-of-types "~/ware/emacs" 'Makefile)
;; Use: (directory-files-of-types "~/cognia" 'Makefile nil 'type-and-file)
;; Use: (directory-files-of-types (elsub "others") 'Version-Controlled-Directory)

;; ---------------------------------------------------------------------------

(defun read-file-name-of-types (prompt kexpr &optional dir default-filename mustmatch initial recog)
  "Read file names matching KEXPR using RECOG."
  (let* ((nav-predicate `(lambda (filename) (or (file-directory-p filename)
                                                (file-match filename (quote ,kexpr) (quote ,recog)))))
         (history-predicate `(lambda (filename) (when (and (file-regular-p filename)
                                                           (file-match
                                                            (file-chase-links filename) ;Note: Chase filename to avoid fcache bug.
                                                            (quote ,kexpr) (quote ,recog)))
                                                  filename)))
         (icicle-must-pass-predicate nav-predicate)
         (filename (let ((file-name-history (delq nil (mapcar history-predicate file-name-history))))
                     (let ((icicle-default-in-prompt-format-function (lambda (default) (format " (%s)" (faze default 'file)))))
                       (read-file-name prompt dir default-filename mustmatch initial nil))))
         )
    (when filename                                  ;if anything picked
      (add-to-history 'file-name-history filename)) ;remember it
    filename))
(when nil
  (let ((prompt "Find file (of type %s): ")
        (mustmatch t))
    (let ((kexpr '(ELF)))
      (read-file-name-of-types (format prompt (mapconcat 'symbol-name kexpr ", ")) kexpr "~/cognia/" nil mustmatch))
    (let ((kexpr '(C-Header)))
      (read-file-name-of-types (format prompt (mapconcat 'symbol-name kexpr ", ")) kexpr "~/cognia/" nil mustmatch nil 'name-recog))
    (let ((kexpr '(C++)))
      (read-file-name-of-types (format prompt (mapconcat 'symbol-name kexpr ", ")) kexpr "~/cognia/" nil mustmatch nil 'name-recog))
    (let ((kexpr '(Makefile)))
      (read-file-name-of-types (format prompt (mapconcat 'symbol-name kexpr ", ")) kexpr (elsub "mine") nil mustmatch nil 'name-recog))
    (let ((kexpr '(ELF)))
      (read-file-name-of-types (format prompt (mapconcat 'symbol-name kexpr ", ")) kexpr "/bin/" nil mustmatch))
    (let ((kexpr '(ELF)))
      (read-file-name-of-types (format prompt (mapconcat 'symbol-name kexpr ", ")) kexpr "~/" nil mustmatch))
    (let ((kexpr '(Shell-Script)))
      (read-file-name-of-types (format prompt (mapconcat 'symbol-name kexpr ", ")) kexpr "~/pnw/scripts/" nil mustmatch))
    (let ((kexpr '(GUD-Debuggable)))
      (read-file-name-of-types (format prompt (mapconcat 'symbol-name kexpr ", ")) kexpr "~/" nil mustmatch))
    (let ((kexpr '(GUD-Debuggable)))
      (read-file-name-of-types (format prompt (mapconcat 'symbol-name kexpr ", ")) kexpr "/bin/" nil mustmatch))
    (let ((kexpr '(GUD-Debuggable)))
      (read-file-name-of-types (format prompt (mapconcat 'symbol-name kexpr ", ")) kexpr "/usr/bin/" nil mustmatch)))
  )

(defun read-file-name-debuggable (prompt &optional dir tkeys)
  "Read a debuggable FILENAME."
  (let* ((tkeys (or tkeys '(GUD-Debuggable))) ;type keys
         (buffer-file buffer-file-name)
         (buffer-debuggable (and buffer-file ;buffer-specific type-keys (if any)
                                 (car (file-match buffer-file tkeys)))) ;buffer type
         (filename (read-file-name-of-types (format (concat prompt " of type %s: ")
                                                    (mapconcat
                                                     (lambda (x)
                                                       (faze (symbol-name x) 'type))
                                                     tkeys ", ")) tkeys nil
                                                     (when buffer-debuggable (faze buffer-file 'file))
                                                     t nil)))
    (list filename)))
;; Use: (file-match "/bin/ls" ftypes-gud-debuggable-file-keys)
;; Use: (read-file-name-debuggable "Debug program file")
;; Use: (read-file-name-debuggable "Check program file" nil '(ELF))

;; ---------------------------------------------------------------------------

;; Note: magic: C program text
(defun file-C-header-p (filename &optional cached-only noerror)
  "Return non-nil if FILENAME is a C Header file."
  (interactive "fFile to investigate: ")
  (file-match filename 'C-Header 'name-or-contents-recog cached-only noerror)) ;relaxed
;; Use: (file-C-header-p "~/cognia/utils.h")

;; Note: magic: C program text
(defun file-C-source-p (filename &optional cached-only noerror)
  "Return non-nil if FILENAME is a C Source file."
  (interactive "fFile to investigate: ")
  (file-match filename 'C-Source 'name-or-contents-recog cached-only noerror)) ;relaxed
;; Use: (file-C-source-p "~/cognia/utils.c") => '(C-Source)
;; Use: (file-C-source-p "~/pnw/java/Sparse2DFloat.java") => nil

;; Note: magic: C++ program text
(defun file-C++-header-p (filename &optional cached-only noerror)
  "Return non-nil if FILENAME is a C++ Header file."
  (interactive "fFile to investigate: ")
  (file-match filename 'C++-Header 'name-or-contents-recog cached-only noerror)) ;relaxed
;; Use: (file-C++-header-p "~/cognia/geometry/vec.hpp")
(defun file-C++-source-p (filename &optional cached-only noerror)
  "Return non-nil if FILENAME is a C++ Source file."
  (interactive "fFile to investigate: ")
  (file-match filename 'C++-Source 'name-or-contents-recog cached-only noerror)) ;relaxed
;; Use: (file-C++-source-p "~/cognia/vec2.c")

;; Note: magic: D program text
(defun file-D-source-p (filename &optional cached-only noerror)
  "Return non-nil if FILENAME is a D Source file."
  (interactive "fFile to investigate: ")
  (file-match filename 'D 'name-or-contents-recog cached-only noerror)) ;relaxed
;; Use: (file-D-source-p "~/bin/wc.d") => '(D)

;; Note: magic: Java program text
(defun file-Java-source-p (filename &optional cached-only noerror)
  "Return non-nil if FILENAME is a Java Source file."
  (interactive "fFile to investigate: ")
  (file-match filename 'Java 'name-or-contents-recog cached-only noerror)) ;relaxed
;; Use: (file-Java-source-p "~/pnw/java/Sparse2DFloat.java")

(defun file-Bash-Script-source-p (filename &optional cached-only noerror)
  "Return non-nil if FILENAME is a Java Source file."
  (interactive "fFile to investigate: ")
  (file-match filename 'Bash-Script 'contents-recog cached-only noerror))
;; Use: (file-C-source-p "/bin/zcat")

;; Note: Backup
(defun file-backup-p (filename &optional cached-only noerror)
  "Return non-nil if FILENAME is a backup file."
  (interactive "fFile to investigate: ")
  (file-match filename '('Emacs-Backup 'Standard-Backup)
              'name-or-contents-recog cached-only noerror)) ;relaxed
;; Use: (file-backup-p "~/cognia/utils.c~")
;; Use: (file-backup-p "/var/backups/passwd.bak")

(defun file-ascii-p (filename &optional cached-only noerror)
  "Return non-nil if FILENAME contains ASCII codes only."
  (interactive "fFile to investigate: ")
  (file-magic-match filename "ASCII"))
;; Use: (file-ascii-p "~/cognia/utils.c")

;; ---------------------------------------------------------------------------

(defun file-elf-p (filename &optional recog cached-only noerror)
  "Return non-nil if FILENAME is an ELF (Executable and Linkable
Format) file"
  (interactive "fFile to investigate: ")
  (file-match filename 'ELF recog cached-only noerror))
;; Use: (file-elf-p "/bin/ls")

(defun file-automake-generated-p (filename &optional recog cached-only noerror)
  "Return non-nil if FILENAME is auto-generated by automake."
  (interactive "fFile to investigate: ")
  (file-match filename 'Automake-generated (or recog 'contents-recog) cached-only noerror)
  )
;; Use: (file-automake-generated-p "~/cognia/Makefile.in")
;; Use: (file-automake-generated-p "~/cognia/Makefile")

(defun file-ectags-p (filename &optional recog cached-only noerror)
  "Return non-nil if FILENAME is an Exuberant Ctags database
file. See:
http://oreilly.com/catalog/vi6/chapter/ch08.html#ch08_05.htm for
description of format."
  (interactive "fFile to investigate: ")
  (file-match filename 'Exuberant-Ctags (or recog 'contents-recog) cached-only noerror)
  )
;; Use: (file-ectags-p "~/cognia/tags")

;; ---------------------------------------------------------------------------

(defun file-script-code-p (filename &optional recog cached-only noerror)
  "Return non-nil if FILENAME is a Script."
  (interactive "fFile to investigate: ")
  (file-match filename 'Executable-Script recog cached-only noerror))
;; Use: (file-script-code-p "/usr/bin/autoconf") => t
;; Use: (file-script-code-p "~/f.m") => nil

(defun file-executable-script-code-p (filename &optional recog cached-only noerror)
  "Return non-nil if FILENAME is a UNIX standard-executable script (code)."
  (interactive "fFile to investigate: ")
  (and (file-match filename 'Executable-Script recog cached-only noerror) ;Note: This first because of its cached.
       (file-executable-p filename)))
;; Use: (file-executable-script-code-p "/usr/bin/autoconf") => t
;; Use: (file-executable-script-code-p "/bin/ls") => nil
;; Use: (file-executable-script-code-p "~/f.m") => nil

(defun file-executable-elf-p (filename &optional recog cached-only noerror)
  "Return non-nil if FILENAME can be profiled by OProfile (normally ELF)."
  (interactive "fFile to investigate: ")
  (and (file-executable-p filename)
       (file-elf-p filename recog cached-only noerror)))
;; Use: (file-executable-elf-p "/root") => nil
;; Use: (file-executable-elf-p "/etc") => nil
;; Use: (file-executable-elf-p "/bin/ls") => t

(defun file-executable-elf-or-script-code-p (filename &optional recog cached-only noerror)
  "Return non-nil if FILENAME is a UNIX standard-executable script (code) or ELF."
  (interactive "fFile to investigate: ")
  (and (file-executable-p filename)
       (or (file-elf-p filename recog cached-only noerror)
           (file-match filename 'Script recog cached-only noerror))))

(defun file-compressed-p (filename &optional recog cached-only noerror)
  "Return non-nil if FILENAME is compressed."
  (interactive "fFile to investigate: ")
  (file-match filename 'Compressed recog cached-only noerror))
;; Use: (file-compressed-p "/etc/X11/Xwrapper.config") => nil
;; Use: (file-compressed-p "/usr/share/info/gzip.info.gz") => '(Compressed)
;; Use: (file-match "/usr/share/info/gzip.info.gz" 'GNU-zip) => '(GNU-zip)

(defun file-archive-p (filename &optional recog compressed-only cached-only noerror)
  "Return non-nil if FILENAME is archive."
  (interactive "fFile to investigate: ")
  (and (or (not compressed-only)
           (file-compressed-p filename recog cached-only noerror))
       (file-match filename (fmd-category-keys "Archive") recog cached-only noerror)))
;; Use: (file-archive-p "/usr/share/info/gzip.info.gz") => nil
;; Use: (file-archive-p "~/gl-man.tgz") => nil

(defun file-compressed-archive-p (filename &optional recog cached-only noerror)
  "Return non-nil if FILENAME is a compressed archive."
  (interactive "fFile to investigate: ")
  (or (file-compressed-p filename recog cached-only noerror)
      (file-archive-p filename recog cached-only noerror)))

(defun file-box-p (filename &optional recog cached-only noerror)
  "Return non-nil if FILENAME is boxed binary, that is a
container format that can be unfolded or decompressed when
matched."
  (interactive "fFile to investigate: ")
  (file-match filename (fmd-class-keys 'box) recog cached-only noerror))
;; Use: (file-box-p "/usr/share/info/gzip.info.gz") => t
;; Use: (file-box-p "~/pnw.tar.gz") => t
;; Use: (file-box-p "/etc/X11/Xwrapper.config") => nil

;; ---------------------------------------------------------------------------

(defun file-idutils-root-directory-p (dir &optional recog cached-only)
  "Return non-nil if directory DIR contains an idutils tags database."
  (and (file-directory-p dir)
       (file-match (expand-file-name "ID" dir)
                   'Idutils recog cached-only t)))
;; Use: (file-idutils-root-directory-p "~/cognia/") => non-nil
;; Use: (file-idutils-root-directory-p "~/dummy/") => nil

(defun file-etags-root-directory-p (dir &optional recog cached-only)
  "Return non-nil if directory DIR contains an Emacs tags database."
  (and (file-directory-p dir)
       (file-match (expand-file-name "TAGS" dir)
                   'Emacs-tags recog cached-only t)))
;; (eval-when-compile (assert-nonnil (file-ectags-root-directory-p "~/cognia/")))
;; Use: (file-etags-root-directory-p "~/dummy/") => nil

(defun file-ectags-root-directory-p (dir &optional recog cached-only)
  "Return non-nil if directory DIR contains an Exuberant CTags tags
database."
  (and (file-directory-p dir)
       (file-match (expand-file-name "tags" dir)
                   'Exuberant-Ctags recog cached-only t)))
;; Use: (file-ectags-root-directory-p "~/cognia/") => non-nil

(defun file-etags-or-ectags-root-directory-p (dir &optional recog cached-only)
  "Return non-nil if directory DIR contains an Emacs tags or Exuberant
  CTags (\"tags\" or \"TAGS\") tags database."
  (and (file-directory-p dir)
       (or (file-match (expand-file-name "tags" dir)
                       'Exuberant-Ctags recog cached-only t)
           (file-match (expand-file-name "TAGS" dir)
                       'Emacs-tags recog cached-only t)
           )))
;; Use: (file-ectags-root-directory-p "~/cognia/")

(defun file-gtags-root-directory-p (dir &optional recog cached-only noerror)
  "Return non-nil if directory DIR contains a GNU GLOBAL (gtags) database."
  (and (file-directory-p dir)
       (file-match dir 'GNU-GLOBAL-Directory recog cached-only t)))
;; Use: (file-gtags-root-directory-p "~/cognia/")
;; Use: (file-gtags-root-directory-p "~/ware/EWSim/")

(defun file-cscope-root-directory-p (dir &optional recog cached-only noerror)
  "Return non-nil if directory DIR contains an Cscope database."
  (and (file-directory-p dir)
       (directory-has-all-p dir '("cscope.out"
                                  "cscope.in.out"
                                  "cscope.po.out"))))
;; Use: (file-cscope-root-directory-p "~/cognia/")

(defun file-tags-root-directory-p (&optional dir recog cached-only noerror)
  "Return non-nil if directory DIR contains any kind of tags database.
Returned value may be the type (as a string) of the tags database
found."
  (unless dir (setq dir default-directory))
  (or
   (file-etags-root-directory-p dir recog cached-only)
   (file-ectags-root-directory-p dir recog cached-only)
   (file-gtags-root-directory-p dir recog cached-only noerror)
   (file-idutils-root-directory-p dir recog cached-only)
   (file-cscope-root-directory-p dir recog cached-only noerror))
  )
;; Use: (file-tags-root-directory-p)
;; Use: (file-tags-root-directory-p "~/cognia/")
;; Use: (file-tags-root-directory-p "~/cognia/pmdb/")

;; TODO: Use to help EDE figure out the project root directory using
;; `semanticdb-project-predicate-functions' defaults to `ede-directory-project-p'
;; `semanticdb-project-root-functions' defaults to `ede-toplevel-project-or-nil'
;; Note: Compare with:
;; Use: (ede-toplevel-project-or-nil "~/cognia")
;; Use: (ede-toplevel-project-or-nil "~/cognia/pmdb")
;; Use: (ede-toplevel-project-or-nil "~/ware/emacs")
;; Use: (ede-directory-project-p "~/ware/gcc")
;; Use: (ede-directory-project-p "~/ware/valgrind")
;; Use: (ede-directory-project-p "~/ware/global")
;; Use: (ede-directory-project-p "~/ware/emacs")
;; Use: (ede-directory-project-p "~/cognia")
;; Use: (ede-directory-project-p "~/cognia/pmdb")
(defun file-project-root-directory-p (&optional dir recog cached-only noerror)
  "Return non-nil if directory DIR contains any kind of tags database.
Returned value may be the type (as a string) of the tags database
found."
  (let ((dir (or dir default-directory)))
    (or (file-vc-root-directory-p dir)
        ;;(file-tags-root-directory-p dir)
        )))
;; Use: (file-project-root-directory-p)
;; Use: (file-project-root-directory-p "~/cognia")
;; Use: (file-project-root-directory-p "~/cognia/semnet")

(defun file-build-directory-p (&optional dir recog format)
  "Return non-nil if DIR contains a build file."
  (directory-files-of-types dir 'Build-Tool-Script recog (or format
                                                             'type-and-file)
                            t))
;; Use: file-build-directory-p (&optional dir recog format)
;; Use: (file-build-directory-p "~/apt-source/tgt-1.0.17")

;; Use: (file-match "~/cognia/GNUmakefile" 'Makefile)
;; Use: (file-match "~/cognia/GNUmakefile" 'Build-Tool-Script)
;; Use: (file-match "~/apt-source/tgt-1.0.17/Makefile" 'Build-Tool-Script)

;; ---------------------------------------------------------------------------

(defun file-uneditable-directory-p (dir &optional recog cached-only noerror)
  "Return non-nil if DIR is an existing directory which is not supposed to manually edited.
Does not care about current user privilegies."
  (and (file-directory-p dir)
       (file-match dir 'Uneditable-Dir recog cached-only noerror)))

(defun file-editable-directory-p (dir &optional recog cached-only noerror)
  "Return non-nil if DIR is an existing directory which is supposed to manually edited.
Does not care about current user privilegies."
  (and (file-directory-p dir)
       (file-match dir 'Editable-Dir recog cached-only noerror)))
;; Use: (file-editable-directory-p "/etc")
;; Use: (file-editable-directory-p "/etcx")
;; Use: (file-editable-directory-p "~/cognia/.git") => nil
;; Use: (file-editable-directory-p "~/cognia/autom4te.cache") => nil
;; Use: (file-editable-directory-p "/usr/lib/xorg/extra-modules") => t

;; ---------------------------------------------------------------------------

(defun file-uneditable-p (file &optional recog cached-only noerror)
  "Return non-nil if FILE is *not supposed to be manually edited*.
Does not care about current user privilegies."
  (file-match file 'Uneditable recog cached-only noerror))

(defun file-editable-p (file &optional recog cached-only noerror)
  "Return non-nil if FILE is *supposed to be manually edited*.
Does not care about current user privilegies."
  (file-match file 'Editable recog cached-only noerror))

;; ---------------------------------------------------------------------------

(defun file-uneditable-regular-p (file &optional recog cached-only noerror)
  "Return non-nil if file FILE is an existing regular file which is *not supposed to be manually edited*.
Does not care about current user privilegies."
  (and (file-regular-p file)        ;Note: All editable files are regular right?
       (file-match file 'Uneditable recog cached-only noerror)
       ))
;; Use: (file-uneditable-regular-p "/etc") => nil
;; Use: (file-uneditable-regular-p "/etcx") => nil
;; Use: (file-uneditable-regular-p "/bin/ls") => '(Uneditable ELF)
;; Use: (file-uneditable-regular-p "/windows/WINDOWS/explorer.exe") => '(Uneditable)
;; Use: (file-uneditable-regular-p "/bin/static-sh") => '(Uneditable ELF)
;; Use: (file-uneditable-regular-p "/usr/lib/xorg/extra-modules") => nil
;; Use: (file-uneditable-regular-p "~/cognia/semnet/preg.cpp") => nil

(defun file-editable-regular-p (file &optional recog cached-only noerror)
  "Return non-nil if file FILE is an existing regular file which is *supposed to be manually edited*.
Does not care about current user privilegies."
  (and (file-regular-p file)        ;Note: All editable files are regular right?
       (file-match file 'Editable recog cached-only noerror)
       ))
;; Use: (file-editable-regular-p "/etc") => nil
;; Use: (file-editable-regular-p "/etcx") => nil
;; Use: (file-editable-regular-p "/etc/passwd") => '(Editable)
;; Use: (file-editable-regular-p "~/cognia/.semantic.cache") => nil
;; Use: (file-editable-regular-p "~/cognia/TAGS") => nil
;; Use: (file-editable-regular-p "~/cognia/tags") => nil
;; Use: (file-editable-regular-p "~/cognia/GTAGS") => nil
;; Use: (file-editable-regular-p "/root") => '(Editable)
;; Use: (file-editable-regular-p "/etc/X11/Xwrapper.config") => '(Editable)
;; Use: (file-editable-regular-p (elsub "mine/ectags.elc")) => nil
;; Use: (file-editable-regular-p "/windows/WINDOWS/explorer.exe") => nil
;; Use: (file-editable-regular-p "/usr/lib/vmware/isoimages/windows.iso") => nil
;; Use: (file-editable-regular-p "/usr/lib/xorg/extra-modules") => nil
;; Use: (file-editable-regular-p "~/cognia/semnet/preg.cpp") => '(Editable)

;; Use: (file-editable-regular-p (elsub "haskell-mode")) => nil
;; Use: (file-editable-directory-p (elsub "haskell-mode")) => t
;; Use: (fcache-ftype (fcache-chase-links (fcache-of (elsub "haskell-mode"))))
;; Use: (fcache-directory-p (fcache-of (elsub "haskell-mode")))

(defun make-buffer-read-only-auto-reverted-if-uneditable (&optional buffer)
  "Make BUFFER read-only if its file is uneditable."
  (unless buffer-read-only
    (let ((file (buffer-file-name buffer)))
      (when (and file                   ;buffer has a file
                 (file-uneditable-regular-p file nil nil t))
        (setq buffer-read-only t)
        (auto-revert-mode 1)
        (message "Made %s buffer read-only and auto-reverted"
                 (file-type-names file t 'font-lock-type-face))
        ))))
(add-hook 'find-file-hook 'make-buffer-read-only-auto-reverted-if-uneditable)

;; ---------------------------------------------------------------------------

(defun fmd-category-types (&optional category)
  (if category
      (extract-elements
       `(lambda (ftype) (equal ,category (ftype-category ftype)))
       fmd-types)
    fmd-types))
;; Use: (fmd-category-types "Build Tool Script Code")
;; Use: (fmd-category-types "Special Text")
;; Use: (fmd-category-types nil)
;; Use: (fmd-category-types "Backup")
;; Use: (fmd-category-types "Source Code")
;; Use: (fmd-category-types "Script Code")
;; Use: (fmd-category-types "Compressed")

(defun fmd-ptype-types (ptype)
  (if ptype
      (extract-elements
       `(lambda (ftype) (eq ',ptype (ftype-ptype ftype)))
       fmd-types)
    fmd-types))
;; Use: (fmd-ptype-types 'bin)
;; Use: (fmd-ptype-types 'txt)
;; Use: (fmd-ptype-types 'box)
;; Use: (fmd-ptype-types 'ascii)

;; ---------------------------------------------------------------------------

(defun fmd-category-keys (category)
  "Extract the keys of CATEGORY and return them as a list."
  (delete-dups (delq nil (mapcar
                          `(lambda (ftype)
                             (when (or (not ,category)
                                       (equal ,category (ftype-category ftype)))
                               (ftype-key ftype)))
                          fmd-types))))

(defun fmd-class-keys (ptype)
  "Extract the keys of CATEGORY and return them as a list."
  (delete-dups (delq nil (mapcar
                          `(lambda (ftype)
                             (when (or (not ',ptype)
                                       (equal ',ptype (ftype-ptype ftype)))
                               (ftype-key ftype)))
                          fmd-types))))

;; ---------------------------------------------------------------------------

(defun file-type-names (filename &optional cached-only type-face skip-types)
  "Return all the type names of FILENAME as a string.
The strings contains a comma-separated list of types names. If
CACHED-ONLY is non-nil only use that cached types."
  (let* ((types (remlq skip-types
                       (file-match filename t nil cached-only)))
         (names (mapconcat
                 (lambda (ftype)
                   (ftype-name/doc (fmd-get-type ftype)))
                 types ",")))
    (when (and names (stringp names) (not (equal names ""))) ;if any names
      (concat "("
              (if type-face
                  (propertize names 'face type-face) ;pretty print
                names)
              ")"))))
;; Use: (ftype-name/doc (fmd-get-type 'GPCH))
;; Use: (file-type-names "~/ware/gcc/x86_64-unknown-linux-gnu/32/libstdc++-v3/include/x86_64-unknown-linux-gnu/bits/stdtr1c++.h.gch/O2g.gch")
;; Use: (file-editable-regular-p "/bin/zcat")
;; Use: (file-match "/bin/zcat" t nil nil)
;; Use: (file-type-names "/bin/ls" t)
;; Use: (file-type-names "/bin/ls")
;; Use: (file-type-names "/bin/nonbody")
;; Use: (file-type-names "~/cognia")
;; Use: (file-type-names "~/.emacs")
;; Use: (file-type-names "/bin/sh.distrib")
;; Use: (file-type-names "/bin/sh.distrib" t)
;; Use: (file-type-names "/bin/zcat")
;; Use: (file-type-names "/bin/zcat" t)
;; Use: (file-type-names "~/cognia/utils.d" t)
;; Use: (benchmark-run 1 (file-type-names "/bin/ls"))
;; Use: (benchmark-run 1 (file-type-names "/bin/ls" t))
;; Use: (benchmark-run 1 (file-type-names "/bin/grep" t))
;; Use: (file-type-names "/")

;; ---------------------------------------------------------------------------

;;; TODO: Add :view as `find-file-read-only' of not already defined and :edit as `find-file' and :edit-binary `find-file-literally'
(defun url-ops (url &optional category recog)
  "Get types that matches URL using RECOG. If CATEGORY is
non-nil only try types that belong to that category."
  (when url
    (cond ((file-regular-p url)
           (let (ops)
             (mapc `(lambda (ftype)
                      (let ((op (when (and (or (not ,category)
                                               (equal ,category (ftype-category ftype)))
                                           (file-match ,url (ftype-key ftype) (quote ,recog)))
                                  (ftype-ops ftype)
                                  )))
                        (when op
                          (setq ops (append ops op)))))
                   fmd-types)
             (delete-dups ops)
             ops))
          ((file-directory-p url)
           ;; TODO: Do something with directories.
           )
          ((string-match (rx (: "svn" (? "+ssh") "://")) url)
           '("git svn clone url>" url))
          ((string-match "git://" url)
           '("git grep < some regex >" url))
          )))
;; Use: (url-ops "/etc/")
;; Use: (url-ops "~/cognia/utils.c")
;; Use: (url-ops "~/cognia/tests/t_hash.cpp")
;; Use: (url-ops "/bin/ls")
;; Use: (cadr (assq :debug (url-ops "/bin/ls")))
;; Use: (url-ops "~/cognia/GNUmakefile")
;; Use: (url-ops "~/cognia")
;; Use: (url-ops "~/cognia/Makefile" "Build Tool Script Code" 'name-or-contents-recog)
;; Use: (url-ops "~/cognia/Jamroot" "Build Tool Script Code" 'name-or-contents-recog)
;; Use: (url-ops "~/cognia/SConstruct" "Build Tool Script Code" 'name-or-contents-recog)
;; Use: (url-ops "~/cognia/utils.h" nil 'name-recog)
;; Use: (assq :build (url-ops "~/cognia/utils.h" nil 'name-recog))
;; Use: (url-ops "~/bin/pbuild")
;; Use: (url-ops "~/foo.cpp")

(defvar file-op-names
  '((:debug "Debug")
    (:trace "Trace")
    (:profile "Profile")
    (:execute "Execute")
    )
  "Alist of operation symbols and names")

(defun file-op-name-string (symbol)
  "Convert file operation SYMBOL to its string name."
  (cadr (assq symbol file-op-names)))
;; Use: (file-op-name-string :debug)

(defun read-file-op (filename &optional category recog try-last)
  "Read Operation associated with FILENAME."
  (let* ((ops (mapcar (lambda (type)
                        (capitalize (substring (symbol-name (car type)) 1)))
                      (url-ops filename category recog)))
         (fcache (fcache-of filename))
         (prop :url-ops-history)
         (hist (when filename
                 (fcache-get-property fcache prop)))
         (default (if hist
                      (first hist)
                    (first ops))))
    (or (when try-last                  ;if reuse cache directly
          (first hist))                 ;use it if present
        (intern
         (let ((icicle-default-in-prompt-format-function
                (lambda (default) (format " (%s)" (faze default 'type)))))
           (let* ((choice (completing-read (format "Operation on %s: "
                                                   (faze filename 'file))
                                           ops nil t nil nil default))
                  (str (if (symbolp choice)
                           (symbol-name choice)
                         choice))
                  )
             (when fcache
               (fcache-add-to-history-property fcache prop str))
             (concat ":" (downcase str))))))))
;; Use: (read-file-op "~/.emacs.d/auto-builds/gcc/Debug~/f")
;; Use: (read-file-op "/bin/ls")
;; Use: (read-file-op "~/f.cpp")

(when nil
  (progn
    (dcache-reset)
    (touch-file "~/.emacs.d/auto-builds/gcc/Debug~/f")
    (touch-file "/bin/ls")
    (list
     (read-file-op "~/.emacs.d/auto-builds/gcc/Debug~/f")
     (file-elf-p "~/.emacs.d/auto-builds/gcc/Debug~/f")
     (file-elf-p "/bin/ls")
     (fmd-match-uncached "~/.emacs.d/auto-builds/gcc/Debug~/f" 'ELF)
     (file-match "/bin/ls" 'ELF)
     )))

;; Use: (read-file-op "/bin/zgrep")
;; Use: (assq (read-file-op "/bin/ls") (url-ops "/bin/ls"))
;; Use: (assq :debug (url-ops "/bin/ls"))

(defun file-op (filename prog-type &optional category recog)
  "Lookup program string or lambda of type PROG-TYPE that can
operate on FILENAME."
  (cadr (assq prog-type (url-ops filename category recog))))
;; Use: (file-op "/etc/" :debug)
;; Use: (file-op "/bin/ls" :debug)
;; Use: (file-op "~/alt/i586-mingw32/bin/wxrc.exe" :execute)
;; Use: (file-op "/usr/include/stdio.h" :build nil 'name-or-contents-recog)
;; Use: (file-op "~/cognia/utils.h" :build nil 'name-or-contents-recog)
;; Use: (file-op "~/bin/pbuild" :execute)
;; Use: (functionp (file-op "~/FOI/FOCUS/grus_default.m" :execute))
;; Use: (funcall (file-op "~/FOI/FOCUS/grus_default.m" :execute) "~/FOI/FOCUS/grus_default.m")
;; Use: (file-op "~/f.c" :build)
;; Use: (file-op "~/f.cpp" :build)

;; ---------------------------------------------------------------------------

(defun file-build (filename &optional on-success try-last)
  "Build FILENAME. Upon build success call ON-SUCCESS. Returns
the build output."
  (let ((builder (file-op filename :build)))
    (cond ((functionp builder)          ;file to be executed
           (funcall builder filename on-success nil nil nil nil try-last)
           ;; (if on-success
           ;;     (funcall builder filename on-success) ;WARNING: Builder returns e-prog but does not finish directly!
           ;;   (funcall builder filename))
           )
          (t
           (message "TODO: Handle string builder %s !" builder)
           filename))))

;; ---------------------------------------------------------------------------

(defun file-try-debug (filename &optional core category recog args silent)
  "Return non-nil upon success."
  (let ((cmd (file-op filename :debug category recog)))
    (if cmd
        (funcall cmd filename
                 (append (when (and core
                                    (file-elf-p filename))
                           `("-c" ,core))
                         (cond ((eq args 'skip)                  ;if args is `skip'
                                nil)                             ;don't ask for them
                               (args                             ;if args given
                                args)                            ;use them
                               (t                                ;if no args given
                                (read-file-execute-args filename) ;ask for them
                                ))))
      (unless silent
        (message "No debugger available for file %s"
                 (faze filename 'file))
        (ding))
      nil)))
;; Use: (file-try-debug "/bin/ls")
;; Use: (progn (setq dummy (file-try-debug "/bin/ls")) dummy)
;; Use: (progn (setq dummy (file-try-debug "/etc/passwd")) dummy)

;; TODO: Merge with ede-debug-target()
(defun file-debug-single (filename &optional args silent)
  "Try to Debug FILENAME directly or (EDE) target associated with
FILENAME. Optional argument ARGS is a list of string arguments to
send to debugged executable FILENAME."
  (interactive (read-file-name-debuggable "Debug program file"))
  (file-try-debug filename nil nil nil args silent))
;; Use: (file-debug-single "/bin/ls")

(defun file-debug-elf-core (filename core &optional args silent)
  "Try to Debug ELF FILENAME and CORE directly or (EDE) target
associated with FILENAME."
  (interactive (list (read-file-name-debuggable "Debug program file")
                     (read-file-name-of-types "Debug core file: " 'ELF)))
  (file-try-debug filename core nil nil args silent))

;; Use: (call-interactively 'file-debug-single)
;; Use: (file-debug-single "/bin/ls")
;; Use: (file-debug-single "/etc/passwd")
;; Use: (file-debug-single "~/bin/pbuild")

(global-set-key [(control c) (d)] 'file-debug-single)
(global-set-key [(meta f10)] 'file-debug-single)
(global-set-key [(control c) (D)] 'file-debug-elf-core)

;; ---------------------------------------------------------------------------

(defun file-build-targets (filename)
  "Return build targets of FILENAME."
  '())
;; (file-build-targets "~/cognia/tests/t_chash.cpp")

(defun file-set-breakpoint ()
  "Set breakpoint at cursor position in current buffer."
  (interactive)
  (when (require 'gud nil t)
    (unless (and (boundp 'gud-minor-mode)
                 gud-minor-mode)        ;unless buffer is already being debugged
      (let ((buffer-file buffer-file-name))
        (if (and buffer-file            ;buffer-specific type-keys (if any)
                 (car (file-match buffer-file 'GUD-Debuggable)))
            (progn (file-debug-single buffer-file)
                   (when (and (require 'gud nil t)
                              (fboundp 'gud-break))
                     (gud-break nil)))
          (if buffer-file
              (message "Buffer has no file related with it")
            (message "Buffer file %s is not debuggable by GUD"
                     (faze buffer-file 'file))))))))
(global-set-key [(control x) (\ )] 'file-set-breakpoint)
(global-set-key [(control x) (\ )] 'gud-break)

;; Add it to the "Tools" menu
(define-key-after menu-bar-tools-menu [file-debug-single]
  '(menu-item "Debugger Multi-Window (GDBA)..." file-debug-single
              :help "Debug a program more graphically from within Emacs with GDB")
  'gdb)

;; ---------------------------------------------------------------------------

;; Do on Load
(fmd-add-defaults)
(fmd-remake-types-stat)
(fmd-remake-single-matchers)           ;NOTE: Call this at the end!

;; ---------------------------------------------------------------------------
;; Benchmarks!

;; Use: (benchmark-run 10 (expand-file-name "tscan-tests/true-link"))
;; Use: (benchmark-run 10 (file-attributes "tscan-tests/true-link"))
;; Use: (benchmark-run 10 (file-chase-links "tscan-tests/true-link"))

;; Use: (benchmark-run 10 (file-elf-p "tscan-tests/true"))
;; Use: (benchmark-run 10 (file-elf-p "tscan-tests/true-link"))

;; Use: (benchmark-run 10 (file-editable-regular-p "/etc/X11/Xwrapper.config"))

;; Use: (touch-file "~/.bashrc")

;; Use: (benchmark-run 10 (file-match "~/.bashrc" 'Editable) nil)
;; Use: (benchmark-run 10 (file-match "~/.bashrc" 'Editable nil t))

;; Use: (benchmark-run 10 (file-match "/bin/ls" 'Uneditable) nil)
;; Use: (benchmark-run 10 (file-match "/bin/ls" 'Uneditable nil t))

;; Use: (benchmark-run 10 (file-editable-regular-p "~/.bashrc"))
;; Use: (benchmark-run 10 (file-elf-p "~/.bashrc"))
;; Use: (benchmark-run 10 (file-uneditable-regular-p "/bin/ls"))

;; Use: (benchmark-run 10 (file-box-p "/usr/share/info/gzip.info.gz"))

;; TODO: There is big performance difference here! For some strange
;; reason `insert-file-contents-literally' is around 11 times slower
;; than `find-file-noselect'! See Google Groups post at
;; http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/f9d45022b5ae5ce2#.

(defun benchmark-inserts (filename)
  "Benchmark different kinds of inserts of FILENAME."
  (interactive)
  (list
   (cons
    (benchmark-run 1
      (with-temp-buffer
        (buffer-disable-undo)
        (insert-file-contents-literally filename nil)
        ))
    "insert-file-contents-literally")
   (cons
    (benchmark-run 1
      (save-excursion
        (let* ((existing-buf (get-file-buffer filename))
               (buf (or existing-buf
                        (find-file-noselect filename t t))))
          (set-buffer buf)
          (when (not existing-buf)
            (kill-buffer buf))
          )))
    "find-file-noselect"))
  )
;; Use: (benchmark-inserts "/var/cache/apt/pkgcache.bin")
;; Use: (benchmark-inserts "/var/cache/apt/srcpkgcache.bin")

;; ---------------------------------------------------------------------------

(provide 'filedb)
