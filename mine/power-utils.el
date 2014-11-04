;;; power-utils.el --- Large Collection of lots och nice and useful Snippets and Utilities.

(eval-when-compile (require 'cl))

(require 'faze)

;;; Version Management
(when t
  (when (not (boundp 'version<=)) (defun version<= (v1 v2) "Return non-nil if V1 is less than or equal to V2."    (or (version< v1 v2)
                                                                                                                        (version= v1 v2))))
  (when (not (boundp 'version>))  (defun version>  (v1 v2) "Return non-nil if V1 is greater than to V2."         (not (version< v1 v2))))
  (when (not (boundp 'version>=)) (defun version>= (v1 v2) "Return non-nil if V1 is greater than or equal to V2." (or (version> v1 v2)
                                                                                                                        (version= v1 v2))))
  (when (require 'inversion nil t)
    (when (not (boundp 'inversion-<=)) (defun inversion-<= (v1 v2) "Return non-nil if V1 is less than or equal to V2."    (or (inversion-< v1 v2)
                                                                                                                              (inversion-= v1 v2))))
    (when (not (boundp 'inversion->)) (defun inversion->  (v1 v2) "Return non-nil if V1 is greater than to V2."         (not (inversion-< v1 v2))))
    (when (not (boundp 'inversion->=)) (defun inversion->= (v1 v2) "Return non-nil if V1 is greater than or equal to V2." (or (inversion-> v1 v2)
                                                                                                                              (inversion-= v1 v2))))
    (defalias 'inversion-decode-version-string 'inversion-decode-version)
    (defalias 'inversion-parse-version 'inversion-decode-version)
    )
  )

(defun region-string (&optional region)
  "Return active region as a string or nil of region active."
  (interactive)
  (if region
      (buffer-substring (car region) (cdr region))
    (when (region-active-p)
      (buffer-substring (region-beginning)
                        (region-end)))))

(defsubst pop-to-buffer-same-window (buffer &optional norecord)
  (switch-to-buffer buffer norecord t))

(defsubst display-buffer-other-window (buffer)
  (display-buffer buffer t))

;; Loading and finding files and directories when the exist.

(defun load-file-if-exist (filename)
  "Load FILENAME only when it exist."
  (ignore-errors
    (load-file filename)))

(defun find-file-if-exist (filename)
  "Find FILENAME only when it exist."
  (ignore-errors
    (find-file filename)))

(defun find-file-read-only-if-exist (filename)
  "Find FILENAME read-only only when it exist."
  (ignore-errors
    (find-file-read-only filename)))

(defun find-file-noselect-if-exist (filename)
  "Find FILENAME only when it exist.
The buffer is not selected, just returned to the caller."
  (ignore-errors
    (find-file-noselect filename)))

(defun command-exists-p (cmd)
  "Determine whether CMD exists or not.
Usage should be similar to `shell-command' and `shell-command-to-string'."
  (condition-case nil
      (if (stringp cmd)
          (if (= (call-process "which" nil nil nil cmd)
                 0)
              t
            nil)
        (error "Argument %s is not a string" cmd))
    (file-error (error "Cannot find WHICH command"))))
(defalias 'command-exists? 'command-exists-p)
;;(command-exists-p "which")

;; ---------------------------------------------------------------------------

(defalias 'reverse-assoc 'rassoc)

(defun dassoc (key alist)
  "Returns the cdr of the first cons of ALIST if KEY is `equal'
to the car of that cons of ALIST. If that fails, returns the car
of the first cons of ALIST if KEY is `equal' to the cdr of that
cons of ALIST. Otherwise returns nil."
  (let ((elm  (cdr (assoc key alist))))
    (if elm elm (car (rassoc key alist)))))
(defalias 'two-way-assoc 'dassoc)
(defalias 'dual-assoc 'dassoc)
(defalias 'pair-assoc 'dassoc)
;; Use: (dassoc 'x '((x . y) (a . b)))
;; Use: (dassoc "y" '(("x" . "y") ("a" . "b")))

(defun dassq (key alist)
  "Returns the cdr of the first cons of ALIST if KEY is `eq'
to the car of that cons of ALIST. If that fails, returns the car
of the first cons of ALIST if KEY is `eq' to the cdr of that
cons of ALIST. Otherwise returns nil."
  (let ((elm  (cdr (assq key alist))))
    (if elm elm (car (rassq key alist)))))
(defalias 'two-way-assq 'dassq)
(defalias 'dual-assq 'dassq)
(defalias 'pair-assq 'dassq)
;; Use: (dassq 'x '((x . y) (a . b)))
;; Use: (dassq "y" '(("x" . "y") ("a" . "b")))

;; ---------------------------------------------------------------------------

(defsubst syntax-name (&optional pos)
  "Return currenct syntax as a symbol."
  (let* ((val (save-excursion (syntax-ppss pos))))
    (cond ((nth 3 val) 'string)
          ((nth 4 val) 'comment)
          (t 'code))))
;; Use: (syntax-name)

(defsubst at-syntax-p (name &optional pos)
  "Return non-nil if inside syntax NAME."
  (eq name (syntax-name pos)))
;; Use: (at-syntax-p 'string) => nil
;; Use: (at-syntax-p 'comment) => t
;; Use: (at-syntax-p 'code) => nil

(defsubst at-syntax-code-p (&optional pos)
  "Check if we are standing inside real-code."
  (let ((val (save-excursion (syntax-ppss pos)))) (not (or (nth 3 val)
                                                           (nth 4 val)))))
(defalias 'at-syntax-code? 'at-syntax-code-p)
;; Use: (at-syntax-code-p)

(defsubst at-syntax-string-p (&optional pos)
  (let ((val (save-excursion (syntax-ppss pos)))) (nth 3 val)))
(defalias 'at-syntax-string? 'at-syntax-string-p)
;; Use: (at-syntax-string-p)

(defsubst at-syntax-comment-p (&optional pos)
  (let ((val (save-excursion (syntax-ppss pos)))) (nth 4 val)))
(defalias 'at-syntax-comment? 'at-syntax-comment-p)
;; Use: (at-syntax-comment-p)

(defsubst at-syntax-string-or-comment-p (&optional pos)
  (let ((val (save-excursion (syntax-ppss pos)))) (or (nth 3 val)
                                                      (nth 4 val))))
(defalias 'at-syntax-string-or-comment? 'at-syntax-string-or-comment-p)
;; Use: (at-syntax-string-or-comment-p)

(defsubst at-syntax-code-or-string-p (&optional pos)
  (let ((val (save-excursion (syntax-ppss pos)))) (not (nth 4 val)))) ;that is not in comment
;; Use: (at-syntax-code-or-string?)

(defsubst at-syntax-code-or-comment-p (&optional pos)
  (let ((val (save-excursion (syntax-ppss pos)))) (not (nth 3 val)))) ;that is not in string
;; Use: (at-syntax-code-or-comment?)

(defconst syntax-context-alist
  '(("Any" 't)
    ("Code" 'at-syntax-code-p)
    ("Comments" 'at-syntax-comment-p)
    ("Strings" 'at-syntax-string-p)
    ("Code-or-Comments" 'at-syntax-code-or-comment-p)
    ("Code-or-Strings" 'at-syntax-code-or-string-p)
    ("Comments-or-Strings" 'at-syntax-string-or-comment-p))
  "List of Syntax Contexts and their respective predicate functions."
  )

(defun read-syntax-context (&optional pos)
  "Read Syntax Context."
  (assoc (completing-read "Syntax Context: " syntax-context-alist
                          nil t nil nil "Any")
         syntax-context-alist))
;; Use: (read-syntax-context)

;; ---------------------------------------------------------------------------

(defun print-to-file (object filename &optional how)
  (save-excursion
    (let ((buffer (find-file filename)))
      (goto-char (if how (point-min) (point-max)))
      (print object buffer)
      (set-buffer buffer)
      (save-buffer))))
(defalias 'save-to-file 'print-to-file)
;; Use: (print-to-file fs-cache "print-sample.save")

;; ---------------------------------------------------------------------------

(defun symbol-name-at-point ()
  "Return name (string) of symbol at point."
  (let ((sym (symbol-at-point)))
    (when sym (symbol-name sym))))

(defun keymap-at-point ()
  "Return keymap at point."
  (let ((sym (symbol-at-point)))
    (when (and sym (keymapp (eval sym)))
      sym)))

;; ---------------------------------------------------------------------------

;;20.08.2001, From: Cyprian Laskowski <cyp@swagbelly.net>
(defun describe-map (map)
  "Describe the key bindings of MAP."
  (interactive
   (list (intern
          (let ((sym (keymap-at-point)))
            (completing-read (format "Describe keymap%s: "
                                     (if sym (concat " (default " (symbol-name sym) ")") ""))
                             obarray
                             (lambda (e) (and (boundp e) (string-match "-map$" (symbol-name e))))
                             t nil nil (symbol-name sym))))))
  (let (beg end)
    (with-temp-buffer
      (use-local-map (eval map))
      (describe-bindings))
    (set-buffer "*Help*")
    (rename-buffer (generate-new-buffer-name (concat "*" (symbol-name map) " bindings*")))
    (setq beg (and (re-search-forward "^Major Mode Bindings:$" nil t) (1+ (match-end 0)))
          end (and (re-search-forward "^Global Bindings:$" nil t) (match-beginning 0)))
    (if (and beg end)
        (narrow-to-region beg end)
      (narrow-to-region 1 1)
      (error (concat (symbol-name map) " has no bindings set.")))))
(defalias 'list-map-key-bindings 'describe-map)
(defalias 'describe-keymap 'describe-map)

;; ---------------------------------------------------------------------------
;; Object Type Predicates Alises

(defmacro every-p (list) (cons 'and (eval list)))
;; Use: (every-p '(t t))
(defalias 'each-p 'every-p)
(defalias 'all-p 'every-p)
(defalias 'every? 'every-p)
(defalias 'each? 'every-p)
(defalias 'all? 'every-p)

(defmacro any-p (list) (cons 'or (eval list)))
;; Use: (any-p '(t nil))
(defalias 'any? 'any-p)

(defalias 'some-p 'any-p)
(defalias 'some? 'any-p)

;; ---------------------------------------------------------------------------

;; ToDo: Print some represenation of functions.
(defun message-object (obj)
  "Print OBJ as a symbol and then its value."
  (cond ((symbolp obj)
         (let ((obj-name (symbol-name obj)))
           (if (boundp obj)
               (message (concat obj-name ": %s")
                        (if (functionp obj)
                            obj
                          (eval obj)))
             (message (concat (faze obj-name 'var) ": not bound") ))))
        ((listp obj)
         (message "%s" obj))))
(defalias 'show 'message-object)
;; Use: (message-object 'vc-directory-exclusion-list)
;; Use: (message-object 'find-file)
;; Use: (message-object 'find-filef)
;; Use: (message-object '(C C++))

;; ---------------------------------------------------------------------------

(defalias 'make-string-from-char 'char-to-string)

(defalias 'chars-to-string 'string)
(defalias 'make-string-from-chars 'string)

(defun n-spaces (n)
  "See: (info \"(elisp) Creating Strings\")."
  (make-string n ?\s))
;; Use: (n-spaces 10)

(defun delimit-regexp (regexp delim)
  "Delimit REGEXP with delimiter DELIM."
  (if (equal delim 'words) (concat "\\<" regexp "\\>") ;word-delimited
    (if (equal delim 'symbols) (concat "\\_<" regexp "\\_>") ;symbol-delimited
      regexp))
  )
;; Use: (delimit-regexp "alpha" 'symbols)

(defun looking-at-ia (regexp)
  "Interactive version of looking-at()"
  (interactive "sRegexp: ")
  (message "%S" (looking-at regexp))
  )

(defun build-word-delim-regexp (id)
  "Matches an ID as single word that respects underscore."
  (concat "\\(" "\\<"
          id
          "\\>" "\\)"))

(defun build-symbol-regexp (id)
  "Matches an ID as single word symbol (or C identifier) that
does not respect underscore."
  (concat "\\_<" id "\\_>"))

(defun build-lisp-identifier-regexp (id)
  "Matches an ID as single word Lisp identifier that respects underscore."
  (concat "\\(\\S_\\)" id "\\(\\S_\\)"))

;; ---------------------------------------------------------------------------

(defun regexp-embrace (str)
  (concat "\\(?:" str "\\)"))
;;(regexp-embrace "alpha")

(defun regexp-quote-alts (sequence &optional delim)
  "Return a regexp string which exactly matches any of the
elements (alternatives) in the SEQUENCE of strings."
  (interactive)
  (delimit-regexp
   (mapconcat 'regexp-quote sequence "\\|") delim))
;;(regexp-quote-alts '("*a" "*b" "*c") 'words)
;;(regexp-quote-alts '["*a" "*b" "*c"] 'symbols)

(defun regexp-quote-any (arg &optional delim)
  "Return a regexp string which exactly matches any of the
elements (alternatives) in ARG (list of strings) or directly ARG
if it is string."
  (interactive)
  (delimit-regexp
   (if (stringp arg) (regexp-quote arg)
     (if (listp arg) (regexp-opt arg)
       (if (sequencep arg) (regexp-quote-alts arg)
         nil))) delim))
;;(regexp-quote-any "*a")
;;(regexp-quote-any '("*a" "*b" "*c") 'words)
;;(regexp-quote-any '["*a" "*b" "*c"] 'symbols)
;;(regexp-opt '("*a" "*b" "*c") 'words)

(defun regexp-from-alts (sequence &optional embrace-flag)
  "Return a regexp string which exactly matches any of the
elements (alternatives) in the SEQUENCE of strings interpreted as
regular expressions."
  (interactive)
  (mapconcat (if embrace-flag 'regexp-embrace 'identity)
             sequence "\\|"))
;; Use: (regexp-from-alts '("a" "b" "c") t)
;; Use: (regexp-from-alts '("a" "b" "c") nil)
;; Use: (regexp-from-alts '["a" "b" "c"] nil)

(defun regexp-gen-literal (arg &optional embrace-flag)
  "Return a regexp string which exactly matches any of the
elements (alternatives) in the ARG of strings (which may in turn
be regexps) or directly ARG if it is string (regexp)."
  (interactive)
  (if (stringp arg) arg
    (if (sequencep arg) (regexp-from-alts arg embrace-flag)
      nil)))
;;(regexp-gen-literal "*a" t)
;;(regexp-gen-literal '("*a" "*b" "*c") t)
;;(regexp-gen-literal '["*a" "*b" "*c"] t)

;;; -------- Finding and Stripping Common Prefixes --------

(defconst regexp-special-chars-list
  '(?$ ?^ ?. ?* ?+ ?? ?\[ ?\\)
  "List of characters that have a special meaning in Emacs
Regular Expression.")

(defconst regexp-special-chars-string-list
  '("$" "^" "." "*" "+" "?" "[" "\\")
  "List of characters that have a special meaning in Emacs
Regular Expression.")

(defconst regexp-special-chars-string
  (mapconcat 'identity regexp-special-chars-string-list "")
  "String containing all characters that have a special meaning
in Emacs Regular Expression.")

(defconst regexp-special-char-regexp
  (concat "["
          (mapconcat 'regexp-quote regexp-special-chars-string-list "")
          "]")
  "Regexp that matches any character that have a special meaning
  in an Emacs Regular Expression.")

(defconst regexp-ordinary-char-regexp
  (concat "[^"
          (mapconcat 'regexp-quote regexp-special-chars-string-list "")
          "]")
  "Regexp that matches any (ordinary) character that have no
  special meaning in an Emacs Regular Expression.")

(defun string-regexp-p (string)
  "Return t if STRING contains regexp characters. See:
http://www.gnu.org/software/emacs/manual/html_node/emacs/Regexps.html"
  (string-match (regexp-quote-alts regexp-special-chars-string-list)
                string))
(defalias 'string-regexp? 'string-regexp-p)
;; Use: (string-regexp-p "a")
;; Use: (string-regexp-p "a_b")
;; Use: (string-regexp-p "a\\")
;; Use: (string-regexp-p "a.b")

;;; -------- Finding and Stripping Common Prefixes --------

(defun common-prefix (collection)
  "Find the (longest) common prefix of all the elements in COLLECTION"
  (try-completion "" collection))
;; Use: (common-prefix '("/etc/passwd" "/etc/passwd~" "/etc/password"))
;; Use: (all-completions "" '("/etc/passwd" "/etc/passwd~" "/etc/password"))

(defun common-suffix (sequencep)
  "Find the (longest) common suffix of all the elements in COLLECTION"
  (string-reverse (common-prefix (mapcar 'string-reverse sequencep))))
;; Use: (common-suffix '("/etc/passwd" "passwd"))

(defun strip-common-prefix (collection)
  "Strip the common prefix from all the elements in COLLECTION."
  (let ((from (string-width (common-prefix collection))))
    (mapcar (lambda (string) (substring string from))
            collection)))
;; Use: (strip-common-prefix '("a1" "a2"))

(defun strip-common-path-prefix (collection)
  "Strip the common path-prefix from all the elements in COLLECTION."
  (let ((from (string-width (common-prefix collection))))
    (mapcar (lambda (string) (substring string from))
            collection)))
;; Use: (strip-common-path-prefix '("include/foo.h" "include/foo2.h"))

(defun string-reverse (string)
  "Reverse STRING.
Also see `completion--sreverse'."
  (concat (reverse (append string nil))))
;; Use: (string-reverse "alpha")

(defun string-trim (s)
  "Remove whitespace at beginning and end of string."
  (if (string-match "\\`[ \t\n\r]+" s) (setq s (replace-match "" t t s)))
  (if (string-match "[ \t\n\r]+\\'" s) (setq s (replace-match "" t t s)))
  s)

(defun string-find-string (key-string string &optional start)
  "Return index of start of first match for KEY-STRING in STRING, or nil."
  (string-match (regexp-quote key-string) string start))
;;(string-find-string "*beta" "*alpha *beta *gamma")

(defun string-match-generic (fmatcher string)
  "Filter the string STRING using Matcher FMATCHER and return
the result."
  (or (not fmatcher)
      (and (stringp fmatcher)
           (string-match fmatcher string))
      (and (functionp fmatcher)
           (funcall fmatcher string))))

;; Use: (split-string "/etc/X11/xorg.conf" "[/]")

;;; See: http://www.emacswiki.org/cgi-bin/wiki/QueryExchange
(defun query-exchange (s1 s2)
  "Exchange s1 and s2 interactively.
The user is prompted at each instance like query-replace."
  (interactive "sString 1: \nsString 2: ")
  (perform-replace
   (concat "\\(" s1 "\\)\\|" s2)
   '(replace-eval-replacement replace-quote
                              (if (match-string-no-properties 1) s2 s1))
   t t nil))
;; Use: (query-exchange "aaa" "bbb")
;; aaa aaa

;;; -------- Querying Sub-Content of Strings --------

(defun sort-words-in-region (reverse beg end)
  "Sort words in region alphabetically, in REVERSE if negative.
Prefixed with negative \\[universal-argument], sorts in reverse.

The variable `sort-fold-case' determines whether alphabetic case
affects the sort order.

See `sort-regexp-fields'."
  (interactive "P\nr")
  (sort-regexp-fields reverse "\\w+" "\\&" beg end))

;;; -------- Querying Sub-Content of Strings --------

(defun reverse-words-in-region (beg end)
  "Reverse the order of words in region.
Example:
first, second, third - last.
Running M-x reverse-words on this sentence with the region
starting from the beginning but not including the period:
last - third, second, first."
  (interactive "r")
  (apply 'insert
         (reverse (split-string (delete-and-extract-region beg end) "\\b"))))

(defun reverse-sexps-in-region (beg end)
  "Reverse the order of sexps in region.
Example:
first, second, third - last.
Running M-x reverse-words on this sentence with the region
starting from the beginning but not including the period:
last - third, second, first."
  (interactive "r")
  (apply 'insert
         (reverse (split-string (delete-and-extract-region beg end) "\\b"))))

(defun transpose-words-dwim (arg)
  "Tranpose Words DWIM."
  (interactive "*p")
  (if (region-active-p)
      (reverse-words-in-region (region-beginning)
                               (region-end))
    (transpose-words arg)))
(global-set-key [(meta t)] 'transpose-words-dwim)

(defun transpose-sexps-dwim (arg)
  "Like M-`x transpose-words-dwim' but applies to sexps."
  (interactive "*p")
  (if (region-active-p)
      (reverse-sexps-in-region (region-beginning)
                               (region-end))
    (transpose-sexps arg)))
(global-set-key [(control meta t)] 'transpose-sexps-dwim)

;;; -------- Querying Sub-Content of Strings --------

(defun set-same-major-mode-as (buffer)
  "Set same major mode as BUFFER."
  (interactive "bSet same major mode as buffer: ")
  (let ((major (with-current-buffer buffer major-mode)))
    (funcall major)))

(defun current-buffer-name ()
  (interactive)
  (buffer-name))

(defun shrink-fit-window-of-buffer (&optional buffer-or-name frame)
  "Shrink the window displaying BUFFER-OR-NAME if it is larger
than its buffer contents."
  (interactive)
  (shrink-window-if-larger-than-buffer (get-buffer-window buffer-or-name frame)))

(defmacro buffer-exists-p (buffer)
  "Return t if a buffer named BUFFER exists."
  `(let ((buffer ,buffer))
     (when buffer
       (funcall (if (stringp buffer) 'get-buffer 'buffer-name)
                buffer))))
;; Use: (buffer-exists-p "*Messages*")

(defun check-balanced-defuns (buffer)
  "Check that every defun in BUFFER is balanced (current-buffer if interactive)."
  (interactive "bBuffer to balance: ")
  (let ((buff (get-buffer buffer)))
    (set-buffer buff)
    (let ((next-end (point-min)))
      (condition-case ddd
          (progn
            (while (setq next-end (scan-lists next-end 1 0)))
            (if (called-interactively-p 'interactive)
                (message "All defuns balanced.")
              t))
        (error
         (push-mark nil t)
         (goto-char next-end)
         (re-search-forward "\\s(\\|\\s)")
         (backward-char 1)
         (cond ((called-interactively-p 'interactive)
                (message "Unbalanced defun.") (ding))
               (t nil)))))))

(defun insert-relative (new curr &optional rpos)
  "Insert the string NEW among regexp CURR in RPOS-relative in
current buffer. RPOS can either `first' or `last'."
  (save-excursion
    (let ((hit nil))
      (case rpos
        ('first                         ;before first
         (goto-char (point-min))
         (setq hit (re-search-forward curr nil t))
         (if hit (goto-char (match-beginning 0))) ;if found before hit
         (insert new)
         )
        ('last                          ;after last
         (goto-char (point-max))
         (setq hit (re-search-backward curr nil t))
         (if hit (goto-char (match-end 0))) ;if found after hit
         (insert new)
         )
        (t                              ;default
         (insert new)                   ;insert at current point
         )
        )
      (when nil
        (if hit
            (message "Hit!")
          (message "No hit!")))
      )))

(when nil
  (insert-relative "#include <FIRST>\n" "#include <vector>\n" 'first)
  (insert-relative "#include <LAST>\n" "#include <vector>\n" 'last)
  )

;; Insert a path into the current buffer.
;; See: http://www.rlazo.org/blog/entry/2008/sep/13/insert-a-path-into-the-current-buffer/
(defun insert-path (file &optional expand-flag)
  "Insert the path FILE into buffer after point."
  (interactive "FPath: ")
  (insert (if expand-flag (expand-file-name file) file)))
;; Use: (insert-path "~/.emacs.d/")
;; Use: (insert-path "~/.emacs.d/" t)

;; ---------------------------------------------------------------------------
;; Inserting Element Relative to Elements already in List

(defun list-insert-after (e l n)
  "Insert element E into list L after first element having value
N."
  (cond ((null l)
         '())
        ((equal n (car l))
         (cons (car l) (cons e (cdr l))))
        (t
         (cons (car l) (list-insert-after e (cdr l) n)))))
;; Use: (list-insert-after 'X '(a b c) 'b)

(defun list-insert-before (e l n)
  "Insert element E into list L before first element having value
N."
  (cond ((null l)
         '())
        ((equal n (car l))
         (cons e l))
        (t
         (cons (car l) (list-insert-before e (cdr l) n)))))
;; Use: (list-insert-before 'X '(a b c) 'b)

(defun remlq (elts list)
  "Remove ELTS from LIST and return result.
Comparison is done with `eq'."
  (mapc
   (lambda (elt)
     (setq list (remq elt list)))
   elts)
  list)
(eval-when-compile (assert-equal '(a d) (remlq '(b c) '(a b c d))))
(eval-when-compile (assert-equal '(a b c) (remlq nil '(a b c))))

;;; -------- Querying Sub-Content of Strings --------

(defun string-strip-prefix (whole beg)
  (if (string-prefix-p beg whole)
      (substring whole (length beg))
    whole))
(eval-when-compile (assert-equal (string-strip-prefix "elf.low" "elf.") "low"))
(eval-when-compile (assert-equal (string-strip-prefix "elf.low" "felf.") "elf.low"))

(defun strip-file-extension (filename extension)
  "Extract the final filename (without extension) from its full path."
  (let ((idx (string-match (concat "\\(.*\\)\\." extension "\\'")
                           filename)))
    (if idx
        (substring filename idx (match-length 1))
      filename)))
;; Use: (strip-file-extension "foo.h" "h")
;; Use: (strip-file-extension "foo.el" "x")
;; Use: (strip-file-extension "foo.el" "el")
;; Use: (strip-file-extension "foo.el.gz" "gz")
;; NOTE: Also see (file-name-sans-extension "foo.h")

(defun string-prefixes-p (begs whole)
  "Return t if the string WHOLE begins with any of the strings in BEGS."
  (string-match (concat "\\`" (eval `(rx (| ,@begs)))) whole))
;; Use: (string-prefixes-p '("std" "core") "std.")

(defalias 'string-compare 'compare-strings)

;; @related: just-one-space
(defalias 'just-one-empty-line 'delete-blank-lines)
(global-set-key [(meta shift return)] 'just-one-empty-line)

;; See: EmacsWiki on Multi Line Regular Expressions (Regexps):
;; http://www.emacswiki.org/emacs-en/MultilineRegexp
(unless (fboundp 'delete-duplicate-lines)
  (defun delete-duplicate-lines ()
    "Find duplicate lines and keep only the first occurrences."
    (interactive)
    (while
        (progn
          (goto-char (point-min))
          (re-search-forward "^\\(.*\\)\n\\(\\(.*\n\\)*\\)\\1$" nil t))
      (if (= 0 (length (match-string-no-properties 1)))
          (replace-match "\\2")
        (replace-match "\\1\n\\2")))))
(defalias 'delete-duplicate-buffer-lines 'delete-duplicate-lines)
(defalias 'uniquify-buffer-lines 'delete-duplicate-lines)

;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/e9d0c26e5beb52d9#
(defun shrink-whitespace ()
  "Collapse all whitespace around point, depending on context.
White space here includes space, tabs, and any end of line char.
This commands either calls `just-one-space' or `delete-blank-lines'."
  (interactive)
  (let (p1 p2 mytext)
    (save-excursion
      (skip-chars-backward "\t \n")
      (setq p1 (point))
      (skip-chars-forward "\t \n")
      (setq p2 (point))
      (setq mytext (buffer-substring-no-properties p1 p2))
      )
    (if (string-match "[\t ]*\n[\t ]*\n" mytext)
        (progn (delete-blank-lines))
      (progn (just-one-space))
      )
    )
  )
(defalias 'collapse-whitespace 'shrink-whitespace)

;;; -------- Querying Sub-Content of Strings --------

;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/4d4f5d16d8ca1191#

(progn                             ;TODO Make this part of paredit.el
  (defun beginning-of-list ()
    "Move to beginning of list, before first element."
    (interactive)
    (up-list)
    (beginning-of-sexp)
    (down-list))
  (global-set-key [(meta shift ?a)] 'beginning-of-list)

  (defun end-of-list ()
    "Move to end of list, after last element."
    (interactive)
    (up-list)
    (down-list -1))
  (global-set-key [(meta shift ?e)] 'end-of-list)

  (defun move-beginning-of-list ()
    "Move to the beginning of a list, before first element."
    (interactive)
    (while (ignore-errors (backward-sexp) t)))

  (defun move-end-of-list ()
    "Move to the end of list, before first element."
    (interactive)
    (while (ignore-errors (forward-sexp) t)))

  (local-set-key [(control shift meta a)] 'beginning-of-list)
  (local-set-key [(control shift meta e)] 'end-of-list)
  )

;;; -------- sexp navigation --------

(defun forward-sexp-safe (&optional arg)
  (interactive "^p")
  (unless (ignore-errors (forward-sexp arg) t)
    (message "After last sexp") ;(sit-for 1)
    (ding)))
(global-set-key [(control meta ?f)] 'forward-sexp-safe)
(defun backward-sexp-safe (&optional arg)
  (interactive "^p")
  (unless (ignore-errors (backward-sexp arg) t)
    (message "Before first sexp") ;(sit-for 1)
    (ding)))
(global-set-key [(control meta ?b)] 'backward-sexp-safe)

;;; -------- list navigation --------

(defun forward-list-safe (&optional arg)
  (interactive "^p")
  (unless (ignore-errors (forward-list arg) t)
    (message "After last list") ;(sit-for 1)
    (ding)))
(global-set-key [(control meta ?n)] 'forward-list-safe)
(defun backward-list-safe (&optional arg)
  (interactive "^p")
  (unless (ignore-errors (backward-list arg) t)
    (message "Before first list") ;(sit-for 1)
    (ding)))
(global-set-key [(control meta ?p)] 'backward-list-safe)

;;; -------- marking --------

(defun mark-sexp-safe (&optional arg allow-extend)
  (interactive "P\np")
  (unless (ignore-errors (mark-sexp arg allow-extend) t)
    (message "All sexp marked") ;(sit-for 1)
    (ding)))
(global-set-key [(control meta ?\ )] 'mark-sexp-safe)

(defun mark-word-safe (&optional arg allow-extend)
  (interactive "P\np")
  (unless (ignore-errors (mark-word arg allow-extend) t)
    (message "All words marked")
    ;; (sit-for 1)
    (ding)))
(global-set-key [(meta ?W)] 'mark-word-safe)

;;; -------- skipping chars --------

(defun skip-chars-forward-ia (string &optional lim)
  "Move point forward, stopping before a char that is not in STRING."
  (interactive "sString of chars to skip forwards: ")
  (skip-chars-forward string lim)
  )

(defun skip-chars-backward-ia (string &optional lim)
  "Move point forward, stopping before a char that is not in STRING."
  (interactive "sString of chars to skip backwards: ")
  (skip-chars-backward string lim)
  )

;;; -------- skipping whitespace --------

(defsubst skip-whitespace-forward (&optional lim)
  "Move point forward, stopping before a char that is not whitespace."
  (interactive)
  (skip-chars-forward "\t \n" lim)
  )

(defsubst skip-whitespace-backward (&optional lim)
  "Move point backward, stopping before a char that is not whitespace."
  (interactive)
  (skip-chars-backward "\t \n" lim)
  )

(defalias 'symbol-to-string 'symbol-name)
;; Use: (symbol-to-string 'test-symbol)

;;; -------- Querying Sub-Content of Strings --------

(defalias 'subsequence 'subseq)

(defalias 'append-sequences 'append)

(defun extract-elements (pred seq)
  "Extract a copy of SEQ containing all elements fullfilling PRED."
  (delq nil (mapcar `(lambda (elm) (when (,pred elm) elm)) seq)))
;; Use: (extract-elements 'symbolp '(a b 1 2)) => '(a b)
;; Use: (extract-elements 'numberp '(a b 1 2)) => '(1 2)

;; -------- Querying Sub-Content of Strings --------

(defalias 'open-file 'find-file)

;; Aliases to ease in finding the right function.
(defalias 'file-name-without-extension 'file-name-sans-extension)
(defalias 'file-name-sans-directory 'file-name-nondirectory)
(defalias 'file-name-without-directory 'file-name-nondirectory)

;; reduce-file-name (to ".reduce-file-name")
(defmacro tv-reduce-file-name (fname level &optional unix-close expand)
  "Reduce file-name by `level' number from end.
`level' is an integer
`unix-close' boolean, if true close filename with /
`expand' boolean, if true expand-file-name"
  `(let* ((exp-fname (expand-file-name ,fname))
          (fname-list (split-string (if ,expand exp-fname ,fname) "/" t))
          (pop-list (loop for s = fname-list then (subseq s 0 (1- (length s)))
                          repeat (1+ ,level)
                          collect s))
          (last-res (car (last pop-list)))
          (str-res (mapconcat (lambda (x) x) last-res "/")))
     (if ,unix-close
         (if ,expand
             (concat "/" str-res "/")
           (if (string-match "~/" str-res)
               (concat str-res "/")
             (concat "/" str-res "/")))
       (if ,expand
           (concat "/" str-res)
         (if (string-match "~/" str-res)
             (concat str-res "/")
           (concat "/" str-res "/"))))))

;; ---------------------------------------------------------------------------

;; Setting (Changing) the n:th element of a list or sequence.

(defalias 'setvars 'setq)               ;better alias
(defalias 'set-ref 'setf)
(defalias 'get-ref 'getf)

(defun setnthcar-alt (n list x)
  "Set N:th element of LIST to X for side effects only."
  (setcar (nthcdr n list) x))
(defun setnthcar (list n x)
  "Set N:th element of LIST to X for side effects only."
  (setf (nth n list) x))
(defalias 'list-setnth 'setnthcar)

(defun setnthref-alt (n array x)
  "Set N:th element of ARRAY to X for side effects only."
  (setf (aref array n) x))
(defalias 'array-setnth 'aset)
(defalias 'array-set 'aset)

(defun sequence-setnth (n seq x)
  "Set N:th element of SEQ to X for side effects only."
  (setf (elt seq n) x))

;; ---------------------------------------------------------------------------

;; Alias from re- to regexp-.
(defalias 'regexp-search-forward 're-search-forward)
(defalias 'regexp-search-forward-case-sensitive 're-search-forward-case-sensitive)
(defalias 'regexp-search-backward 're-search-backward)
(defalias 'regexp-builder 're-builder)

(defalias 'regexp-skip-forward 're-search-forward)
(defalias 'regexp-skip-backward 're-search-backward)

;; To harmonize with `skip-chars-forward' and `skip-chars-backward'.
(defalias 'skip-regexp-forward 're-search-forward)
(defalias 'skip-regexp-backward 're-search-backward)

(defalias 'regexp-search-backward 're-search-backward)

;; ---------------------------------------------------------------------------

(defalias 'push-to-list 'push)
(defalias 'pop-from-list 'pop)

;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/b364430d0d102bfd/9e7cc1814a1804db#9e7cc1814a1804db
(defmacro reverse-pop-from-list (LIST)
  "Reverse `pop'."
  `(prog1 (car (last ,LIST))
     (setq ,LIST (butlast ,LIST 1))))
(defalias 'rpop 'reverse-pop-from-list)

;; ---------------------------------------------------------------------------

(defun neq (obj1 obj2)
  "Return t if the two args are NOT the same Lisp object."
  (not (eq obj1 obj2)))
;; Use: (neq '1 '1)
;; Use: (neq '1 '2)
(defalias 'not-eq 'neq)

;; C-Style Alises
(progn
  (defalias '== 'eq)
  (defalias '!= 'neq)
  (defalias '&& 'and)
  (defalias '|| 'or)
  )

(defalias 'increment 'incf)
(defalias 'decrement 'decf)

(defun not-equal (obj1 obj2)
  "Return t if two Lisp objects do NOT have similar structure and contents."
  (not (equal obj1 obj2)))
;; Use: (not-equal '1 '1)
;; Use: (not-equal '1 '2)

;; ---------------------------------------------------------------------------

(defalias 'fbuiltinp 'subrp)
;; Use: (fbuiltinp (symbol-function 'cons))

(defalias 'defun-inline 'defsubst)
(defalias 'definline 'defsubst)

;; Note: Created these aliases because nth() only works for lists and
;; elt() isn't that intuitive.
(defalias 'index 'elt)
(defalias 'nth-element 'elt)
(defalias 'nth-sequence-element 'elt)
(defalias 'nth-array-element 'aref)

(defun bofp ()
  "Return t if point is at the beginning of a function."
  (message "bofp(): ToDo: Implement me by reusing beginning-of-defun()")
  nil)
(defalias 'bof? 'bofp)

(defun eofp ()
  "Return t if point is at the end of a function."
  (message "eofp(): ToDo: Implement me by reusing end-of-defun()")
  nil)
(defalias 'eof? 'eofp)

(defalias 'bob? 'bobp)
(defalias 'eob? 'eobp)

(defalias 'looking-forward 'looking-at)

;; More intuitive alises.
(defalias 'lookup-symbol 'intern)
(defalias 'delete-symbol 'unintern)
(defalias 'erase-symbol 'unintern)

;; Shorter alises.
(progn
  (defalias '1st 'first)
  (defalias '2nd 'second)
  (defalias '3rd 'third)
  (defalias '4th 'fourth)
  (defalias '5th 'fifth)
  (defalias '6th 'sixth)
  (defalias '7th 'seventh)
  (defalias '8th 'eighth)
  (defalias '9th 'ninth)
  (defalias '10th 'tenth)
  )

(defalias 'toolbar-mode 'tool-bar-mode)

;;; Define some aliases so can find toggle commands easily.
;;; ToDo: Perhaps better: (defun toggle-minor-mode (mode))
(progn
  (defalias 'toggle-abbrev-mode 'abbrev-mode)
  (defalias 'toggle-auto-fill-mode 'auto-fill-mode)
  (defalias 'toggle-auto-lower-mode 'auto-lower-mode)
  (defalias 'toggle-auto-raise-mode 'auto-raise-mode)
  (defalias 'toggle-auto-save-mode 'auto-save-mode)
  (defalias 'toggle-binary-overwrite-mode 'binary-overwrite-mode)
  (defalias 'toggle-compilation-minor-mode 'compilation-minor-mode) ; (defsubst)
  (defalias 'toggle-delete-selection-mode 'delete-selection-mode) ; `delsel.el'.
  (defalias 'toggle-double-mode 'double-mode)
  (defalias 'toggle-enable-flow-control 'enable-flow-control)
  (defalias 'toggle-font-lock-mode 'font-lock-mode)
  (defalias 'toggle-hide-ifdef-mode 'hide-ifdef-mode)
  (defalias 'toggle-iso-accents-mode 'iso-accents-mode)
  (defalias 'toggle-menu-bar-mode 'menu-bar-mode)
  (defalias 'toggle-overwrite-mode 'overwrite-mode)
  (defalias 'toggle-scroll-bar-mode 'scroll-bar-mode)
  (defalias 'toggle-standard-display-european 'standard-display-european)
  (defalias 'toggle-transient-mark-mode 'transient-mark-mode)
  (defalias 'toggle-outline-minor-mode 'outline-minor-mode)
  )

(defun byte-compile-directory (bytecomp-directory &optional bytecomp-force)
  "Handy alias to make it easier to find this version of byte-recompile-directory()."
  (byte-recompile-directory bytecomp-directory 0 bytecomp-force)
  )

(defun buffer-empty-p (&optional buffer)
  "Check if BUFFER is empty.
BUFFER defaults to `current-buffer'."
  (if buffer
      (with-current-buffer buffer
        (and (bobp) (eobp)))
    (and (bobp) (eobp))))
(defalias 'buffer-empty? 'buffer-empty-p)
;; Use: (buffer-empty-p)

(defalias 'buffer-visible-p 'get-buffer-window)
(defalias 'buffer-shown-p 'get-buffer-window)
(defalias 'buffer-displayed-p 'get-buffer-window)

(defalias 'buffer-window 'get-buffer-window)
(defalias 'current-window 'selected-window
  "Harmonize with naming of `current-buffer'.")
(defun current-window-buffer ()
  "Harmonize with naming of `current-buffer'."
  (window-buffer (selected-window)))
;; Use: (current-window-buffer)

;; ---------------------------------------------------------------------------
;; Windows

(defun toggle-hook (hook function &optional append)
  "Toogle HOOK for MODE."
  (if (not (remove-hook hook function))
      (add-hook hook function append)))
(defalias 'add-or-remove-hook 'toogle-hook)

;;; ===========================================================================
;;; Predicate Constants

(progn
  (defconst cpus-online-count
    (let ((count
           (string-to-number
            (shell-command-to-string "grep -c processor /proc/cpuinfo"))))
      (if (>= count 1) count 1))	;default to one if grep failed
    "Number of CPUs online. Defaults to 1 if this number could not be detected.")

  (defconst win32-p
    (eq system-type 'windows-nt)
    "Are we running on a WinTel system?")

  (defconst cygwin-p
    (eq system-type 'cygwin)
    "Are we running on a WinTel CygWin system?")

  (defconst linux-p
    (or (eq system-type 'gnu/linux)
        (eq system-type 'linux))
    "Are we running on a GNU/Linux system?")

  (defconst unix-p
    (or linux-p
        (eq system-type 'usg-unix-v)
        (eq system-type 'berkeley-unix))
    "Are we running UNIX?")

  (defconst linux-x-p
    (and window-system linux-p)
    "Are we running under X on a GNU/Linux system?")

  (defconst darwin-p
    (eq system-type 'darwin)
    "Are we running on a Darwin system?")

  (defconst xemacs-p (featurep 'xemacs)
    "Are we running XEmacs?")

  (defvar xemacsp xemacs-p "Set to t if we are in XEmacs.") ;Needed by bashdb

  (defconst emacs>=21-p (and (not xemacs-p)
                             (>= emacs-major-version 21))
    "Are we running GNU Emacs 21 or above?")

  (defconst emacs>=22-p (and (not xemacs-p)
                             (>= emacs-major-version 22))
    "Are we running GNU Emacs 22 or above?")
  )

;;; ===========================================================================
;;; Predicate Functions

(defun darwin-alt-p ()
  "Alternative function for determining if we are on a Darwin system"
  (interactive)
  (let ((env-OSTYPE (getenv "OSTYPE")))
    (or (and env-OSTYPE
             (string-match "^darwin" env-OSTYPE))
        (string-match "Darwin"
                      (shell-command-to-string "uname")))))
(defalias 'on-darwin? 'darwin-alt-p)

(defun unsetenv (variable &optional value substitute-env-vars)
  (interactive
   (read-envvar-name "Clear environment variable: " 'exact))
  )

(defalias 'set-shell-environment-variable 'setenv)
(defalias 'get-shell-environment-variable 'getenv)

;;; ===========================================================================
;; Environment Utils

;; see: http://stackoverflow.com/questions/6483875/temporary-modified-environment-during-external-process-call-from-emacs
(defalias 'with-process-environment 'server-with-environment)
(when nil
  (let ((process-environment (cons "FOO=BAR" process-environment)))
    (shell-command-to-string "echo $FOO"))
  (let ((process-environment (cons "LANGUAGE=en" process-environment)))
    (shell-command-at "make clean; make; " "~/Work/FOI/tgt")))

;;; ===========================================================================
;;; Predicate Macros

(progn
  (defmacro GNUEmacs (&rest x)
    (list 'if (string-match "GNU Emacs" (version)) (cons 'progn x)))

  (defmacro GNUEmacs-21 (&rest x)
    (list 'if (string-match "GNU Emacs 21" (version)) (cons 'progn x)))

  ;; Return t if we are in Emacs version 21, nil otherwise.
  (defun GNUEmacs-21-p ()
    (string-match "GNU Emacs 21" (version)))

  (defmacro GNUEmacs-21-3 (&rest x)
    (list 'if (string-match "GNU Emacs 21.3" (version)) (cons 'progn x)))

  (defmacro GNUEmacs-21-3-2 (&rest x)
    (list 'if (string-match "GNU Emacs 21.3.2" (version)) (cons 'progn x)))

  (defmacro GNUEmacs-21-4 (&rest x)
    (list 'if (string-match "GNU Emacs 21.4" (version)) (cons 'progn x)))

  (defmacro GNUEmacs->=22 (&rest x)
    (list 'if emacs>=22-p (cons 'progn x)))

  (defmacro XEmacs (&rest x)
    (list 'if xemacs-p (cons 'progn x)))

  (defmacro Xlaunch (&rest x)
    (list 'if (eq window-system 'x) (cons 'progn x)))
  )

;;; ===========================================================================
;; Crontab (to ".Crontab")

;;;###autoload
(defun tv-insert-new-crontab (min hr month-day month week-day progr)
  (interactive "sMin (0-59 or *): \
\nsHour (0 23 or *) \
\nsDayOfMonth (1 31 or *) : \
\nsMonth (1 12 or *): \
\nsDayOfWeek (0 7 or *) : \nsCommand: ")
  (let ((abs-prog (with-temp-buffer
                    (call-process
                     "which"
                     nil
                     t
                     nil
                     (format "%s" progr))
                    (buffer-string))))
    (insert (concat min
                    " "
                    hr
                    " "
                    month-day
                    " "
                    month
                    " "
                    week-day
                    " "
                    abs-prog))))

;; Delete-processes (to ".Delete-processes")
;;;###autoload
(defun tv-kill-process (process)
  (interactive (list (completing-read "Process: "
                                      (mapcar 'process-name
                                              (process-list))
                                      nil
                                      t)))
  (delete-process (get-process process)))

;; get-elisp-index-at-point (to ".get elisp-index at point")
;;;###autoload
(defun tv-get-index-at-point (expr)
  (interactive
   (list (read-from-minibuffer "Search: "
                               nil
                               nil
                               nil
                               nil
                               (thing-at-point 'sexp))))
  (elisp-index-search expr))

;; Redefine append-to-register with a "\n"
;;;###autoload
(defun tv-append-to-register (register start end &optional delete-flag)
  "Append region to text in register REGISTER.
With prefix arg, delete as well.
Called from program, takes four args: REGISTER, START, END and DELETE-FLAG.
START and END are buffer positions indicating what to append."
  (interactive "cAppend to register: \nr\nP")
  (let ((reg (get-register register))
        (text (filter-buffer-substring start end)))
    (set-register
     register (cond ((not reg) text)
                    ((stringp reg) (concat reg "\n" text))
                    (t (error "Register does not contain text")))))
  (if delete-flag (delete-region start end)))
(global-set-key (kbd "C-x r a") 'tv-append-to-register)
(global-set-key (kbd "C-x r L") 'list-registers)

;;; ===========================================================================

(defmacro autoload-file-remote (url file fn)
  "Autoload function FN from FILE downloaded at URL."
  (unless (file-exists-p file)
    (save-current-buffer
      (set-buffer (url-retrieve-synchronously url))
      (set buffer-file-name file)
      (save-buffer)))
  (autoload file fn))
;; Use: (autoload-file-remote)

;;; ===========================================================================

(defun directory-regular-files (directory)
  "Return number of regular files contained in DIRECTORY."
  (when (file-accessible-directory-p directory)
    (let (hits)
      (mapc
       (lambda (filename)
         (when (file-regular-p filename)
           (if hits (nconc hits (list filename)) (setq hits (list filename)))))
       (directory-files directory t))
      hits)))
;; Use: (directory-regular-files "/tmp/")
;; Use: (benchmark-run 1 (directory-regular-files "/usr/bin/"))

(defun directory-regular-files-count (directory)
  "Return number of regular files contained in DIRECTORY."
  (when (file-accessible-directory-p directory)
    (let ((count 0))
      (mapc (lambda (filename)
              (when (file-regular-p filename)
                (setq count (1+ count))))
            (directory-files directory t))
      count)))
;; Use: (directory-regular-files-count "/tmp/")
;; Use: (benchmark-run 1 (directory-regular-files-count "/usr/bin/"))

;;; ===========================================================================

;;; I used to pile stuff into my .emacs which whilst convenient for
;;; moving between sites was a nightmare to maintain. What I use now
;;; is an init style system which is kicked of with this in my .emacs:
(defun load-directory (dir)
  (mapc 'load
        (mapcar (lambda (file)
                  (if (file-exists-p (concat file "c"))
                      (concat file "c") file))
                (directory-files dir t "\\.el$"))))

;;; ===========================================================================
;;; Serializing Lisp Objects
;;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/d0fdd254ae1f123b#
(defalias 'encode-to-string 'prin1-to-string)
(defalias 'serialize-to-string 'prin1-to-string)
(defalias 'decode-from-string 'read-from-string)
(defalias 'unserialize-from-string 'read-from-string)

(defun buffer-ascii-clean-p ()
  "Return non-nil if current is ASCII clean, that is only
contains characters between 0 and 127."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (skip-chars-forward "[\0-\177]")
    (eobp)))
(defalias 'buffer-ascii-clean? 'buffer-ascii-clean-p)
(defalias 'buffer-7bit-clean-p 'buffer-ascii-clean-p)
(defalias 'buffer-7bit-clean? 'buffer-ascii-clean-p)
;; Use: (buffer-ascii-clean-p)

;; Escaping
(when nil
  (message "result: %s"
           (list
            (string-to-vector "ELF")
            (string-to-vector "\177ELF")
            (equal (string-to-vector "b1 ")
                   (string-to-vector "b1\5\0"))
            )))

(defun run-vanilla-emacs ()
  "Run \"Vanilla\" Emacs in background starting with my .emacs
file. Useful when debugging problems whose origin is hard to
determine."
  (interactive)
  (shell-command-silent-at
   (concat "emacs -bg \"#000000\" -fg wheat -cr green -ms green -Q -fn 6x13 "
           (read-file-name "Run with File/Directory: ")
           " &")
   "~"
   "*emacs-vanilla-output" "*emacs-vanilla-error*")
  "Launching Vanilla Emacs...")
(defalias 'run-emacs-vanilla 'run-vanilla-emacs)
(defalias 'vanilla-emacs-run 'run-vanilla-emacs)
(defalias 'execute-emacs-vanilla 'run-vanilla-emacs)
;; Use: (run-vanilla-emacs)

(defun function-at-point () (thing-at-point 'defun))
;; Use: (function-at-point)

(when (require 'trace nil t)
  (defun xsteve/trace-function (arg)
    (interactive "p")
    (let* ((untracing (< arg 0))
           (function (intern (completing-read (if untracing "Untrace function: " "Trace function: ")
                                              obarray 'fboundp t (symbol-name (function-at-point))))))
      (cond ((eq current-prefix-arg nil)
             (message "tracing %S in background" function)
             (trace-function-background function))
            ((> arg 0)
             (message "tracing %S" (faze function 'function))
             (trace-function function))
            (untracing
             (message "untracing %S" (faze function 'function))
             (untrace-function function))))))

;; ---------------------------------------------------------------------------

(defun c-mode? () (memq major-mode '(c-mode)))
(defun c++-mode? () (memq major-mode '(c++-mode)))
(defun objc-mode? () (memq major-mode '(objc-mode)))
(defun java-mode? () (memq major-mode '(java-mode)))
(defun emacs-lisp-mode? () (memq major-mode '(emacs-lisp-mode)))

;; ---------------------------------------------------------------------------

(defun make ()
  "Do make in current directory."
  (interactive)
  (compile "make"))
(defalias 'mk 'make)

(defun make-clean ()
  "Do make in current directory."
  (interactive)
  (compile "make"))
(defalias 'mkc 'make-clean)

;; UNIX Command Line style aliases for File Operations

;; Create
(defalias 'mkdir 'make-directory)

;; Rename
(defalias 'move-file 'rename-file)
(defalias 'mv-file 'rename-file)
(defalias 'mv 'rename-file)
(defalias 'ren-file 'rename-file)

;; Copy
(defalias 'cp-file 'copy-file)
(defalias 'cp 'copy-file)
(defalias 'cpdir 'copy-directory)

;; Delete
(defalias 'rmdir 'delete-directory)
(defalias 'deldir 'delete-directory)
(defun delete-file-or-directory (file)
  (interactive "fDelete file/directory: ")
  (dired-delete-file file 'ask))
(defalias 'rm-file (if (require 'dired nil t) 'delete-file-or-directory 'delete-file))
(defalias 'rm 'rm-file)
(defalias 'remove-file 'rm-file)

;; List Files
(defalias 'ls 'dired)

;; Hard-Link
(defalias 'hard-link-file 'add-name-to-file)
(defalias 'link-file-hard 'add-name-to-file)
(defalias 'lnh 'add-name-to-file)

;; Symbolic-Link
(defalias 'symbolic-link-file 'make-symbolic-link)
(defalias 'link-file-symbolic 'make-symbolic-link)
(defalias 'lns 'make-symbolic-link)

;; Change
(defalias 'change-directory 'cd)

;; ---------------------------------------------------------------------------

(defalias 'bell 'ding) ;; disable bell

;; ---------------------------------------------------------------------------

(defalias 'bob 'beginning-of-buffer)
(defalias 'eob 'end-of-buffer)
(defalias 'goto-bob 'beginning-of-buffer)
(defalias 'goto-eob 'end-of-buffer)

(defalias 'bol 'beginning-of-line)
(defalias 'eol 'end-of-line)
(defalias 'goto-bol 'beginning-of-line)
(defalias 'goto-eol 'end-of-line)

;; for consistency with other predicates
(defalias 'bol-p 'bolp)
(defalias 'eol-p 'eolp)
(defalias 'bol? 'bolp)
(defalias 'eol? 'eolp)
(defalias 'array-p 'arrayp)
(defalias 'array? 'arrayp)

;; ---------------------------------------------------------------------------
;;; Conversions

;; Convert DOS CR-LF to UNIX newline
(defun dos-to-unix ()
  (interactive)
  (goto-char (point-min))
  (while (search-forward "\r\n" nil t)
    (replace-match "\n")))
(defalias 'dos2unix 'dos-to-unix)

;; Convert UNIX newline to DOS CR-LF
(defun unix-to-dos ()
  (interactive)
  (goto-char (point-min))
  (while (search-forward "\n" nil t)
    (replace-match "\r\n")))
(defalias 'unix2dos 'unix-to-dos)

(defun buffer-dos-line-endings ()
  "Sets the buffer-file-coding-system to undecided-dos; changes the buffer
    by invisibly adding carriage returns"
  (interactive)
  (set-buffer-file-coding-system 'undecided-dos nil))

(defun buffer-unix-line-endings ()
  "Sets the buffer-file-coding-system to undecided-unix; changes the buffer
    by invisibly removing carriage returns"
  (interactive)
  (set-buffer-file-coding-system 'undecided-unix nil))

(defun tabify-buffer ()
  "Tabify the whole buffer."
  (tabify (point-min) (point-max)))
;; (add-hook 'find-file-hooks 'tabify-buffer)

(defun untabify-buffer ()
  "Untabify the whole buffer. Calls untabify for the whole
buffer. If called with prefix argument: use prefix argument as
tabwidth"
  (interactive "p")
  (let ((tab-width (or current-prefix-arg tab-width)))
    (untabify (point-min) (point-max)))
  (message "Untabified buffer."))
;; (remove-hook 'write-file-functions 'untabify-buffer)

(defun transpose-buffers (arg)
  "Transpose the buffers shown in two windows."
  (interactive "p")
  (let ((selector (if (>= arg 0) 'next-window 'previous-window)))
    (while (/= arg 0)
      (let ((this-win (window-buffer))
            (next-win (window-buffer (funcall selector))))
        (set-window-buffer (selected-window) next-win)
        (set-window-buffer (funcall selector) this-win)
        (select-window (funcall selector)))
      (setq arg (if (plusp arg) (1- arg) (1+ arg))))))
(defalias 'swap-buffers 'transpose-buffers)

(defun list-buffers-select ()
  "Variant of list-buffers() that switches to the *Buffer List* buffer."
  (interactive)
  (list-buffers)
  (other-window 1)
  (switch-to-buffer "*Buffer List*" t)
  )
;;(global-set-key [(control x) (control b)] 'list-buffers-select)

;; ---------------------------------------------------------------------------

(defun embrace-selection (&optional front-arg rear-arg)
  "Embrace the current selection with the front-arg and rear-arg."
  (interactive)
  (let* ((front (or front-arg (read-string "Front brace: ")))
         (rear (or rear-arg (read-string "Rear brace: "))))
    (if mark-active
        (progn
          (save-excursion
            (goto-char (region-beginning))
            (insert front))
          (save-excursion
            (goto-char (region-end))
            (insert rear)))
      (insert front)
      (save-excursion
        (insert rear)))))

;; ---------------------------------------------------------------------------

(defalias 'skip-errors 'ignore-errors)
(defalias 'inhibit-errors 'ignore-errors)

;; ---------------------------------------------------------------------------

(defsubst 2+ (number)
  "Return NUMBER plus two.
NUMBER may be a number ory a marker.  Markers are converted to
  integers."
  (+ number 2))

(defsubst 3+ (number)
  "Return NUMBER plus three.
NUMBER may be a number or a marker.  Markers are converted to
  integers."
  (+ number 3))

(defsubst 2- (number)
  "Return NUMBER minus two.
NUMBER may be a number ory a marker.  Markers are converted to
  integers."
  (- number 2))

(defsubst 3- (number)
  "Return NUMBER minus three.
NUMBER may be a number or a marker.  Markers are converted to
  integers."
  (- number 3))

;; ---------------------------------------------------------------------------

(defsubst unpropertize (string)
  "Return STRING, without text properties."
  (substring-no-properties string))

(defsubst buffer-match-no-properties (num)
  "Optimized version of match-string-no-properties()."
  (if (match-beginning num)
      (buffer-substring-no-properties (match-beginning num)
                                      (match-end num))))

(defsubst match-length (num)
  "Get length of match NUM."
  (when (match-beginning num)
    (- (match-end num)
       (match-beginning num))))
;; Use: (match-length 0)
;; Use: (match-length 1)
;; Use: (match-length 2)

(defsubst match-nonempty (num)
  "Check if match NUM is nonempty."
  (and (match-length num)
       (>= (match-length num) 1)))
;; Use: (match-nonempty 1)

;; ---------------------------------------------------------------------------

(defun shuffle-vector (vector)
  "Randomly permute the elements of VECTOR. All permutations will
be equally likely."
  (let ((i 0) j temp (len (length vector)))
    (while (< i len)
      (setq j (+ i (random (- len i))))
      (setq temp (aref vector i))
      (aset vector i (aref vector j))
      (aset vector j temp)
      (setq i (1+ i))
      ))
  vector)
;; Use: (shuffle-vector [0 1 2 3 4 5 6 7 8 9])

;; ---------------------------------------------------------------------------

(defun backup-pnw ()
  "Backup my stuff."
  (interactive)
  (compile "cd ~/pnw; ~/pnw/backup_pnw.sh")
  )

;; ---------------------------------------------------------------------------
;; List Operations

(defun sublist-alt (list from &optional to)
  "Return a sublist of LIST, from FROM to TO.
If END is omitted, it defaults to the length of the sequence.
Counting starts at 0. Like `subsequence' and `substring' but for
lists."
  (unless to (setq to (length list)))
  (let (rtn (c from))
    (setq list (nthcdr from list))
    (while (and list (< c to))
      (push (pop list) rtn)
      (setq c (1+ c)))
    (nreverse rtn)))

(defun sublist (list from &optional to)
  "Return a sublist of LIST, from FROM to TO.
If TO is omitted, it defaults to the length of the sequence.
Counting starts at 0. Like `subseq' and `substring' but solely
for lists."
  (let ((start (nthcdr from list)))     ;start reference
    (if to (butlast start
                    (- (+ from (length start)) ;if extract list at the end this makes it much faster
                       to))
      start)))
(defalias 'partial-list 'sublist)
;; Use: (sublist '(a b c) 0 0)
;; Use: (sublist '(a b c) 0 1)
;; Use: (sublist '(a b c) 1 2)
;; Use: (sublist '(a b c) 0 2)
;; Use: (sublist '(a b c) 0 3)
;; Use: (sublist '(a b c) 1 3)
;; Use: (sublist '(a b c) 2 3)

(defun nsublist (list from &optional to)
  "Like `sublist' but LIST is modified.
TODO Why is this function slower than `sublist'?"
  (let ((start (nthcdr from list)))     ;start reference
    (if to (nbutlast start
                     (- (+ from (length start)) ;if extract list at the end this makes it much faster
                        to))
      start)))
;; Use: (let ((dummy '(a b c d e))) (nsublist dummy 2 4))

(defun remove-from-list (list-var element)
  "Delete members of LIST-VAR which are `equal' to ELEMENT.
Opposite of `add-to-list'."
  (set list-var
       (delete element (symbol-value list-var))))
;; (remove-from-list 'compilation-error-regexp-alist 'd-backtrace)

;; ---------------------------------------------------------------------------

;; Use: (let ((l (make-list 1000 nil))) (benchmark-run 1000 (nreverse l)))
;; Use: (let ((l (make-list 1000 nil))) (benchmark-run 1000 (length l)))
;; Use: (let ((l (make-list 1000 nil))) (benchmark-run 1000 (sublist-alt l 250)))
;; Use: (let ((l (make-list 1000 nil))) (benchmark-run 1000 (sublist-alt l 250 750)))
;; Use: (let ((l (make-list 1000 nil))) (benchmark-run 1000 (sublist l 250)))
;; Use: (let ((l (make-list 1000 nil))) (benchmark-run 1000 (sublist l 250 750)))
;; Use: (let ((l (make-list 1000 nil))) (benchmark-run 1000 (sublist-alt l 250 1000)))
;; Use: (let ((l (make-list 1000 nil))) (benchmark-run 1000 (sublist l 250 1000)))
;; Use: (let ((l (make-list 1000 nil))) (benchmark-run 1000 (nsublist l 250 1000)))
;; Use: (let ((l (make-list 1000 nil))) (benchmark-run 1000 (subseq l 250 1000)))

(defalias 'make-buffer 'get-buffer-create)
(defalias 'load-buffer 'eval-buffer)

;; ---------------------------------------------------------------------------

(defalias 'make-bit-vector 'make-bool-vector)

(defalias 'bitwise-shift-left 'lsh)
(defalias 'arithmetic-shift-left 'ash)
(defalias 'bitwise-and 'logand) (defalias 'bitand 'logand)
(defalias 'bitwise-or 'logior) (defalias 'bitior 'logior) (defalias 'bitor 'logior)
(defalias 'bitwise-xor 'logxor) (defalias 'bitxor 'logxor)
(defalias 'bitwise-not 'lognot) (defalias 'bitnot 'lognot)

;; ---------------------------------------------------------------------------

(defalias 'call-function 'funcall)

(defalias 'break-on-entry 'debug-on-entry)
(defalias 'set-break-point-at-function 'debug-on-entry)

(defalias 'unrequire 'unload-feature)   ;naming consistency

;; ---------------------------------------------------------------------------
;; Frame Navigation

(defun x-focus-previous-frame ()
  "Set the input focus to previous frame."
  (interactive)
  (x-focus-frame (previous-frame)))

(defun x-focus-next-frame ()
  "Set the input focus to next frame."
  (interactive)
  (x-focus-frame (next-frame)))

;;(global-set-key [(control c) (control right)] 'x-focus-next-frame)
;;(global-set-key [(control c) (control left)] 'x-focus-previous-frame)

;; ---------------------------------------------------------------------------

;; TODO Fix this.
(defun font-existsp (font)
  "Return non-nil if the symbol FONT exists as a font."
  (when window-system
    (if (null (x-list-fonts font))
	nil t)))
;; Use: (font-existsp "shadow")
(font-existsp "font-lock-variable-name-face")
(fontp 'font-lock-variable-name-face)

;; ---------------------------------------------------------------------------

(defalias 'insert-unicode-char 'ucs-insert)

;; ---------------------------------------------------------------------------

(defalias 'set-key 'define-key)

(defun undefine-key (keymap key)
  "In KEYMAP, define key sequence KEY as DEF.
  KEYMAP is a keymap."
  (define-key keymap key nil))
(defalias 'remove-key 'undefine-key)
(defalias 'unset-key 'undefine-key)

;; ---------------------------------------------------------------------------

;; See: http://groups.google.se/group/gnu.emacs.help/browse_thread/thread/178e901350723b90
(defmacro inhibit-messages (&rest body)
  "Disabled messages temporarily and evaluation BODY. "
  `(flet ((message (&rest _)))
     ,@body))

;; ---------------------------------------------------------------------------

(defalias 'host-name 'system-name)

(defalias 'minibuffer-active 'minibufferp)

;; See also: http://irreal.org/blog/?p=3259
;; (defun make-random-tree (nodes)
;;   (let (tree)
;;     (do ((n 1 (1+ n)))
;;         ((= n nodes) (reverse tree))
;;       (push (list (random n) n) tree))))
;; (make-random-tree nodes)

(provide 'power-utils)
