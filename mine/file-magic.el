;;; file-magic.el --- file/magic code editing commands for Emacs

;; Author: Per Nordlöw (per.nordlow@gmail.com)
;; Keywords: languages, file(1), magic/magic

;;; Code:

(require 'font-lock-extras)
(require 'power-utils)

(defgroup file-magic-mode nil
  "file-magic code editing commands for Emacs."
  :group 'tools)

(defconst file-magic-type-strings-regexps
  '("byte"				; A one-byte value.

    "short" ; A two-byte value (on most systems) in this machine’s native byte order.

    "long" ; A four-byte value (on most systems) in this machine’s native byte order.

    "quad" ; An eight-byte value (on most systems) in this machine’s native byte order.

    "string"

    "string/[Bbc]*" ; A string of bytes.  The string type specification can be
                                        ; optionally followed by /[Bbc]*.  The “B” flag compacts
                                        ; whitespace in the target, which must contain at least one
                                        ; whitespace character.  If the magic has n consecutive
                                        ; blanks, the target needs at least n consecutive blanks to
                                        ; match.  The “b” flag treats every blank in the target as an
                                        ; optional blank.  Finally the “c” flag, specifies case
                                        ; insensitive matching: lowercase characters in the magic
                                        ; match both lower and upper case characters in the target,
                                        ; whereas upper case characters in the magic, only much uppercase characters in the target.

    "pstring" ; A pascal style string where the first byte is interpreted as the an unsigned length.  The string is not NUL terminated.

    "date"	       ; A four-byte value interpreted as a UNIX date.

    "qdate"	      ; A eight-byte value interpreted as a UNIX date.

    "ldate" ; A four-byte value interpreted as a UNIX-style date, but interpreted as local time rather than UTC.

    "qldate" ; An eight-byte value interpreted as a UNIX-style date, but interpreted as local time rather than UTC.

    "beshort" ; A two-byte value (on most systems) in big-endian byte order.

    "belong" ; A four-byte value (on most systems) in big-endian byte order.

    "bequad" ; An eight-byte value (on most systems) in big-endian byte order.

    "bedouble" ; An eight-byte (double) in big-endian byte order.

    "bedate" ; A four-byte value (on most systems) in big-endian byte order, interpreted as a Unix date.

    "beqdate" ; An eight-byte value (on most systems) in big-endian byte order, interpreted as a Unix date.

    "beldate" ; A four-byte value (on most systems) in big-endian byte order, interpreted as a UNIX-style date, but interpreted as local time rather than UTC.

    "beqldate" ; An eight-byte value (on most systems) in big-endian byte order, interpreted as a UNIX-style date, but interpreted as local time rather than UTC.

    "bestring16" ; A two-byte unicode (UCS16) string in big-endian byte order.

    "leshort" ; A two-byte value (on most systems) in little-endian byte order.

    "lelong" ; A four-byte value (on most systems) in little-endian byte order.

    "lequad" ; An eight-byte value (on most systems) in little-endian byte order.

    "ledouble" ; An eight-byte (double) in little-endian byte order.

    "ledate" ; A four-byte value (on most systems) in little-endian byte order, interpreted as a UNIX date.

    "leqdate" ; An eight-byte value (on most systems) in little-endian byte order, interpreted as a UNIX date.

    "leldate" ; A four-byte value (on most systems) in little-endian byte order, interpreted as a UNIX-style date, but interpreted as local time rather than UTC.

    "leqldate" ; An eight-byte value (on most systems) in little-endian byte order, interpreted as a UNIX-style date, but interpreted as local time rather than UTC.

    "lestring16" ; A two-byte unicode (UCS16) string in little-endian byte order.

    "melong" ; A four-byte value (on most systems) in middle-endian (PDP-11) byte order.

    "medate" ; A four-byte value (on most systems) in middle-endian (PDP-11) byte order, interpreted as a UNIX date.

    "meldate" ; A four-byte value (on most systems) in middle-endian (PDP-11) byte order, interpreted as a UNIX-style date, but interpreted as local time rather than UTC.

    "regex"	; A regular expression match in extended POSIX regular

    "regex/[cse]*"	; A regular expression match in extended POSIX regular
                                        ; expression syntax (much like egrep).  The type specification
                                        ; can be optionally followed by /[cse]*.  The “c” flag makes
                                        ; the match case insensitive, while the “s” or “e” flags
                                        ; update the offset to the starting or ending offsets of the
                                        ; match (only one should be used).  By default, regex does not
                                        ; update the offset.  The regu‐ lar expression is always
                                        ; tested against the first N lines, where N is the given
                                        ; offset, thus it is only useful for (single-byte encoded)
                                        ; text.  ^ and $ will match the beginning and end of
                                        ; individual lines, respectively, not beginning and end of
                                        ; file.  search      A literal string search starting at the
                                        ; given offset.  It must be followed by <number> which
                                        ; specifies how many matches shall be attempted (the range).
                                        ; This is suitable for searching larger binary expressions
                                        ; with variable offsets, using \ escapes for special
                                        ; characters.

    "search/[0-9]+"

    "default" ; This is intended to be used with the text x (which is always true) and a message that is to be used if there are no other matches.
    )
  "Type string regexps for file magic sources."
  )

(defconst file-magic-font-lock-keywords
  (list
   (cons
    (concat "^"
            "\\([>]*\\)"				;scope

            "\\(" "&?" "\\)"        ;operator

            "\\((?\\)"                    ;opening offset paren
            "\\(" "&?" "\\)"        ;operator

            "\\(" "-?" "\\(?:0x\\)?" "[[:xdigit:]]+" "\\)"	;offset

            "\\(" "\\(?:" "\.[a-zA-Z]" "\\)?" "\\)" ;letter
            "\\(?:[+-]\\|\*\\)?"
            "\\(" "\\(?:" "\\(?:0x\\)?" "[[:xdigit:]]+" "\\)?" "\\)" ;number

            "\\()?\\)"                    ;closing offset paren

            "[ \t]+"				;whitespace (tabs)

            "\\(" "[u]?" "\\(?:" (regexp-from-alts file-magic-type-strings-regexps) "\\)" "\\)" ;type
            "\\(" "\\(?:" "&" "\\)?" "\\)" ;optional type operator
            "\\(" "\\(?:" "\\(?:0x\\)?" "[[:xdigit:]]+" "\\)?" "\\)" ;optional type operator argument

            "[ \t]+"				;whitespace (tabs)

            "\\(" "\\(?:" (regexp-from-alts '("=" "&" "!" "<" ">")) "\\)?" "\\)" ;optional constant operator

            "\\(" "\\(?:" (regexp-from-alts '("\\\\ " "[^\t\n ]")) "\\)" "+" "\\)" ;constant

            "[ \t]*"				;whitespace (tabs)

            "\\("
            "\\(" ".*" "\\)"			;comment
            "\\)"
            )
    '((1 'font-lock-operator-face)
      (2 'font-lock-operator-face)
      (3 'font-lock-parens-face)
      (4 'font-lock-operator-face)
      (5 'font-lock-number-face)
      (6 'font-lock-number-face)
      (7 'font-lock-number-face)
      (8 'font-lock-parens-face)
      (9 'font-lock-type-face)
      (10'font-lock-operator-face)
      (11 'font-lock-number-face)
      (12 'font-lock-operator-face)
      (13 'font-lock-constant-face)
      (14 'font-lock-string-face)
      ))

   ;; comment
   (cons "\\(^#.*\\)"
         '((1 font-lock-comment-face t)))

   ;; mime
   (cons (concat "^!:"              ;start
                 "\\(mime\\)"       ;keyword
                 "[ \t]+"           ;space
                 "\\(.*\\)"         ;id
                 "$")
         '((1 font-lock-keyword-face t)
           (2 font-lock-string-face t)))

   ;; strength
   (cons (concat "^!:"              ;start
                 "\\(strength\\)"   ;keyword
                 "[ \t]+"           ;space
                 "\\([+*]?\\)"
                 "\\([0-9]+\\)"         ;id
                 "$")
         '((1 font-lock-keyword-face t)
           (2 font-lock-operator-face t)
           (3 font-lock-number-face t)))

   ;; apple type recog
   (cons (concat "^!:"              ;start
                 "\\(apple\\)"      ;keyword
                 "[ \t]+"           ;space
                 "\\(.*\\)"         ;id
                 "$")
         '((1 font-lock-keyword-face t)
           (2 font-lock-string-face t)))

;;;    (cons "\\$[0-9*#@]"
;;; 	 '((1 font-lock-variable-name-face t)))
   )
  "Keywords for file-magic-mode")

;;;###autoload
(defun file-magic-mode ()
  "A major-mode to edit libmagic files like magic"

  (interactive)
  (kill-all-local-variables)

  (setq major-mode 'file-magic-mode)
  (setq mode-name "File-Magic")

  (make-local-variable 'comment-start)
  (setq comment-start "# ")

  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)

  (make-local-variable	'font-lock-defaults)
  (setq font-lock-defaults `(file-magic-font-lock-keywords nil))

  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\" "w" table)
    (set-syntax-table table))

  (run-hooks 'file-magic-mode-hook)
  )

(add-to-list 'magic-mode-alist '("\\`^# Magic" . file-magic-mode))
(add-to-list 'auto-mode-alist '("/magic/Magdir/" . file-magic-mode))
(add-to-list 'auto-mode-alist '("\\.magic\\'" . file-magic-mode))

;; ============================================================================

;; Emacs file magic

(defun file-magic (filename)
  "Determine the file-type of FILENAME using file (and libmagic)."
  (interactive "fFile to investigate: ")
  (if (and (file-readable-p filename)
           (executable-find "file"))
      (let ((magic-string
             (shell-command-to-string (concat "file "
                                              "-b " ;don't append filenames
                                              filename))))
        (if (interactive-p)
            (message magic-string)
          magic-string))))
;; Use: (file-magic (elsub "mine/pnw-dot-emacs.el"))

(defun file-magic-match (filename regexp)
  "Match keywords REGEXP with the file-type of FILENAME (using libmagic)."
  (interactive "fFile to investigate: \nsKeyword regexp: ")
  (let ((magic (file-magic filename)))
    (if magic (string-match regexp magic)
      nil)))
;; (file-magic-match (elsub "mine/pnw-dot-emacs.el") "Lisp")

(defun file-magic-is-ELF-p (filename)
  "Return non-nil if FILENAME is an ELF (Executable and Linkable Format)"
  (interactive "fFile to investigate: ")
  (file-magic-match filename "^ELF")
  )
;; (file-magic-is-ELF-p "/bin/bash")

(defun file-magic-is-ELF-exe-p (filename)
  "Return non-nil if FILENAME is an ELF executable (Executable
and Linkable Format)"
  (interactive "fFile to investigate: ")
  (file-magic-match filename "^ELF.*executable")
  )
;; (file-magic-is-ELF-exe-p "/bin/bash")

(defun file-magic-is-ELF-obj-p (filename)
  "Return non-nil if FILENAME is an ELF relocatable (Executable
and Linkable Format)"
  (interactive "fFile to investigate: ")
  (file-magic-match filename "^ELF.*relocatable")
  )
;; (file-magic-is-ELF-obj-p "~/justcxx/bitv.o")

(defun file-magic-is-executable-ELF-p (filename)
  "Return non-nil if FILENAME can be executed by you and is
an ELF relocatable (Executable and Linkable Format)."
  (and (file-executable-p filename)	;Note: efficiently skip
                                        ;all non-executable files
       (file-magic-is-ELF-p filename)))

;; ============================================================================

(provide 'file-magic)

;;; file-magic.el ends here
