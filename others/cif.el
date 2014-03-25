;;; cif.el --- major mode for editing (mm?)CIF files

;; Copyright (C) 1999, 2003 Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Has a superset (roughly) of the useful functionality of a version
;; done by Martyn Winn.  This is a completely different implementation
;; which is more Emacs-canonical in interface and implementation, is
;; simpler, and is GPLed.

;; Functionality: Font Lock, Imenu, Which Function, loops and data
;; blocks as functions, skeleton commands.  Potentially useful for
;; dictionaries too, since it also supports save_ stuff.  Also examples
;; of transformation commands similar to the PDB versions.

;; Probably requires Emacs 21.  Needs font-lock on to deal properly
;; with the syntax.

;; Consider in .emacs:
;;   (add-to-list 'auto-mode-alist '("\\.cif\\'" . cif-mode))
;;   (autoload 'cif-mode "cif")

;; etags recipe for dictionary:  etags -r '/save_\([^ ]+\)/\1/' ...

;;; Code:

(defgroup cif ()
  "Editing CIF crystallographic data files"
  :group 'data)

(defconst cif-mode-syntax-table
  (let ((table (make-syntax-table))
	(c (1+ ? )))
    ;; First set initially non-space, non-word ASCII characters to
    ;; symbol constituents, then modify a few.  This allows moving
    ;; word-wise within names, with sexp-wise movement going over the
    ;; whole name.  However, it doesn't provide matching of `[' and
    ;; `]' within names, for instance.
    (while (< c 128)
      (unless (eq ?w (char-syntax c))
	(modify-syntax-entry c "_" table))
      (setq c (1+ c)))
    ;; Loses with `;' not at start of line, but that is fixed up with
    ;; syntactic font lock if we use font lock:
    (modify-syntax-entry ?\; "\"" table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    table))

;; We do syntactic font-locking -- see `font-lock-defaults' below.
;; Perhaps we don't really want strings highlighted, but it's
;; potentially useful to be able to spot the inside and outside of the
;; losing semi-colon-delimited stuff; see also `cif-fontify-strings'.
;; This also maintains syntax properties, allowing us to treat `;'
;; correctly when it's not at the start of a line.  (We lose
;; otherwise.)

;; Draw your own conclusions about the CIF syntax from this.  (I
;; originally drew them from trying to specify it formally.)

;; For font-lock purposes, we're mainly interested in non-whitespace
;; runs of characters (apart from comments and strings).  It's
;; convenient to treat nearly everything as having word syntax,
;; simplifying the keywords definition below.

(defconst cif-font-lock-syntax-table
  (let ((table (copy-syntax-table cif-mode-syntax-table))
	(c (1+ ? )))
    (with-syntax-table cif-mode-syntax-table
      ;; Give all non-special characters word syntax.
      (while (< c 128)
	(if (eq ?_ (char-syntax c))
	    (modify-syntax-entry c "w" table))
	(setq c (1+ c))))
    table))

;; font-lock-variable-name-face isn't really appropriate here, but the
;; default appearance is sufficiently distinctive.
(defconst cif-font-lock-keywords
  '("\\<loop_\\>"
    ;; Perhaps this should only be done anchored on loop_.
    ("\\<_\\sw+" . font-lock-type-face)
    ("\\<data_\\sw+" . font-lock-variable-name-face)
    ;; only relevant for dictionaries
    ("\\<save_\\sw+" . font-lock-variable-name-face)
    "\\<save_\\>"))

;; See `imenu-syntax-alist' below.
(defconst cif-imenu-generic-expression
  ;; Loses in comment or string; oh well...
  '((nil "\\<_\\([^ \t\n]+\\)" 1)))

(defvar cif-mode-map
  (let ((map (make-sparse-keymap))
	(menu (make-sparse-keymap "CIF")))
    (define-key map "\C-c\C-d" 'cif-data-block)
    (define-key map "\C-c\C-l" 'cif-loop)
    (define-key map "\C-c\C-s" 'cif-search-dictionary)

    (define-key map [menu-bar cif] (cons "CIF" menu))
    (define-key-after menu [cif-loop-end]
      '(menu-item "Go to end of loop" end-of-defun
		  :enable (cif-data-item-name)))
    (define-key-after menu [cif-loop-start]
      '(menu-item "Goto start of loop" beginning-of-defun
		  :enable (cif-data-item-name)))
    (define-key-after menu [cif-data-item-name]
      '(menu-item "Item name" cif-data-item-name
		  :enable (cif-data-item-name) :help "Name of loop item"))
    (define-key-after menu [cif-data-block]
      '(menu-item "New data block" cif-data-block :help "Insert new block"))
    (define-key-after menu [cif-loop]
      '(menu-item "New loop" cif-loop :help "Insert new loop"))
    (define-key-after menu [deh]
      '(menu-item "Dehydrogenate" cif-dehydrogenate
		  :help "Remove hydrogens in region" :enable mark-active))
    (define-key-after menu [setb]
      '(menu-item "Set B" cif-set-bfactor :help "Set B factor in region"
		  :enable mark-active))
    (define-key-after menu [incb]
      '(menu-item "Increment B" cif-increment-bfactor
		  :help "Increment B factor in region"
		  :enable mark-active))
    (define-key-after menu [bchain]
      '(menu-item "Beginning of chain" cif-beginning-of-chain
		  :help "Go to beginning of current chain"))
    (define-key-after menu [echain]
      '(menu-item "End of chain" cif-end-of-chain
		  :help "Go to end of current chain"))
    (define-key-after menu [cif-electric]
      '(menu-item "Toggle electric strings"
		  (lambda ()
		    (interactive)
		    (cif-toggle-electric nil (not cif-electric-strings)))
		  :button (:toggle . cif-electric-strings)
		  :help "Whether string delimiters insert pairs"))
    map))

(defcustom cif-fontify-strings t
  "Non-nil means fontify strings as such.
Otherwise give them the default face."
  :type 'boolean
  :group 'cif)

;; For editing contents of strings and comments, it's convenient to
;; have more normal syntax.
(defun cif-font-lock-syntactic-face-function (state)
  "`font-lock-syntactic-face-function' for CIF mode.
Returns the string or comment face as usual, with side effect of putting
a `syntax-table' property on the inside of the string or comment which is
the standard syntax table."
  (if (nth 3 state)
      (save-excursion
	(goto-char (nth 8 state))
	(condition-case nil
	    (forward-sexp)
	  (error nil))
	(put-text-property (1+ (nth 8 state)) (1- (point))
			   'syntax-table (standard-syntax-table))
	(if cif-fontify-strings
	    'font-lock-string-face
	  nil))
    (put-text-property (1+ (nth 8 state)) (line-end-position)
			   'syntax-table (standard-syntax-table))
    'font-lock-comment-face))

(define-derived-mode cif-mode fundamental-mode "CIF"
  "Major mode for editing CIF files.

Loops and data blocks are treated as functions by \\[beginning-of-defun] and \\[end-of-defun] etc.
Supports Imenu and Which Function mode.
Requires Font Lock mode turned on to work properly.

To make tags from the dictionary, use:  etags -r '/save_\([^ ]+\)/\1/' ...

\\{cif-mode-map} (May be modified by `cif-electric-strings'.)"
  :group 'cif
  (set (make-local-variable 'font-lock-defaults)
       `(cif-font-lock-keywords nil nil nil nil
	 ;; Deal with losing multi-line string stuff.  Give real
	 ;; deliminators correct syntax property (generic string
	 ;; delimiter).  Also give semis which aren't such delimiters
	 ;; non-quote syntax, though I don't think that ever matters.
	 (font-lock-syntactic-keywords . (("^;" 0 "|") ("[^\n];" 0 "_")))
	 (font-lock-syntax-table . ,cif-font-lock-syntax-table)
	 (font-lock-syntactic-face-function
	  . cif-font-lock-syntactic-face-function)))
  (set (make-local-variable 'beginning-of-defun-function)
       #'cif-beginning-of-defun)
  (set (make-local-variable 'end-of-defun-function) #'cif-end-of-defun)
  (set (make-local-variable 'imenu-generic-expression)
       cif-imenu-generic-expression)
  (set (make-local-variable 'imenu-syntax-alist) '(("_." . "w")))
  (put 'cif-mode 'find-tag-default-function 'cif-find-tag-default-function)
  ;; For correct sexp motion over `; ... ;':
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'skeleton-pair-alist) '((?\" _ ?\") (?\; _ ?\;)))
  (set (make-local-variable 'skeleton-pair) t)
  (set (make-local-variable 'which-func-functions) '(cif-data-item-name))
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'which-func-mode) t))

(defun cif-toggle-electric (junk on)
  "Turn on CIF electric strings if ON is non-nil.
Else turn them off.  JUNK is ignored."
  (setq-default cif-electric-strings on)
  ;; Note that the behaviour of `skeleton-pair-insert-maybe' could be
  ;; controlled by `skeleton-pair', but not `cif-multiline-string'.
  (if on
      (progn
	(define-key cif-mode-map "'" 'skeleton-pair-insert-maybe)
	(define-key cif-mode-map "\"" 'skeleton-pair-insert-maybe)
	(define-key cif-mode-map "\;" 'cif-multiline-string))
    (define-key cif-mode-map "'" 'self-insert-command)
    (define-key cif-mode-map "\"" 'self-insert-command)
    (define-key cif-mode-map "\;" 'self-insert-command)))

(defcustom cif-electric-strings nil
  "Non-nil means quotes and semicolons are electric.
This means they insert a delimiter pair rather than being self-inserting."
  :type 'boolean
  :set #'cif-toggle-electric
  :group 'cif)

;;;; Utility stuff

(defun cif-in-comment-or-string ()
  "Return start of enclosing string or comment.
Return nil if not in string or comment."
  (if (featurep 'syntax)
      (nth 8 (syntax-ppss))
    (save-excursion
      (save-restriction
	(widen)
	;; We'll rely on syntactic font-lock to update properties
	;; rather than have parse-partial-sexp start from point-min.
	(if (> (point) font-lock-syntactically-fontified)
	    (font-lock-fontify-syntactically-region
	     font-lock-syntactically-fontified (line-end-position)))
	(and (memq (get-text-property (point) 'face)
		   '(font-lock-comment-face font-lock-string-face))
	     (or (previous-single-property-change (point) 'face)
		 (point-min)))))))

(defconst cif-star-keyword-re
  "\\<\\(?:\\(loop_\\)\\|data_\\sw+\\|save_\\sw*\\)"
  "Regexp to match a STAR keyword.
Assumes `cif-font-lock-syntax-table' is in force.")

(defconst cif-beginning-of-defun-re
  "\\<\\(?:loop_\\|data_\\sw+\\|save_\\sw+\\)"
  "Regexp to match a STAR keyword marking beginning of a `defun'.
Assumes `cif-font-lock-syntax-table' is in force.")

(defun cif-forward-items (n)
  "Skip N items (sexps) forward plus all following whitespace and comments."
  (forward-sexp n)
  (if (> n 0)
      (forward-comment (point-max)))) ; skip multiple comments/whitespace

(defun cif-loop-data ()
  "Return non-nil if point is in CIF loop.
If non-nil, the value returned is a list (START NITEMS NDATA), where:
 START is the position of the start of the loop_ keyword;
 NITEMS is the number of items in the loop;
 NDATA is the number of data in the loop up to point."
  (save-excursion
    (save-restriction
      (widen)
      (with-syntax-table cif-font-lock-syntax-table
	(let ((case-fold-search t)
	      (comment-or-string (cif-in-comment-or-string))
	      (count 0)
	      (loop-count 0)
	      old-point start)
	  (if comment-or-string
	      (goto-char comment-or-string))
	  ;; If at start of symbol step into it so it gets included.
	  (if (looking-at "\\<")
	      (forward-char))
	  (setq old-point (point))
	  ;; Look back for a loop_
	  (while (and (not (bobp))
		      (re-search-backward "\\<loop_\\>" nil 'move)
		      (cif-in-comment-or-string))
	    t)
	  ;; Note that forward-sexp should be safe if we make sure we're
	  ;; outside strings -- we don't have open/close syntax.
	  (when (and (looking-at "loop_") (not (bobp)))
	    (setq start (match-beginning 0))
	    (forward-sexp 1)
	    ;; Forward over `loop-count' item names.
	    (while (and (not (eobp))
			(progn
			  (forward-sexp)
			  (save-excursion
			    ;; beginning of word before point
			    (re-search-backward "\\<_\\sw+\\=" nil t))))
	      (setq loop-count (1+ loop-count)))
	    (unless (eobp)
	      (backward-sexp))
	    (save-restriction
	      (narrow-to-region (point) old-point)
	      (while (not (eobp))
		(cif-forward-items 1) ; skip all comments and whitespace
		(setq count (1+ count))))
	    (if comment-or-string (setq count (1+ count)))
	    (list start loop-count count)))))))

;;;; Commands

(defun cif-number-of-loop-items ()
  "Print the number of data items in the current loop."
  (interactive)
  (let ((data (cif-loop-data)))
    (if data
	(message "Number of data items in loop: %d" (nth 1 data))
      (error "Not in a loop"))))

(defun cif-data-item-name ()
  "Print loop item name for value at or before point.
Non-interactively, just return the name."
  (interactive)
  (let* ((data (cif-loop-data))
	 (items (and data (nth 1 data)))
	 (values (and data (nth 2 data)))
	 (item-no (and data (1+ (mod (1- values) items))))
	 end)
    (if (and values (> values 0))
	(let ((name (save-excursion
		      (goto-char (car data))
		      (forward-sexp (1+ item-no))
		      (setq end (point))
		      (backward-sexp)
		      (buffer-substring-no-properties (point) end))))
	  (if (interactive-p)
	      (message "Item name: %s" name)
	    name))
      (if (interactive-p)
	  (error "Not in a loop body")))))

(defun cif-find-tag-default-function ()
  "`find-tag-default-function' for CIF.
Return the symbol at point if it starts with `_'.  Otherwise
return the name of the loop item corresponding to the position in
any enclosing loop."
  (let ((item (current-word)))
    (if item (setq item (symbol-name item)))
    (if (and item (eq ?_ (aref item 0)))
	item
      (condition-case nil
	  (cif-data-item-name)
	(error nil)))))

(defun cif-beginning-of-defun ()
  "Move backward to the beginning of the current CIF item or loop."
  (interactive)
  (with-syntax-table cif-font-lock-syntax-table
    ;; In case we're on the relevant keyword, but not right at the
    ;; beginning.  Allows continually movement backwards with C-M-a.
    (if (and (eq ?w (char-syntax (following-char)))
	     (eq ?w (char-syntax (preceding-char))))
	(forward-sexp))
    (re-search-backward cif-beginning-of-defun-re nil 'move) ; probable start
    (while (and (not (bobp)) (cif-in-comment-or-string)) ; iterate if necessary
      (re-search-backward cif-beginning-of-defun-re nil 'move))))

(defun cif-end-of-defun ()
  "Move forward to the end of the current CIF item or loop."
  (interactive)
  (if (and (not (looking-at cif-beginning-of-defun-re))
	   (not (cif-loop-data)))
      (cif-beginning-of-defun))
  (with-syntax-table cif-font-lock-syntax-table
    (cond ((looking-at "data")	 ; terminated by another `data' or end
	   (forward-sexp)
	   (re-search-forward "\\<data_" nil 'move)
	   (while (and (not (eobp))
		       (or (match-beginning 0)
			   (cif-in-comment-or-string)))
	     (re-search-forward "\\<data_" nil 'move)))
	  ((looking-at "save")		; terminated by `save_'
	   (forward-sexp)
	   (re-search-forward "\\<save_\\>" nil 'move)
	   (while (and (not (eobp))
		       (or (match-beginning 0)
			   (cif-in-comment-or-string)))
	     (re-search-forward "\\<save_" nil 'move)))
	  (t		       ; otherwise loop, terminated by keyword
	   (forward-sexp)
	   (when (cif-loop-data)
	     (re-search-forward cif-star-keyword-re nil 'move)
	     (while (and (not (eobp))	; iterate if necessary
			 (cif-in-comment-or-string))
	       (re-search-forward cif-star-keyword-re nil 'move))))))
  (unless (eobp)
    (goto-char (match-beginning 0))))

(defvar cif-dictionary-file nil
  "Filename of dictionary for this CIF file.
This variable is automatically buffer-local.")
(make-variable-buffer-local 'cif-dictionary-file)

(defun cif-search-dictionary (name)
  "Search dictionary for category/item NAME.
Can be used in the absence of a TAGS file for the
dictionary.  (Etags is the preferred mechanism)."
  (interactive
   (let ((n (condition-case nil
		(cif-data-item-name)
	      (error (thing-at-point 'symbol))))
	 (enable-recursive-minibuffers t))
     (setq n (read-string (format "Category/item name? (default %s) " n)
			  nil nil n))
     (list n)))
    (if cif-dictionary-file
	(cif-visit-dictionary cif-dictionary-file)
      (call-interactively #'cif-visit-dictionary))
    (let ((case-fold-search t))
      (goto-char (point-min))
      (unless (re-search-forward (concat "\\<save_" (regexp-quote name) "\\>")
				 nil 'move)
	(error "Item not found: %s" name))))

(defun cif-visit-dictionary (file)
  "Visit and select buffer for CIF dictionary in FILE."
  (interactive (list (read-file-name "Dictionary file name: " nil
				     cif-dictionary-file)))
  (setq cif-dictionary-file file)
  (find-file-other-window file)
  (cif-mode)
  (current-buffer))

;;;; Statement skeletons

(define-skeleton cif-multiline-string
  "Insert semi-colon-delimited string."
  nil "\n;" _ "\n;")

(define-skeleton cif-loop
  "Start a new loop."
  nil "\nloop_\n")

(define-skeleton cif-data-block
  "Start a new data block."
  "Name of block: " "\ndata_" str "\n\n" _ )

;;;; Operations, including chain movement

;; Just some examples, mostly easily extended following pdb.el.  This is
;; obviously more awkward than the PDB versions.  The obvious way to do
;; it would be to make a list of atom record vectors, transform it, and
;; format the result in place of the original, but that wouldn't
;; preserve (more-or-less) the layout for one thing.

(defun cif-atom_site-items (&optional data)
  "Return alist of (ITEM-NAME . NUMBER) for _atom_site loop.
DATA is as returned by `cif-loop-data'.  NUMBER is the position
of the item _atom_site.ITEM-NAME in each atom record, (0-based)."
  (unless data (setq data (cif-loop-data)))
  (save-excursion
    (let (alist)
      (goto-char (car data))
      (forward-sexp)			; skip loop_
      (dotimes (i (cadr data))
	(forward-sexp)
	(let ((word (downcase (current-word))))
	  (unless (string-match "\\`_atom_site.\\(.+\\)\\'" word)
	    (error "Not in (correct) atom_site loop"))
	  (push (cons (match-string 1 word) i) alist)))
      (nreverse alist))))

(defun cif-start-of-loop-data (data)
  "Go to start of first item in loop and return point.
DATA is as returned by `cif-loop-data'."
  (goto-char (car data))
  (cif-forward-items (1+ (cadr data)))
  (point))

(defun cif-start-of-atom-record (&optional data)
  "Go to start of first item in current atom record.
Goto start of first record if point is before it.  DATA is as
returned by `cif-loop-data'."
  (unless data (setq data (cif-loop-data)))
  (let* ((nitems (nth 1 data))
	 (string-start (cif-in-comment-or-string)))
    ;; Ensure we can back up to start of item.
    (if (looking-at "\\sw\\|\\s_")
	(goto-char (1+ (point))))
    (when string-start
      (goto-char string-start)
      (let ((parse-sexp-ignore-comments nil))
	(forward-sexp)))
    ;; Now position correctly.
    (if (zerop (nth 2 data))
	(cif-start-of-loop-data data)
      (if (zerop (% (nth 2 data) nitems)) ; at end of record
	  (backward-sexp nitems)
	(backward-sexp (% (nth 2 data) nitems))))))

(defun cif-field-number (field alist)
  "Return the position of FIELD in the atom record.
ALIST is as returned by `cif-atom_site-items'."
  (or (cdr (assoc field alist))
      (error "Item %s not in atom_site records")))

(defun cif-replace-atom-field (beg end field replacement)
  "Replace items in _atom_site records between BEG and END.
FIELD is the downcased name of the field, e.g. \"type_symbol\".
REPLACEMENT is a string with which to replace the item, or a
function to transform it to a the replacement."
  (save-excursion
    (goto-char beg)
    (condition-case error-data
	(let* ((data (cif-loop-data))
	       (nitems (nth 1 data))
	       (alist (cif-atom_site-items data)))
	  (cif-start-of-atom-record data)
	  ;; Start of first potentially-relevant field.
	  (cif-forward-items (cif-field-number))
	  ;; Start of first relevant field after BEG.
	  (when (< (point) beg)
	    (cif-forward-items nitems))
	  (while (and (< (point) end) (not (eobp)))
	    (kill-sexp)
	    (insert (if (functionp replacement)
			(funcall replacement (current-word))
		      replacement))
	    (cif-forward-items (1- nitems))))
      (scan-error (error "Bad syntax around char %d"(nth 2 error-data))))))

(defun cif-next-atom-record (&optional n data)
  "Go to start of next record.
If N is non-nil move that many records.  DATA is as returned by
`cif-loop-data'."
  (interactive "p")
  (unless data (setq data (cif-loop-data)))
  (cif-start-of-atom-record data)
  (unless n (setq n 1))
  (if (< n 0)
      (dotimes (i (- n))
	(backward-sexp (cadr data)))
    (dotimes (i n)
      (cif-forward-items (cadr data)))))

(defun cif-dehydrogenate (beg end)
  "Remove hydrogen records in the region."
  (interactive "r")
  (save-excursion
    (goto-char beg)
    (let* ((data (cif-loop-data))
	   (start (progn (cif-start-of-atom-record (cif-loop-data))
			 (point)))
	   (alist (cif-atom_site-items data))
	   (item (cif-field-number "type_symbol" alist)))
      (while (and (not (eobp)) (< (point) beg))
	(cif-forward-items item)
	(if (looking-at "H\\>")
	    (progn (cif-next-atom-record nil data)
		   (delete-region start (point)))
	  (cif-next-atom-record nil data))))))

(defun cif-set-bfactor (beg end b)
  "Set B-factor of all atoms in region to B."
  (interactive "r\nnNew B: ")
  (cif-replace-atom-field beg end "b_iso_or_equiv" (number-to-string b)))

(defun cif-increment-bfactor (beg end inc)
  "Increment B-factor of all atoms in region by INC."
  (interactive "r\nnIncrement: ")
  (cif-replace-atom-field beg end "b_iso_or_equiv"
			  (lambda (str)
			    (format "%.2f" (+ (string-to-number str) inc)))))

(defun cif-field-value (field &optional alist data)
  "Return the value of the FIELD in current atom record.
Point must be at the first item of the record.  ALIST and DATA
are values as returned by `cif-atom_site-items' and
`cif-loop-data' at point."
  (save-excursion
    (unless alist (setq alist (cif-atom_site-items data)))
    (cif-forward-items (cif-field-number field alist))
    (current-word)))

(defun cif-field-value-p (field test &optional alist data)
  "Return non-nil if FIELD in current atom record satisfies TEST.
If TEST is a string, it is used as a regexp match for the field;
otherwise it must be a function of no args called with point at
the start of the field to return the correct value.  Point must
be at the first item of the record.  ALIST and DATA are values as
returned by `cif-atom_site-items' and `cif-loop-data' at point."
  (save-excursion
    (unless alist (setq alist (cif-atom_site-items data)))
    (cif-forward-items (cif-field-number field alist))
    (if (stringp test)
	(looking-at test)
      (funcall test))))

(defun cif-beginning-of-chain ()
  "Go to the beginning of the current _atom_site chain."
  (interactive)
  (let* ((data (cif-loop-data))
	 (nitems (nth 1 data))
	 (alist (cif-atom_site-items data))
	 (_ (cif-start-of-atom-record data))
	 ;; regexp-quote should actually be redundant
	 (chain (regexp-quote (cif-field-value "label_asym_id" nil data)))
	 (start (save-excursion (cif-start-of-loop-data data))))
    (while (and (> (point) start)
		(cif-field-value-p "label_asym_id" chain alist data))
      (forward-sexp (- nitems)))
    (unless (cif-field-value-p "label_asym_id" chain alist)
      (forward-sexp nitems))))

(defun cif-end-of-chain ()
  "Go to the beginning of the current _atom_site chain."
  (interactive)
  (let* ((data (cif-loop-data))
	 (nitems (nth 1 data))
	 (alist (cif-atom_site-items data))
	 (_ (cif-start-of-atom-record data))
	 ;; regexp-quote should actually be redundant
	 (chain (regexp-quote (cif-field-value "label_asym_id" nil data))))
    (while (and (not (eobp))
		(cif-field-value-p "label_asym_id" chain alist data))
      (cif-forward-items nitems))))

(provide 'cif)

;;; cif.el ends here
