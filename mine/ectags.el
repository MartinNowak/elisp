;;; ectags.el --- Interface to Exuberant Ctags (ECtags).

;; Copyright (C) 2008 Per Nordlöw
;; Author: Per Nordlöw <per.nordlow@gmail.com>
;; Maintainer: Per Nordlöw <per.nordlow@gmail.com>

;; TODO Use `completion-extra-properties' to display extra properties such as function doc etc.
;; FIXME: class tags are not put in their namespaces for example semnet::filesystem::Dir'c is stored only as Dir'c
;; TODO Why does (symbol-plist (intern-soft "bob'f" *ectags*)) have `:path' property?
;; TODO M-. should wait for current ectags async process to finish before
;; parsing it file using `call-process' and
;; `comint-output-filter-functions'. See:
;; http://stackoverflow.com/questions/3572532/how-to-wait-for-capture-aysnchronous-shell-command-output-in-emacs-lisp

;;; Code:

(eval-when-compile (require 'cl))

(provide 'ectags)

(require 'desktop)
(require 'fcache)
(require 'hl-line)
(require 'etags)
(require 'custom)
(require 'easymenu)

(require 'pnw-regexps)
(require 'obarray-utils)
(require 'power-utils)
(require 'file-utils)
(require 'filedb nil t)                   ;Soft require.
(require 'thingatpt-syntax)
(require 'rx-delim)
(require 'strip-common)
(require 'font-lock-extras)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Custom stuff

(defgroup ectags nil
  "Exuberant Ctags Support for Emacs"
  :group 'tools)

(defcustom ectags-before-find-tag-hook nil
  "*List of functions to call prior to `find-ectag'."
  :group 'ectags
  :type 'hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Variables

(defconst ectags-command-name "ectags"
  "Ectags command name.")

(defconst ectags-command-args '("--sort=yes" ;need for duplicates to be detected
                                "--links=no"
                                "--excmd=number"
                                "--languages=MatLab,C,C++,Java,C#,Python,Ruby,Lisp,Sh" ;Skipping HTML
                                "--extra=+f"
                                "--file-scope=yes"
                                ;;"--fields=afikmnsSt"
                                "--fields=afikmsSt"
                                )
  "Ectags command arguments list.")

(defvar ectags-temp-buffer-name " *ectags*"
  "Buffer name of current ectags table.")

(defvar ectags-file-name nil
  "*File name of ectags table.
To switch to a new tags table, setting this variable is sufficient.
If you set this variable, do not also set `ectags-table-list'.
Use the `ectags' program to make a ectags table file.")

(defvar ectags-file-id nil
  "Modification Time and File Size Id for `ectags-file-name'.")

(defvar *ectags-alist* nil
  "Association List used for ectags completions.")

(defvar *ectags* nil
  "Obarray used for ectags completions. To filter out symbols,
  use `mapatoms'.")

(defvar ectags-tag-files nil
  "Tag files in current ectags.")
(defvar ectags-tag-fcaches nil
  "Tag fcaches in current ectags.")

;; ---------------------------------------------------------------------------

(defcustom ectags-file-display-prefix "@"
  "This separator should be easy to type and not have a special
  meaning in regular expressions.")

(defcustom ectags-kind-display-prefix "'"
  "This separator should be easy to type and not have a special
  meaning in regular expressions.")

(defcustom ectags-lazy-hook nil
  "Hook to be run by \\[ectags-lazy-completion-table] before building the tags completion table.
  See `run-hooks'."
  :group 'ectags
  :type 'hook)

(defcustom find-ectag-hook nil
  "Hook to be run by \\[find-ectag] after finding a tag.
See `run-hooks'. The value in the buffer in which
\\[find-ectag] is done is used, not the value in the buffer
\\[find-ectag] goes to."
  :group 'ectags
  :type 'hook)

;; ---------------------------------------------------------------------------

(defconst ectags-kinds
  '(
    (?a "Anchor" font-lock-constant-face) ;HTML Anchor (<a href>. Kind of like goto adress.
    (?c "Class" font-lock-class-face) ;class
    (?d "Macro" font-lock-preprocessor-face) ;define
    (?e "Enumeration" font-lock-enumeration-face) ;enumeration
    (?f "Function" font-lock-function-name-face) ;function or method
    (?F "File" font-lock-file-name-face) ;file
    (?g "Enumerator" font-lock-enumerator-face) ;enumerator
    (?l "Enumerator" font-lock-enumerator-face) ;enumerator (Ada)
    (?m "Member Variable" font-lock-variable-name-face) ;member (of structure or class data)
    (?p "Function Prototype" font-lock-function-name-face) ;function prototype
    (?s "Structure" font-lock-structure-face) ;structure
    (?t "Typedef" font-lock-type-face) ;typedef
    (?u "Union" font-lock-union-name-face) ;union
    (?v "Variable" font-lock-variable-name-face) ;variable
    (?n "Namespace" font-lock-keyword-face) ;namespace

    (?C "Constructor" font-lock-constructor-face) ;constructor, ctor
    (?D "Destructor" font-lock-destructor-face) ;destructor, dtor

    ;; D
    ;; See: https://github.com/Hackerpilot/Dscanner#supported-kinds
    (?k "Keyword" font-lock-keyword-face) ;D Programming Language
    (?P "Package" font-lock-keyword-face) ;D Programming Language
    (?M "Module" font-lock-keyword-face) ;D Programming Language
    (?T "Template" font-lock-keyword-face) ;D Programming Language
    (?X "Mixin" font-lock-keyword-face) ;D Programming Language
    (?V "Version" font-lock-keyword-face) ;D Programming Language
    ) "Tags kind faces alist.")
;; Use: (caddr (assoc ?a ectags-kinds))

(defconst ectags-kinds-chars (mapcar 'car ectags-kinds))

(defvar ectags-syntax-kind-map (make-hash-table)
  "Hash Table that maps syntax contexts to ectags kind character(s).")
(defun ectags-build-syntax-kind-map ()
  "Build `ectags-syntax-kind-map'."
  (clrhash ectags-syntax-kind-map)
  (let ((m ectags-syntax-kind-map))
    (puthash tag-ctx-class-ctor-call ?C m)
    (puthash tag-ctx-class-dtor-call ?D m)
    (puthash tag-ctx-class-declaration ?c m)
    (puthash tag-ctx-class-definition ?c m)
    (puthash tag-ctx-class-reference ?c m)
    (puthash tag-ctx-include ?F m)
    (puthash tag-ctx-function-macro ?d m)
    (puthash tag-ctx-constant-macro ?d m)
    (puthash tag-ctx-macro-reference ?d m)
    (puthash tag-ctx-member-function-call '(?f ?d) m)
    (puthash tag-ctx-function-call '(?C ?f ?d) m)
    (puthash tag-ctx-struct-reference ?s m)
    (puthash tag-ctx-union-reference ?u m)
    (puthash tag-ctx-enum-reference ?g m)
    (puthash tag-ctx-type-reference '(?c ?t ?e ?d) m)
    (puthash tag-ctx-variable-assignment '(?v ?m) m)
    (puthash tag-ctx-variable-declaration ?v m)
    (puthash tag-ctx-variable-definition ?v m)
    (puthash tag-ctx-variable-definition ?v m)
    (puthash tag-ctx-symbol-reference '(?v ?m ?d ?e ?f) m)
    (puthash tag-ctx-scope '(?c ?n) m)
    ))
(ectags-build-syntax-kind-map)

(defun ectags-syntax-context-kind (ctx)
  "Lookup ectags kinds from syntax context CTX.
If CTX is nil default to `ectasg-kinds-chars'."
  (let ((value (if ctx
                   (gethash ctx ectags-syntax-kind-map)
                 ectags-kinds-chars)))
    (if (not value)
        (warn "Unknown syntax context %s!" ctx))
    (if (listp value)
        value
      (list value))))
;; Use: (ectags-syntax-context-kind tag-ctx-variable-definition)
;; Use: (ectags-syntax-context-kind tag-ctx-symbol-reference)
;; Use: (ectags-syntax-context-kind tag-ctx-type-reference)
;; Use: (ectags-syntax-context-kind nil)
;; Use: (ectags-syntax-context-kind 'x)

(defun ectags-syntax-context-kind-atpt (&optional mode pos)
  (ectags-syntax-context-kind
   (thing-at-point-syntax-context mode pos)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Functions

(defvar ectags-kind-faces nil
  "Faces for tag kinds.")
;; Use: (describe-hash-table 'ectags-kind-faces)
;; Use: (clrhash ectags-kind-faces)

(defun ectags-rebuild-kind-faces-hash ()
  "Rebuild Hash Table that maps key-chars to key-faces."
  (setq ectags-kind-faces
        (make-hash-table :size (length ectags-kinds) :test 'eq)) ;Warning: Note: `eq' only works for chars!
  (dolist (kind ectags-kinds)
    (puthash (car kind)
             (caddr kind)
             ectags-kind-faces)))
(ectags-rebuild-kind-faces-hash)

(defun ectags-kind-face (kind-char)
  "Lookup the face of KIND-CHAR."
  (gethash kind-char ectags-kind-faces))
;; Use: (ectags-kind-face ?a)

(defun ectags-scan-find-dup-cnt (tag-patt)
  "Look ahead in subsequent lines to get number of occurrencies
of the regexp TAG-PATT. Note: This requires the tags file to be
sorted alphabetically."
  (save-excursion
    (let ((dup 0))                         ;duplication counter
      (while (looking-at (concat "^" tag-patt "\t"))
        (setq dup (1+ dup)) ;increase duplication counter
        (forward-line)
        )
      (when (> dup 0) ;if duplicates were found
        (setq dup (1+ dup)) ;include first hit as a duplicate aswell
        ;;(message "%s is %d-tuple" tag-patt dup)
        )
      dup)))

(defconst ectags-format-vi-full-matcher
  (concat "^"                           ;line start
          "\\(" "[^\t]+" "\\)" "\t" ;`tagname'
          "\\(" "[^\t]+" "\\)" "\t" ;`tag-file'

          ;; "\\(?:"
          ;; "\\(?:" "/\\^" "\\(" ".*" "\\)" "\$/;\"" "\\)" ;Literal address
          ;; "\\|"
          ;; "\\(?:" "\\(" "[[:digit:]]+" "\\)" ";\"" "\\)" ;Line address
          ;; "\\)"

          "\\(" "[[:digit:]]+" "\\)" ";\"" ;Line address

          "\t?" "\\(" "[[:alpha:]]?" "\\)"   ;`tag-kind'

          ;; "\t?" "\\(?:" "\\(?:" "line:" "\\(" "[[:digit:]]+" "\\)" "\\)" "\\)"

          "\t?" "\\(?:" "\\(?:" "namespace:" "\\(" "[^\t\n]+" "\\)" "\\)?" "\\)"
          "\t?" "\\(?:" "\\(?:" "file:" "\\(" "[^\t\n]*" "\\)" "\\)?" "\\)" ;Note: can be empty
          "\t?" "\\(?:" "\\(?:" "inherits:" "\\(" "[^\t\n]+" "\\)" "\\)?" "\\)"

          ;; Note: If match ""__anona[0-9]+" its anonymous and can be skipped
          "\t?" "\\(?:" "\\(?:" (regexp-opt '("class:"
                                              "typeref:struct:"
                                              "typeref:enum:"
                                              "struct:"
                                              "enum:"))
          "\\(" "[[:alpha:][:digit:]_::]+" "\\)" "\\)?" "\\)"

          "\t?" "\\(?:" "\\(?:" "access:" "\\(" "[[:alpha:]_]+" "\\)" "\\)?" "\\)"

          "\t?" "\\(?:" "\\(?:" "implementation:" "\\(" "[[:alpha:]_]+" "\\)" "\\)?" "\\)"

          "\t?" "\\(?:" "\\(?:" "signature:" "\\(" "[^\t\n]+" "\\)" "\\)?" "\\)"
          )
  "Regexp matching a tag entry in ECtags Vi (Extended) Format.")
(eval-when-compile
  (assert-nonnil
   (with-temp-buffer
     (insert "is_cyclic	semnet/patt.hpp	224;\"	f	class:Patt	access:public	signature:() const")
     (insert "added_cb	semnet/panyfile.hpp	93;\"	f	class:pAnyFile	access:public	implementation:virtual	signature:() const")
     (goto-char (point-min))
     (when (re-search-forward ectags-format-vi-full-matcher nil t)
       (list
        :name (match-string-no-properties 1)
        :file (match-string-no-properties 2)
        ;;:addr (match-string-no-properties 3)
        :anum (match-string-no-properties 3)
        :kind (match-string-no-properties 4)
        ;;:line (match-string-no-properties 5)
        :namespace (match-string-no-properties 6)
        ;;:file2 (match-string-no-properties 7)
        :inherits (match-string-no-properties 7)
        :structure (match-string-no-properties 8)
        :access (match-string-no-properties 9)
        :implementation (match-string-no-properties 10)
        :signature (match-string-no-properties 11)
        ))))
  )

(defconst ectags-format-x-matcher
  (concat "^"
          "\\(" "[^ ]+" "\\)" "[ ]+" ;tag name
          "\\(" "[^ ]+" "\\)" "[ ]+" ;tag file
          )
  "Regexp the matches a tag entry in ECtags x format."  )

(defun ectags-register-tag-fcache (fcache)
  "Register FILENAME as a file containing ectags."
  (if ectags-tag-fcaches
      (nconc ectags-tag-fcaches (list fcache)) ;append hit
    (setq ectags-tag-fcaches (list fcache))))
(defun ectags-unregister-tag-file (filename)
  "Register FILENAME as a file containing ectags."
  (when ectags-tag-files
      (delete filename ectags-tag-files)))
(defun ectags-register-tag-file (filename)
  "Register FILENAME as a file containing ectags."
  (ectags-register-tag-fcache (fcache-of filename))
  (if ectags-tag-files
      (add-to-list 'ectags-tag-files filename t)
    ;;(nconc ectags-tag-files (list filename)) ;append hit
    (setq ectags-tag-files (list filename)))
  )

(defadvice rename-file (around sync-ectags-rename-file (file newname &optional ok-if-already-exists) activate)
    "Update ectags for renaming of FILE to NEWNAME."
    (ectags-unregister-tag-file file)
    ad-do-it
    (ectags-register-tag-file newname))
(defadvice delete-file (before sync-ectags-delete-file (filename &optional trash) activate)
    "Update ectags for deletion of FILENAME."
    (ectags-unregister-tag-file filename))

;; TODO Does put-text-property() after we have concatted everything improve performance?
;; TODO Highlight words before "::" in font-lock-type-face. Search for "\w::"

;; TODO Add `:type' attribute to variables by scanning `tag-addr' from tag_name to beginning, filtering out variable qualifier keywords such as `static'.
;; TODO Enables: g_oreg->set_tag will then complete to pReg::set_tag() and not also to Ob::set_tag()
;; TODO BUG: find-ectag at `g_pob_undefined___' gives error:
;;       `find-ectag': Wrong type argument: integer-or-marker-p, nil
(defun ectags-scan-tags (root &optional file-format tags-obarray tag-patt file-patt type-name multi-flag)
  "Scan for Exuberant Ctags in Current Buffer for the tag
pattern (regexp) TAG-PATT and put the hits in the obarray
OBA. NMATCH can be either 'exact, 'prefix, 'suffix, 'partial."
  (goto-char (point-min))
  ;;(setq *ectags-marks* nil)
  (let ((lpatt (case file-format
                 ('ectags-format-x
                  ectags-format-x-matcher)
                 ('ectags-format-vi-full-file
                  (forward-line 6)                      ;skip ectags header
                  ectags-format-vi-full-matcher)
                 ('ectags-format-vi-full-raw
                  ectags-format-vi-full-matcher)
                 (t
                  ectags-format-vi-full-matcher)
                 ))
        ;;              (alist nil)               ;alist to store tags
        (dup 0)                         ;tag name duplication counter
        current-file                    ;current source file that is being scanned for tags
        )
    (while (re-search-forward lpatt nil t)
      (let* ((tag-name (buffer-match-no-properties 1))
             (tag-file (buffer-match-no-properties 2))
             ;;(tag-addr (buffer-match-no-properties 3)) ;address as literal string
             (tag-anum (buffer-match-no-properties 3)) ;address as number
             (tag-kind (buffer-match-no-properties 4))
             ;;(tag-line (buffer-match-no-properties 5))

             ;; In Class Definitions:
             (tag-namespace (buffer-match-no-properties 6))
             ;;(tag-file2 (buffer-match-no-properties 7))
             (tag-inherits (buffer-match-no-properties 7))

             ;; In Member Function/Variable/Type Definitions:
             (tag-structure (buffer-match-no-properties 8)) ;Note: either "typeref:struct:", "typeref:enum:", "enum:", "struct:", "class:tracer::ABox3". anonymous tag-structures match the regexp "__anon\\([:digit:]+\\)"
             (tag-access (buffer-match-no-properties 9))
             (tag-implementation (buffer-match-no-properties 10))
             (tag-signature (buffer-match-no-properties 11))

             (ectag-kind-char (if tag-kind (string-to-char tag-kind))) ;kind character
             (tag-kind-char (if (eq ectag-kind-char ?f)
                                (cond ((eq (string-to-char tag-name) ?~) ;name starts with tilde ~
                                       ?D) ;destructor
                                      ((and tag-structure
                                            (string-match (concat "\\_<" (regexp-quote tag-name) "\\'") tag-structure))
                                       ?C) ;constructor
                                      (t
                                       ectag-kind-char) ;default
                                      )
                              ectag-kind-char))
             (tag-kind (string tag-kind-char)) ;update tag-kind (string)

             (tag-face (ectags-kind-face tag-kind-char)) ;face

             (tag-key tag-name))  ;hash-table lookup key (string)

        ;; highlight tag-name using type font
        (when tag-face (put-text-property 0 (length tag-name) 'face tag-face tag-name))

        (when (and tag-structure
                   (not (string-match "^__anon[[:digit:]]+\\'" tag-structure))) ;skip anonymous
          (put-text-property 0 (length tag-structure) 'face 'font-lock-structure-face tag-structure)
          (setq tag-key (concat tag-structure "::" tag-name)) ;prepend structure
          )

        (when tag-namespace
          (put-text-property 0 (length tag-namespace) 'face 'font-lock-constant-face tag-namespace)
          (setq tag-key (concat tag-namespace "::" tag-name))) ;prepend namespace

        (when tag-signature
          (setq tag-key (concat tag-key tag-signature))) ;append signature

        ;; TODO Uniquify using signature
        ;; Note: duplicates handling: uniquify overloadabled function names using signature
        (when (zerop dup)     ;if not just another duplicate
          (forward-line)      ;need to go to beginning of next line
          (setq dup (ectags-scan-find-dup-cnt (regexp-quote tag-key)))
          )
        (when (> dup 0) ;if this is duplicate
          (setq dup (1- dup)) ;decrease duplication counter
          ;; colorize tag-file
          (put-text-property 0 (length tag-file) 'face 'font-lock-file-name-face tag-file)
          (setq tag-key (concat tag-key
                                ectags-file-display-prefix
                                tag-file)) ;append tag-file
          )

        ;; fontify tag-kind char string
        ;; TODO Use: (string (+ ?Ⓐ (- ?b ?a)))
        (when tag-kind (put-text-property 0 1 'face '(:inherit shadow :box -1) tag-kind))

        (if (and (or (null tag-patt) (string-match tag-patt tag-key))
                 (or (null file-patt) (string-match file-patt tag-file))
                 (or (null type-name) (string-match type-name tag-kind)))
            (let* ((comb-name (concat tag-key
                                      (if tag-kind
                                          (concat ectags-kind-display-prefix
                                                  tag-kind
                                                  )))))
              (let ((comb-sym (intern comb-name (or tags-obarray
                                                    *ectags*))))
                (when tag-key (put comb-sym :path tag-key))
                (when tag-name (put comb-sym :name tag-name))
                (when tag-file (put comb-sym :file tag-file))
                ;;(when tag-line (put comb-sym :line tag-line))
                ;;(when tag-addr (put comb-sym :addr tag-addr))
                (when tag-anum (put comb-sym :anum tag-anum))
                (when tag-namespace (put comb-sym :namespace tag-namespace))
                (when tag-inherits (put comb-sym :inherits tag-inherits))
                (when tag-structure (put comb-sym :structure tag-structure))
                (when tag-access (put comb-sym :access tag-access))
                (when tag-implementation (put comb-sym :implementation tag-implementation))
                (when tag-signature (put comb-sym :signature tag-signature))
                (when tag-kind-char (put comb-sym :kind tag-kind-char))
                ;;(put comb-sym :doc "Doc String")
                )

              (when (eq tag-kind-char ?F)
                (let ((tag-file-path (expand-file-name (unpropertize tag-file) root)))
                  (if (file-regular-p tag-file-path)
                      (progn
                        (setq current-file tag-file-path)
                        (ectags-register-tag-file tag-file-path))
                    (warn "Tag file %s is does not exist!" tag-file-path))))
              ;;(setq alist (cons comb-name alist)) ;put comb-name first in alist
              ))))
    ;;(setq *ectags-alist* (nreverse alist)) ;reverse alist
    (if (not (eobp))
        (error "Failed to parse at position %d" (point)))))
;; Use: (progn (ectags-make-obarray) (ectags-scan-tags-file "ectags-sample.tags" 'ectags-format-vi-full-file *ectags*) (completing-read "Tag: " *ectags*))

(defun ectags-scan-tags-file (file &optional file-format tags-obarray tag-patt file-patt type-name multi-flag)
  "Scan the Exuberant Ctags FILE (defaulty named \"tags\") for
the tag pattern (regexp) TAG-PATT and put the hits in the obarray
OBA. NMATCH can be either 'exact, 'prefix, 'suffix, 'partial."
  (with-temp-buffer
    (insert-file-contents-literally file)
    (ectags-scan-tags (file-name-directory file) file-format tags-obarray tag-patt file-patt type-name multi-flag)))

(eval-when-compile
  (defun ectags-executable ()
    "Return ectags executable program."
    (or (executable-find "ectags")
        (executable-find "ctags-exuberant"))))

(defun ectags-scan-directory (directory &optional file-format tags-obarray tag-patt file-patt type-name multi-flag)
  "Scan Exuberant Ctags recursively in DIRECTORY."
  (let ((args (append ectags-command-args
                      '("--recurse=yes")           ;recursive
                      '("-f-")          ;direct standard to buffer
                      ))
        (buffer (get-buffer-create ectags-temp-buffer-name)))
    (with-current-buffer buffer
      (setq buffer-read-only nil)
      (erase-buffer))
    (let ((default-directory directory))
      (eval `(call-process ,(ectags-executable) nil ,buffer nil ,@args))
      (with-current-buffer buffer
        (setq buffer-read-only t))))
  (with-current-buffer ectags-temp-buffer-name
    (ectags-scan-tags directory file-format tags-obarray tag-patt file-patt type-name multi-flag)))
;; (eval-when-compile (ectags-scan-directory "~/justcxx/semnet/" 'ectags-format-vi-full-raw))
;; (ectags-scan-directory "~/justcxx/" 'ectags-format-vi-full-raw)

;; (eval-when-compile
;;   (let ((tags-obarray (make-obarray 1000)))
;;     (ectags-scan-directory "/usr/include/c++/4.7/vector" 'ectags-format-vi-full-raw tags-obarray)))

;; TODO colorize scope as type
(when (string-match (concat "\\(?:\\([[:alnum:]_]+\\)::\\)"
                            "\\(?:\\([[:alnum:]_]+\\)::\\)?"
                            "\\(?:\\([[:alnum:]_]+\\)::\\)?"
                            "\\(?:\\([[:alnum:]_]+\\)::\\)?"
                            "\\(?:\\([[:alnum:]_]+\\)::\\)?"
                            "\\(?:\\([[:alnum:]_]+\\)::\\)?")
                    "world::semnet::Ob::")
  (let ((hits (cddr (match-data))))
    (while hits
      (setq hits (cddr hits))))
  (list
   (match-data t)
   (list (match-beginning 0)
         (match-end 0))
   (cddr (match-data t))))

(defun ectags-make-obarray ()
  "Init ECtags obarray using structure of current ECtags buffer."
  (setq *ectags* (make-obarray (count-lines (point-min) (point-max)))))

(defun visit-ectags-table (file)
  "Load tags from Exuberant Ctags (Vi-Style) FILE."
  (interactive "fFile: ")
  (setq file (expand-file-name file))   ;canonicalize format
  (when (file-directory-p file)         ;if directory given
    (setq file (expand-file-name "tags" file))) ;expand to Exuberant Ctags standard name DIR/"tags"
  (let* ((attrs (file-attributes file))
         (mtime (nth 5 attrs))
         (fsize (nth 7 attrs)))
    (unless (and
             (equal ectags-file-name file) ;file-name match
             (equal ectags-file-id (list mtime fsize)) ;and not changed
             )
      (if (or (not (fboundp 'file-ectags-p))
              (file-ectags-p file))
          (progn
            (message "Scanning Exuberant CTags (Ectags) Table...")
            (ectags-make-obarray)
            (setq ectags-tag-files nil)
            (setq ectags-tag-fcaches nil)
            (setq ectags-file-name file)
            (setq ectags-file-id (list mtime fsize))
            (ectags-scan-tags-file file 'ectags-format-vi-full-file *ectags*)
            (message "Done"))
        (message "File %s is not an Exuberant Ctags table!" (faze file 'file))
        ))))
;; Use: (visit-ectags-table "ectags-sample.tags")

(defun ectags-tags-file-directory (&optional file)
  "Find root (tags or project) directory of FILE."
  (let* ((dir (progn
                (unless file (setq file buffer-file-name))
                (unless file (setq file default-directory))
                (unless (file-directory-p file) (setq file (file-name-directory file)))
                file))
         (tags-root (car (trace-directory-upwards
                          'file-ectags-root-directory-p
                          dir))))
    (or tags-root                        ;either we found root
        (read-directory-name "Directory to generate tags from: " dir nil t)))) ;or we default to current
;; Use: (ectags-tags-file-directory)
;; Use: (ectags-tags-file-directory "~/justcxx/")
;; Use: (ectags-tags-file-directory "~/justcxx/semnet/")
;; Use: (ectags-tags-file-directory "~/pnw/")
;; Use: (ectags-tags-file-directory (elsub "others"))
;; Use: (ectags-tags-file-directory "/etc")
;; Use: (ectags-tags-file-directory "~/ware/emacs/src")

(defun ectags-lazy-completion-table (&optional dir-flag)
  "Create an ECtags Completion Table from current file-system
context."
  (interactive)
  (run-hooks 'ectags-lazy-hook)
  (let ((root (car (trace-directory-upwards 'file-tags-root-directory-p)))) ;try to find tags root
    (when root
      (if dir-flag
          (ectags-scan-directory root 'ectags-format-vi-full-raw *ectags*)
        (unless (file-regular-p (expand-file-name "tags" root)) ;if no tags yet
          (atags-update root 'Exuberant-Ctags nil t)                     ;create it. TODO sync-flag doesn't work when I delete (elsub "mine/tags").
          )
        (visit-ectags-table root))
      *ectags*)))
;; Use: (ectags-lazy-completion-table)
;; Use: (bench (ectags-lazy-completion-table))

;; ---------------------------------------------------------------------------

(defsubst ectag-get (tag-key propname &optional default)
  "TAG-KEY can be either a symbol or a string. PROPNAME is the
property to read defaulting its value to DEFAULT."
  (let ((prop (get (intern-soft tag-key *ectags*) propname)))
    (or prop default)))
;;Use: (ectag-get "Ob'c" :name "None")
;;Use: (ectag-get "Ob'c" :file)
;;Use: (ectag-get "Ob'c" :kind)
;;Use: (ectag-get 'Ob :kind)

(defun ectag-get-doc-string (tag-key propname &optional face default)
  (let ((prop (get (intern-soft tag-key *ectags*) propname)))
    (when prop
      (format "%s: %s, "
              (propertize (capitalize (substring (symbol-name propname) 1)) 'face 'bold)
              (if face (propertize prop 'face face) prop)))))
;;Use: (ectag-get-doc-string "Ob'c" :name 'font-lock-file-name-face)

(defun ectag-get-kind-face (tag-key)
  (ectags-kind-face (get (intern-soft tag-key *ectags*) :kind)))
;;Use: (ectag-get-kind-face "Ob'c")

(defsubst ectag-signature (tag-key) (ectag-get tag-key :signature))

;; ---------------------------------------------------------------------------

;; ECTags Sorting Functions using Icicles
(when (ignore-errors (and (require 'icicles nil t)
			  (require 'icicles-mac nil t)))
  (defcustom ectags-sort-commands nil
    "List of functions (symbols) used by Icicles to sort Completion
    Candidates.")

  (defun ectags-path-less-p (s1 s2)
    "Compare S1 and S2 by `:path' property."
    (string-lessp (ectag-get s1 :path) (ectag-get s2 :path)))
  (add-to-list 'ectags-sort-commands
               (icicle-define-sort-command "by ectag path" ectags-path-less-p "Sort completion candidates by path."))

  (defun ectags-name-less-p (s1 s2)
    "Compare S1 and S2 by `:name' property."
    (string-lessp (ectag-get s1 :name) (ectag-get s2 :name)))
  (add-to-list 'ectags-sort-commands
               (icicle-define-sort-command "by ectag name" ectags-name-less-p "Sort completion candidates by name."))

  (defun ectags-file-less-p (s1 s2)
    "Compare S1 and S2 by definition `:file' property."
    (string-lessp (ectag-get s1 :file) (ectag-get s2 :file)))
  (add-to-list 'ectags-sort-commands
               (icicle-define-sort-command "by ectag file" ectags-file-less-p "Sort completion candidates by  definition file."))

  (defun ectags-kind-less-p (s1 s2)
    "Compare S1 and S2 by `:kind' property."
    (string-lessp (ectag-get s1 :kind) (ectag-get s2 :kind)))
  (add-to-list 'ectags-sort-commands
               (icicle-define-sort-command "by ectag kind" ectags-kind-less-p "Sort completion candidates by kind."))

  (defun ectags-namespace-less-p (s1 s2)
    "Compare S1 and S2 by `:namespace' property."
    (string-lessp (ectag-get s1 :namespace) (ectag-get s2 :namespace)))
  (add-to-list 'ectags-sort-commands
               (icicle-define-sort-command "by ectag namespace" ectags-namespace-less-p "Sort completion candidates by namespace."))

  (defun ectags-inherits-less-p (s1 s2)
    "Compare S1 and S2 by `:inherits' property."
    (string-lessp (ectag-get s1 :inherits) (ectag-get s2 :inherits)))
  (add-to-list 'ectags-sort-commands
               (icicle-define-sort-command "by ectag inherits" ectags-inherits-less-p "Sort completion candidates by inherits."))

  (defun ectags-structure-less-p (s1 s2)
    "Compare S1 and S2 by `:structure' property."
    (string-lessp (ectag-get s1 :structure) (ectag-get s2 :structure)))
  (add-to-list 'ectags-sort-commands
               (icicle-define-sort-command "by ectag structure" ectags-structure-less-p "Sort completion candidates by structures."))

  (defun ectags-access-less-p (s1 s2)
    "Compare S1 and S2 by `:access' property."
    (string-lessp (ectag-get s1 :access) (ectag-get s2 :access)))
  (add-to-list 'ectags-sort-commands
               (icicle-define-sort-command "by ectag access" ectags-access-less-p "Sort completion candidates by access."))

  (defun ectags-implementation-less-p (s1 s2)
    "Compare S1 and S2 by `:implementation' property."
    (string-lessp (ectag-get s1 :implementation) (ectag-get s2 :implementation)))
  (add-to-list 'ectags-sort-commands
               (icicle-define-sort-command "by ectag implementation" ectags-implementation-less-p "Sort completion candidates by implementations."))

  (defun ectags-signature-less-p (s1 s2)
    "Compare S1 and S2 by `:signature' property."
    (string-lessp (ectag-get s1 :signature) (ectag-get s2 :signature)))
  (add-to-list 'ectags-sort-commands
               (icicle-define-sort-command "by ectag signature" ectags-signature-less-p "Sort completion candidates by signatures."))
  )

;; TODO Use: http://www.emacswiki.org/emacs/Icicles_-_Customization_and_General_Tips#toc55 to dynamically create Completion Candidate Name

;; ---------------------------------------------------------------------------

(defun ectags-lookup-tag-symbol (tagname &optional kinds)
  "Try to lookup (using `intern-soft') a symbol in the hash-table
`*ectags*' that match TAGNAME by succesively appending all type
suffix KINDS.  See `ectags-kinds' for details."
  (catch 'hit
    (dolist (kind (or kinds (ectags-syntax-context-kind-atpt)))
      (let ((tag-key (concat tagname (string ?' kind))))
        (let ((sym (intern-soft tag-key *ectags*)))
          (when sym                     ;if we found a symbol
            (throw 'hit sym))           ;throw it
          )))))
;; Use: (ectags-lookup-tag-symbol "pbuild_emacs" ectags-kinds-chars)
;; Use: (ectags-lookup-tag-symbol "Ob" ectags-kinds-chars)
;; Use: (ectags-lookup-tag-symbol "Ob" ectags-kinds-chars)
;; Use: (ectags-lookup-tag-symbol "Ob" '(?c))
;; Use: (symbol-plist (ectags-lookup-tag-symbol "Ob" '(?c)))
;; Use: (ectags-lookup-tag-symbol "Ob" '(?f))
;; Use: (ectags-lookup-tag-symbol "Ob::Ob" '(?f))
;; Use: (ectags-lookup-tag-symbol "nthD" '(?f))
;; Use: (symbol-plist (ectags-lookup-tag-symbol "Unit" '(?c)))

(defun symbol-scope-at-point ()
  "Return scope of symbol at point.
In C++ this means namespace qualifier. "
  (save-excursion
    (beginning-of-symbol-next-to-point)
    (when (looking-back (concat "\\(" ID "\\)" _* "::" _*))
      (match-string 1))))
;; Use: (symbol-scope-at-point)

(defun ectags-default-tags-at-point (&optional thing propname)
  "Determine default tag(s) as a string or list of tags (strings)
 to search for, based on text at point. If there is no plausible
 default, return nil. THING defaults to symbol."
  (ectags-lazy-completion-table)
  (let ((tag (and (or (not (cc-derived-mode-p))
                      (c-on-identifier))
                  (cond ((or (null thing)
                             (eq thing 'symbol))
                         (or (symbol-at-point)
                             (symbol-bfpt)))
                        (t
                         (thing-at-point (or thing 'symbol))))))) ;Note: I used (find-tag-default)
    (when tag
      (let* ((tag (if (symbolp tag) (symbol-name tag) tag)) ;assure string
             (sym (ectags-lookup-tag-symbol tag)) ;first try exact match
             (sym-name (symbol-name sym))) ;we want to return the string instead of the symbol
        (or
         (and sym sym-name)             ;exact match as string first
         (when (>= (length tag) 2) ;only match symbol at point that have 2 or more letters to not make matches to many
           (let ((scope (symbol-scope-at-point)))
             (or (obarray-multi-match-string tag
                                             propname
                                             'exact
                                             (ectags-syntax-context-kind-atpt)
                                             scope *ectags*) ;try exact first
                 (when nil ;NOTE: Disabled for now because too slow for large projects.
                   (obarray-multi-match-string tag
                                               propname
                                               'partial
                                               (ectags-syntax-context-kind-atpt)
                                               scope
                                               *ectags*)))))))))) ;try partial second
;; Use: (ectags-default-tags-at-point)

;; ---------------------------------------------------------------------------

(defun ectags-goto-tag (tagname &optional not-this-window)
  "Find definition of TAGNAME.
TAGNAME can be either symbol or a string.  If NOT-THIS-WINDOW is
non-nil find it in other window."
  (let* ((sym (if (symbolp tagname)
                  tagname
                (intern-soft tagname *ectags*)))
         (tag-file (get sym :file))
         (tag-fpath (expand-file-name tag-file (file-name-directory ectags-file-name))) ;tag-file relative to tags table
         ;;(tag-line (get sym :line))
         (tag-anum (get sym :anum))
         (tag-name (get sym :name))
         (tag-name-re (concat "\\_<" "\\(" (regexp-quote tag-name) "\\)" "\\_>"))
         ;;(tag-addr (get sym :addr))
         (tag-anum (get sym :anum))
         (tag-kind (get sym :kind))
         )
    (if (and tag-fpath
             (file-regular-p tag-fpath)
             (file-readable-p tag-fpath))
        (progn
          (if not-this-window (find-file-other-window tag-fpath) (find-file tag-fpath))
          (when tag-anum
            (goto-char (point-min))
            (forward-line (1- (string-to-number tag-anum)))
            (beginning-of-line))
          (when (and tag-name
                     (case tag-kind
                       (?v (re-search-forward (concat tag-name-re) nil t))  ;variable: NAME
                       (?m (re-search-forward (concat tag-name-re) nil t))  ;member: NAME
                       (?f (re-search-forward (concat tag-name-re L* "(") nil t))  ;function: NAME L* "("
                       (?c (re-search-forward (concat tag-name-re L* "{") nil t))  ;class: NAME L* "{"
                       (?d (re-search-forward (concat tag-name-re) nil t))         ;macro: NAME
                       (?C (re-search-forward (concat tag-name-re L* "(") nil t))  ;ctor: NAME L* "("
                       (?D (re-search-forward (concat tag-name-re L* "(") nil t))  ;dtor: NAME L* "("
                       (?t (re-search-forward (concat tag-name-re L* ";") nil t))  ;typedef: NAME L* ";"
                       (?e (re-search-forward (concat tag-name-re) nil t))         ;enumerator: NAME
                       ((?g ?s ?u) (re-search-forward (concat tag-name-re) nil t)) ;enumeration: NAME
                       (t
                        ;;(and tag-addr (re-search-forward tag-addr nil t))
                        )
                       ))
            (goto-char (match-beginning 1))
            ))
      (message "Warning: Couldn't find tag-file %s containing tag %s!"
               (faze tag-file 'file)
               (symbol-name sym)))))

;; ---------------------------------------------------------------------------

(defun icicle-find-ectag-action (cand)
  "Act on ectags candidate CAND.
Action function for `find-ectag'.
Inspired by `icicle-find-tag-action'."
  (let ((file (expand-file-name (ectag-get cand :file)
                                (file-name-directory ectags-file-name))))
    (if (file-regular-p file)
        (progn
          (ectags-goto-tag cand t)
          (widen)
          ;; inherits behaviour of `previous-error' and `next-error'
          (hictx-line nil 'next-error (if (numberp next-error-highlight)
                                                        next-error-highlight
                                                      0.5))
          (when nil                     ;disabled because too hard to spot
            (hictx-symbol-after-point nil 'next-error (if (numberp next-error-highlight)
                                                          next-error-highlight
                                                        0.5)))
          (select-window (minibuffer-window))
          (select-frame-set-input-focus (selected-frame)))
      (message "Warning: File %s not present." (faze file 'file)))))

(defun icicle-find-ectag-help (cand)
  "Get help (documentation) for ectags candidate CAND.
Use as `icicle-candidate-help-fn' for `find-ectag'."
  (message (concat (ectag-get-doc-string cand :file 'font-lock-file-name-face)
                   (ectag-get-doc-string cand :line 'font-lock-number-face)
                   (ectag-get-doc-string cand :namespace 'font-lock-type-face)
                   (ectag-get-doc-string cand :structure 'font-lock-class-face)
                   (ectag-get-doc-string cand :name) ;use face already propertized
                   (ectag-get-doc-string cand :inherits 'font-lock-class-face)
                   (ectag-get-doc-string cand :access 'font-lock-keyword-face)
                   (ectag-get-doc-string cand :implementation 'font-lock-keyword-face)
                   (ectag-get-doc-string cand :signature)
                   (format "%s: %s"
                           (faze "Kind" 'bold)
                           (let ((kind (cadr (assoc (ectag-get cand :kind) ectags-kinds))))
                             (or kind
                                 "Unknown")))
                   ))
  (sit-for 4))

(defun ectags-select-tag (tagpatt &optional propname)
  "Scan for tags that match the regexp TAGPATT and perform a
  completing read (selection) of them if any."
  ;;(message "Scanning tags that match the regexp %s..." tagpatt)
  (let ((tagnames (obarray-match-regexp tagpatt propname)))
    (cond ((= (length tagnames) 1)
           (first tagnames))
          (tagnames
           (let* (icicle-transform-function
                  (icicle-candidate-action-fn 'icicle-find-ectag-action)
                  (icicle-candidate-help-fn 'icicle-find-tag-help)
                  ;;(icicle-sort-functions-alist ectags-sort-commands)
                  )
             (completing-read "Choose tag: " tagnames nil t))))))
;; Use: (ectags-select-tag "b" :name)
;; Use: (ectags-select-tag "buf" :name)
;; Use: (ectags-select-tag "^Ob$" :name)

(defun ectags-transform-function (candidates)
  (mapcar (lambda (tag-key) (ectag-get tag-key :name))
          candidates))

(defvar ectags-default-display-max 5
  "Maximum number of default tags to display in minibuffer.")

(defvar find-ectag-history find-tag-history
  "History of ectag lookups.")
(add-to-list 'desktop-globals-to-save 'find-tag-history t)
(add-to-list 'desktop-globals-to-save 'find-ectag-history t)

;;; TODO Support kind `argument' having values `variable' and `function', `type', `class'
(defun read-ectag-key (&optional prompt require-match kind default)
  "Read an `*ectags*' tag key string."
  (let* ( ;;(icicle-transform-function 'ectags-transform-function)
         (icicle-candidate-action-fn 'icicle-find-ectag-action)
         (icicle-candidate-help-fn 'icicle-find-ectag-help)
         ;;(icicle-sort-functions-alist ectags-sort-commands)
         (defs (when nil                ;NOTE: Disabled for now because too slow for large projects
                 (ectags-default-tags-at-point 'symbol :name)) ;partial tag name matches. TODO Use lazy.
           )
         (defs-num (cond ((stringp defs) 1)
                         ((listp defs) (length defs))))
         (def1 (cond ((stringp defs) defs)

                     ((listp defs) (when (= 1 defs-num) (first defs)))))
         (prompt (or prompt "Find tag"))
         (table (ectags-lazy-completion-table))
         (tag-key
          (if table
              (let* ((def-val (if (or def1 defs)
                                  (concat " (default"
                                          (when (> defs-num 1) "s")
                                          " "
                                          (or def1
                                              (let ((num ectags-default-display-max))
                                                (concat (mapconcat 'identity (sublist defs 0 num) ", ")
                                                        (when (> defs-num num) ", ..."))))
                                          ")")
                                ""))
                     (icicle-default-in-prompt-format-function (lambda (ignored) def-val)))
                (completing-read (format (concat prompt "%s: ")
                                         def-val)
                                 table nil
                                 nil ;Note: Don't require match so we can def1 to partial or fuzzy match.
                                 nil 'find-ectag-history
                                 def1))
            (read-string (concat prompt ": "))
            ;;(message "No tags table found") nil
            ))
         (tag-key (if (or (not tag-key)
                          (string= tag-key ""))
                      (if def1 def1
                        (when defs
                          (completing-read (format (concat prompt " (matching %s): ") (symbol-at-point))
                                           defs nil require-match)))
                    tag-key)))
    tag-key))

;; (read-ectag-key)

(defun read-ectag-symbol (&optional prompt require-match)
  "Read an `*ectags*' tag symbol."
  (intern-soft (read-ectag-key prompt require-match) *ectags*))
;; Use: (read-ectag-symbol)

(defun read-ectag-name-or-key (&optional prompt require-match kind)
  "Read an `*ectags*' tag symbol name or key string."
  (let* ((key (read-ectag-key prompt require-match kind))
         (sym (intern-soft key *ectags*)))
    (if sym
        (plist-get (symbol-plist sym) :name)
      key)))
;; (read-ectag-name-or-key)

(defun find-ectag-interactive (&optional prompt require-match)
  "Get interactive arguments for tag functions.
The functions using this are `find-ectag'."
  (list (read-ectag-key prompt require-match)))

;;;###autoload
(defun find-ectag (tagname &optional propname next-p regexp-p)
  "Find and goto definition of TAGNAME. If PROPNAME is non-nil
move there; currently supports `:name', `:namespace',
`:structure', `:file' or `:signature'."
  (interactive (find-ectag-interactive))
  ;; Save the current buffer's value of `ectags-before-find-tag-hook'
  ;; before selecting the tags table buffer.  For the same reason,
  ;; save value of `ectags-file-name' in case it has a buffer-local
  ;; value.
  (if tagname
      (progn (let ((local-find-tag-hook ectags-before-find-tag-hook))
               (run-hooks 'local-find-tag-hook)
               )
             (let ((sym (intern-soft tagname *ectags*)))
               (unless sym                    ;if user entered incomplete tag-key
                 (setq sym (ectags-lookup-tag-symbol tagname ectags-kinds-chars))) ;try to using know suffixes
               (unless sym                    ;if still no match
                 (let ((newname (ectags-select-tag (concat "^" tagname "$") :name)))
                   (when newname
                     (setq tagname newname))
                   (setq sym (intern-soft tagname *ectags*)) ;lookup again
                   ))
               (if sym
                   (progn
                     (add-to-history 'find-ectag-history tagname)
                     (ring-insert find-tag-marker-ring (point-marker))
                     (ectags-goto-tag sym)
                     )
                 (message "Tag %s not found" (faze tagname 'const))
                 nil                          ;signal miss
                 )))
    (message "Tag not found")))
;; Use: (find-ectag "Ob")
;; Use: (find-ectag "Ob'c")
;; Use: (call-interactively 'find-ectag)

;;;###autoload
(defun find-ectag-regexp (tagname-regexp &optional propname next-p regexp-p)
  "Find and goto definition of TAGNAME-REGEXP. If PROPNAME is non-nil
move there; currently supports `:name', `:namespace',
`:structure', `:file' or `:signature'."
  (find-ectag tagname-regexp propname next-p t))

;; ---------------- query-replace integration ----------------

(defun ectags-query-replace-read-args (&optional prompt regexp-flag noerror)
  (let* (
         ;;(default-from (if (region-active-p)))
         ;;(query-replace-read-args prompt regexp-flag noerror)

         (thing (multi-read-thing (or prompt
                                      (format "Tags query replace %s%s"
                                              (if regexp-flag "regexp" "string")
                                              ""
                                              ;; (if sym-str-atpt (format " (default %s) "
                                              ;;                      sym-str-atpt)
                                              ;;   "")
                                              ))
                                  (if regexp-flag 'regexp 'symbol-string-at-point)
                                  t
                                  nil
                                  nil ;;TODO Make M-return work in `multi-read-thing' with `read-ectag-name-or-key' as `read-fn' argument.
                                  ))

         (from-to (strip-common-prefix-suffix-from-string-list thing 'ask))
         (from-rx (car from-to))
         (to-str (cadr from-to)))
    (list (eval from-rx)
          to-str)))
;; Use: (ectags-query-replace-read-args)filter

;;;###autoload
(defun ectags-query-replace-string (from to &optional delimited)
  "Ectags string version of `tags-query-replace'."
  (interactive (ectags-query-replace-read-args nil nil t))
  (tags-query-replace from to delimited `(mapcar (lambda (fcache)
                                                   (fcache-full-fname fcache))
                                                 ectags-tag-fcaches)))

;;;###autoload
(defun ectags-query-replace-regexp (from to &optional delimited)
  "Ectags regexp version of `tags-query-replace'."
  (interactive (ectags-query-replace-read-args nil t t))
  (tags-query-replace from to delimited `(mapcar (lambda (fcache)
                                                   (fcache-full-fname fcache))
                                                 ectags-tag-fcaches)))

;; ---------------- c-eldoc integration ----------------

;;;###autoload
(defun c-eldoc-scope ()
  "Try to figure out our scope."
  (save-excursion
    (c-end-of-defun)
    (c-beginning-of-defun-1)
    (forward-line -1)
    (c-syntactic-re-search-forward "::")
    (backward-char 2)
    (when (c-on-identifier)
      (let* ((id-end (point))
             (id-start (progn (backward-char 1) (c-beginning-of-current-token) (point))))
        (buffer-substring-no-properties id-start id-end)))))

;;;###autoload
(defun c-eldoc-function (&optional limit)
  "Finds the current function and position in argument list."
  (let* ((literal-limits (c-literal-limits))
         (literal-type (c-literal-type literal-limits)))
    (save-excursion
      ;; if this is a string, move out to function domain
      (when (eq literal-type 'string)
        (goto-char (car literal-limits))
        (setq literal-type nil))
      (if literal-type
          nil
        (when (c-on-identifier)
          (let* ((id-on (point-marker))
                 (id-start
                  (progn (c-beginning-of-current-token)
                         ;; are we looking at a double colon?
                         (if (and (= (char-before)  ?:)
                                  (= (char-before (1- (point))) ?:))
                             (progn
                               (backward-char 3)
                               (c-beginning-of-current-token)
                               (point-marker))
                           (point-marker))))
                 (id-end
                  (progn
                    (goto-char id-on)
                    (forward-char)
                    (c-end-of-current-token)
                    (point-marker))))
            (buffer-substring-no-properties id-start id-end)))))))

(defun ectags-eldoc-print-current-symbol-info ()
  "Print the ectags info associated with the current eldoc
symbol, without scope (in more conservative languages)."
  (let* ((eldoc-sym (c-eldoc-function (- (point) 1000))))
    (let ((hits (obarray-match-regexp eldoc-sym)))
      (if (> (length hits) 0)
          (ectag-signature (car hits))  ;TODO Check this!
        (format "Unknown %s " eldoc-sym)))))

;; TODO Activate eldoc support.
(when nil
  (defun ectags-eldoc-print-current-scoped-symbol-info ()
    "Try to find the meaning of the symbol in the current scope. Probably only useful for cpp mode"
    (message "OK")
    (let* ((eldoc-scope (c-eldoc-scope))
           (eldoc-sym (c-eldoc-function (- (point) 1000))))
      (when eldoc-sym
        (let ((hits (obarray-match-regexp (format "%s::%s" eldoc-scope eldoc-sym))))
          (if (> (length hits) 0)
              (format "%s::%s %s" eldoc-scope eldoc-sym (ectag-signature (car hits))) ;TODO Check this!
            (progn
              (setq hits (obarray-match-regexp eldoc-sym)) ;try without scope
              (if (> (length hits) 0)
                  (format "%s %s" eldoc-sym (ectag-signature (car hits))) ;TODO Check hits
                (when eldoc-scope
                  (format "Scope %s " eldoc-scope))
                (format "Unknown %s " eldoc-sym))))))))

  (defun ectags-turn-on-eldoc-mode (&optional scope-format)
    (interactive)
    (cond
     ((eq major-mode 'c-mode)
      (set (make-local-variable 'eldoc-documentation-function) 'ectags-eldoc-print-current-symbol-info))
     ((memq major-mode '(c++-mode objc-mode java-mode csharp-mode))
      (set (make-local-variable 'eldoc-documentation-function) 'ectags-eldoc-print-current-scoped-symbol-info))
     (ta
      (set (make-local-variable 'eldoc-documentation-function) 'ectags-eldoc-print-current-symbol-info))
     )
    (turn-on-eldoc-mode))

  (add-hook 'c-mode-common-hook 'ectags-turn-on-eldoc-mode t)
  )

(defun ectags-default-global-keybindings ()
  "Set up global keybindings for `ectags'."
  (global-set-key [(meta ?.)] 'find-ectag)
  (global-set-key [(control ?:)] 'find-ectag-regexp)
  (global-set-key [(control c) (control shift meta ?§)] 'visit-ectags-table) ;least often
  (global-set-key [(control c) (?§)] 'ectags-query-replace-string)
  (global-set-key [(control c) (meta ?§)] 'ectags-query-replace-regexp)
  (global-set-key [(control c) (?½)] 'tags-loop-continue)
  ;; (global-set-key [(control c) (meta ?§)] 'visit-tags-table) ;least often
  ;; (global-set-key [(control c) (?½)] 'tags-query-replace) ;Less often
  ;; (global-set-key [(control c) (?§)] 'tags-loop-continue) ;most often
  )
(ectags-default-global-keybindings)

;; Use:
(when nil
  (message "result %s" (benchmark-run-compiled 1 (ectags-scan-tags-file "ectags-sample.tags" 'ectags-format-vi-full-file *ectags* ".*" nil nil nil)))
  (progn
    (setq *sym-obarray* (make-vector 16 0))
    (setq sym (intern "sym-string" *sym-obarray*))
    (put sym 'variable-documentation "Sym Doc.")
    (put sym :file "foo.c")
    (put sym :line 12)
    ;;(symbol-plist (intern-soft "find-file"))
    (message "symbol-plist of sym: %s" (symbol-plist 'sym))
    (message "symbol-plist of intern-soft symstring: %s" (symbol-plist (intern-soft "sym-string" *sym-obarray*)))
    )
  )
