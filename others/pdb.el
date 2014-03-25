;;; pdb.el --- Editing Protein Databank files  -*-coding: iso-2022-7bit;-*-

;; Copyright (C) 2001  Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>
;; Keywords: data
;; $Revision: 1.2 $

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; PDB mode is a major mode for editing Protein Databank (PDB) files
;; (according to the CCP4 definition of them).  It provides various
;; commands for transforming records in the file.  These mainly
;; operate on the (active) region; see the menu.

;; This requires Emacs 21.

;; Most of the commands are re-implemented from a mode by
;; C.S.Bond@dundee.ac.uk, often with the names rationalized and
;; behaviour somewhat changed.  That mode was originally
;; XEmacs-specific and I found it easiest to re-write rather than fix
;; it for Emacs, since I didn't follow a lot of the Lisp.  The result
;; is at least more compact and amenable to extension.  (See
;; `pdb-replace-atom-field', for instance.)  It tries to fit in with
;; Emacs conventions in user interface and implementation, but
;; illustrates the lack of some hooks (at least in Emacs 21.3),
;; e.g. for paragraph movement functions and commenting.

;; Tab stops are set up appropriately for the fields of the record
;; type around point so that TAB moves between the fields; it inserts
;; space only to extend the record to sufficient columns.  The current
;; field is highlighted (on capable terminals) and a description of it
;; appears in the mode line.

;; Navigation support is provided by Imenu and by treating chains as
;; `pages' and residues as `paragraphs' with the normal key bindings.

;; Font-lock isn't supported -- it's not clear how it would be useful,
;; except, perhaps to highlight records with detectable syntactic
;; problems, e.g. not long enough.

;; You might find `column-number-mode' useful with such fixed format
;; records, but it slows down redisplay.  `overwrite-mode' and
;; `transient-mark-mode' are probably useful too.

;; Note that column-oriented functions are used, disallowing
;; multi-column characters and tabs in the file (which aren't allowed
;; in PDB anyway, as far as I know).

;; Note the unrelated command `pdb' in gud.el, but there shouldn't be
;; scope for confusion.

;;; Code:

(eval-when-compile
  (defvar which-func-format))

(defgroup pdb ()
  "Editing Protein Databank files"
  :link '(emacs-commentary-link "pdb")
  :group 'data)

;;;; Defining columns and such

(eval-and-compile
  (defconst pdb-atom-record-regexp "^\\(?:ATOM  \\|HETATM\\)"
    "Regexp matching start of atom record."))

;; We may be able to display technical symbols.  It's not terribly
;; useful in this mode, but we try to Unicode on principle and
;; pedagogically.
(eval-and-compile
  (defvar pdb-alpha "alpha")
  (defvar pdb-beta "beta")
  (defvar pdb-gamma "gamma")
  (unless (fboundp 'char-displayable-p)	; future renaming
    (defalias 'char-displayable-p 'latin1-char-displayable-p)
    (require 'latin1-disp))
  (if (char-displayable-p ?$,1'1(B)
      (setq pdb-alpha "$,1'1(B"
	    pdb-beta "$,1'2(B"
	    pdb-gamma "$,1'3(B")
    (if (char-displayable-p ?,Fa(B)
	(setq pdb-alpha ",Fa(B"
	      pdb-beta ",Fb(B"
	      pdb-gamma ",Fc(B"))))

;; Definitions of records from CCP4 pdbformat.doc.  For each record
;; type we need the column boundaries and labels for the columns.
;; Note that columns in the doc are 1-based, but they're 0-based in
;; Emacs.

(eval-and-compile
(defconst pdb-column-defs
  `(("ATOM"
     (1 6 "AT/HET")			; Record name "ATOM  " or "HETATM"
     (7 11 "serial #")			; Atom serial number
     (13 14 "symbol")			; Chemical symbol (right justified)
     (15 15 "remoteness")		; Remoteness indicator
     (16 16 "branch")			; Branch designator
     (17 17 "alternate loc")		; Alternate location indicator
     (18 20 "residue name")		; Residue name
     (21 21 "reserved")			; Reserved
     (22 22 "chain")			; Chain identifier
     (23 26 "residue seq #")		; Residue sequence number
     (27 27 "insertion code")		; Code for inserting residue
     (31 38 "x")			; X
     (39 46 "y")			; Y Orthogonal Angstrom coordinates
     (47 54 "z")			; Z
     (55 60 "occupancy")		; Occupancy
     (61 66 "B")			; Isotropic B-factor
     (73 76 "seg id") ; Segment identifier, left justified (used by XPLOR)
     (77 78 "element")			; Element symbol, right justified
     (79 80 "charge")			; Charge on atom
     )

    ("HETATM"
     (1 6 "AT/HET")			; Record name "ATOM  " or "HETATM"
     (7 11 "serial #")			; Atom serial number
     (13 14 "symbol")			; Chemical symbol (right justified)
     (15 15 "remoteness")		; Remoteness indicator
     (16 16 "branch")			; Branch designator
     (17 17 "alternate loc")		; Alternate location indicator
     (18 20 "residue name")		; Residue name
     (21 21 "reserved")			; Reserved
     (22 22 "chain")			; Chain identifier
     (23 26 "residue seq #")		; Residue sequence number
     (27 30 "insertion code")		; Code for inserting residue
     (31 38 "x")			; X
     (39 46 "y")			; Y Orthogonal Angstrom coordinates
     (47 54 "z")			; Z
     (55 60 "occupancy")		; Occupancy
     (61 72 "B")			; Isotropic B-factor
     (73 76 "seg id") ; Segment identifier, left justified (used by XPLOR)
     (77 78 "element")		        ; Element symbol, right justified
     (79 80 "charge")			; Charge on atom
     )

    ("TER"
     (1 3 "TER")			; Record name "TER"
     (7 11 "serial #")			; Serial number
     (18 20 "residue")			; Residue name
     (21 27 "sequence id")		; Sequence identifier
     )

    ("CRYST1"
     (1 6 "CRYST")			; Record name "CRYST1"
     (7 15 "a")				; a
     (16 24 "b")			; b
     (25 33 "c")			; c
     (34 40 ,pdb-alpha)			; alpha
     (41 47 ,pdb-beta)			; beta
     (48 54 ,pdb-gamma)			; gamma
     (56 66 "SG")			; Space group symbol, left justified
     (67 70 "Z")			; Z
     )

    ("SCALE"
     (1 6 "SCALE")
     (11 20 "S1")
     (21 30 "S2")
     (31 40 "S3")
     (46 55 "U"))

    ("ANISOU"
     (1 6 "ANISOU")			; Record name "ANISOU"
     (7 11 "serial #")			; Atom serial number
     (13 16 "atom name")		; Atom name
     (17 17 "alt loc")			; Alternate location indicator
     (18 20 "residue name")		; Residue name
     (22 22 "chain")			; Chain identifier
     (23 26 "residue seq #")		; Residue sequence number
     (27 27 "insertion code")		; Insertion code
     (29 35 "U(1,1)")			; U(1,1)
     (36 42 "U(2,2)")			; U(2,2)
     (43 49 "U(3,3)")			; U(3,3)
     (50 56 "U(1,2)")			; U(1,2)
     (57 63 "U(1,3)")			; U(1,3)
     (64 70 "U(2,3)")			; U(2,3)
     (73 76 "segment id")	        ; Segment identifier, left-justified
     (77 78 "element")		        ; Element symbol, right-justified
     (79 80 "charge")			; Charge on the atom.
     )

    ("REMARK"
     (1 6 "remark")
     (8 80 "comment")))
  "Definitions of columns for PDB files.
This is a list of lists, one per record type.  The car of each element
is the name of the record type.  The cdr is a list (START END LABEL),
where START and END gives the 1-based, inclusive column range of the
field with the given LABEL."))

(eval-and-compile
  (defun pdb-column-of-1 (record-type field-name start)
    "Subroutine of `pdb-column-of'."
    (let ((type-record (cdr (assoc record-type pdb-column-defs)))
	  column)
      (dolist (elt type-record)
	(if (string= field-name (nth 2 elt))
	    (setq column (1- (nth (if start 0 1) elt)))))
      column)))

;; These two are macros to expand to constants at compile time in most
;; cases.  Not just eval-when-compile in case they're useful for
;; extensions.

(defmacro pdb-column-of (record-type field-name)
  "Return starting column of FIELD-NAME in the given RECORD-TYPE.
Args are strings exactly matching elements of `pdb-column-defs'."
  (if (and (stringp record-type) (stringp field-name))
      (pdb-column-of-1 record-type field-name t) ; compile-time constant
    `(pdb-column-of-1 ,record-type ,field-name t)))

(defmacro pdb-end-column-of (record-type field-name)
  "Return end column of FIELD-NAME in the given RECORD-TYPE.
Args are strings exactly matching elements of `pdb-column-defs'."
  (if (and (stringp record-type) (stringp field-name))
      (pdb-column-of-1 record-type field-name nil) ; compile-time constant
    `(pdb-column-of-1 ,record-type ,field-name nil)))

;; Macro so that column expressions eval to constants if possible.

(defmacro pdb-atom-field (field-name)
  "Return value of field FIELD-NAME in current record."
  `(buffer-substring (+ (line-beginning-position)
			(pdb-column-of "ATOM" ,field-name))
		     (+ (line-beginning-position) 1
			(pdb-end-column-of "ATOM" ,field-name))))

;; This would probably be useful in the Emacs core.
(eval-when-compile
  (defmacro pdb-with-restriction (beg end &rest forms)
    "Execute FORMS with region narrowed to BEG to END, point at BEG.
Save the restriction and excursion around this."
    `(save-restriction
       (narrow-to-region ,beg ,end)
       (save-excursion
	 (goto-char ,beg)
	 ,@forms))))

;; Make the column labels normally stand out better in the mode line
;; by adding faces to them.
(setq pdb-column-defs
      (mapcar
       (lambda (elt)
	 (mapcar (lambda (el)
		   (setcar (last el)
			   (propertize (car (last el)) 'face 'bold)))
		 (cdr elt))
	 (cons (propertize (pop elt) 'face 'bold) elt))
       pdb-column-defs))

(defconst pdb-tab-stop-alist
  (mapcar (lambda (elt)
	    (cons (car elt) (mapcar #'1- (mapcar #'car (cdr elt)))))
	  pdb-column-defs)
  "Internal use.")

;;;; Imenu

(defun pdb-strip-blanks (string)
  "Return STRING, less leading and trailing blanks."
  (string-match "\\` *\\(.*[^ ]\\)? *\\'" string)
  (or (match-string 1 string) ""))

(defun pdb-imenu-create-index-function ()
  (let (residues chains)
    (save-restriction
      (widen)
      ;; residues
      (goto-char (point-min))
      (re-search-forward pdb-atom-record-regexp nil t)
      (push (cons (pdb-strip-blanks (pdb-atom-field "residue name"))
		  (copy-marker (line-beginning-position)))
	    residues)
      (while (pdb-forward-residue)
	(if (looking-at pdb-atom-record-regexp)
	    (push (cons (pdb-strip-blanks (pdb-atom-field "residue name"))
			(copy-marker (line-beginning-position)))
		  residues)))
      ;; chains
      (goto-char (point-min))
      (re-search-forward pdb-atom-record-regexp nil t)
      (push (cons (pdb-strip-blanks (pdb-atom-field "seg id"))
		  (copy-marker (line-beginning-position)))
	    chains)
      (while (pdb-forward-chain)
	(if (looking-at "TER")
	    (forward-line))
	(if (looking-at pdb-atom-record-regexp)
	    (push (cons (pdb-strip-blanks (pdb-atom-field "seg id"))
			(copy-marker (line-beginning-position)))
		  chains)))
      (list (cons "Chains" (nreverse chains))
	    (cons "Residues" (nreverse residues))))))

;;;; Major mode and basic interactive stuff

(defvar pdb-mode-map
  (let ((map (make-sparse-keymap)))
    ;; We should be able to bind backtab to go back a stop, but
    ;; there's no currently-defined function to do that.
    (define-key map "\t" #'move-to-tab-stop)
    ;; Treat chains as `pages' and residues as `paragraphs'.  (This
    ;; would work better with hooks which aren't yet in Emacs.)
    (define-key map (or (where-is-internal 'mark-page global-map t)
			[?\C-x ?\C-p])
      #'pdb-mark-chain)
    (define-key map (or (where-is-internal 'mark-paragraph global-map t)
			[?\M-h])
      #'pdb-mark-residue)
    (define-key map (or (where-is-internal 'forward-paragraph global-map t)
			[?\M-}])
      #'pdb-forward-residue)
    (define-key map (or (where-is-internal 'backward-paragraph global-map t)
			[?\M-{])
      #'pdb-backward-residue)
    (define-key map (or (where-is-internal 'forward-page global-map t)
			[?\C-x ?\]])
      #'pdb-forward-chain)
    (define-key map (or (where-is-internal 'backward-page global-map t)
			[?\C-x ?\[])
      #'pdb-backward-chain)
    (define-key map "\C-c\C-r" #'pdb-right-justify)
    (easy-menu-define pdb-menu map ""
      '("PDB"
	"--" "Motion" "--"
	["Forward residue" pdb-forward-residue t]
	["Backward residue" pdb-backward-residue t]
	["Forward chain" pdb-forward-chain t]
	["Backward chain" pdb-backward-chain t]
	"--" "Set region" "--"
	["Select current chain" pdb-mark-chain t]
	["Select current residue" pdb-mark-residue t]
	"--" "Set values in region" "--"
	["Set alternate location" pdb-set-alternate :active mark-active]
	["Set B-factor" pdb-set-bfactor :active mark-active]
	["Set chain id" pdb-set-chain :active mark-active]
	["Set atom name" pdb-set-name :active mark-active]
	["Set occupancy" pdb-set-occupancy :active mark-active]
	["Set residue number" pdb-set-residue :active mark-active]
	["Set segment id" pdb-set-segid :active mark-active]
	["Set residue type" pdb-set-type :active mark-active]
	"--" "Modify values in region" "--"
	["Increment B-factor" pdb-increment-pdb-bfactor :active mark-active]
	["Add to residue number" pdb-increment-residue :active mark-active]
	["Translate atom poitions" pdb-increment-xyz :active mark-active]
	["Renumber consecutive atoms" pdb-renumber-atoms :active mark-active]
	"--" "Modify region" "--"
	["Change ATOM to HETATM" pdb-atom-to-hetatm :active mark-active]
	["Change HETATM to ATOM" pdb-hetatm-to-atom :active mark-active]
	["Reduce to CA only" pdb-remove-non-CA :active mark-active]
	["Remove hydrogens" pdb-dehydrogenate :active mark-active]
	["Reduce to poly-ALA/GLY" pdb-reduce-to-poly-ala :active mark-active]
	["Remove all but ATOM/HETATM" pdb-remove-non-atoms :active mark-active]
	"--"
	["Right-justify field" pdb-right-justify t]
	["Send region to viewer" pdb-view :active mark-active]))
    map))

(defvar pdb-box-overlay nil
  "Overlay used to highlight current field.")
(make-variable-buffer-local 'pdb-box-overlay)

(defcustom pdb-highlight-face 'underline
  "Face with which to highlight the current field."
  :type 'face
  :group 'pdb)

;; This could also adjust `header-line-format' to display an
;; indication of the fields, but the overlay and mode-line display is
;; probably good enough.  (See also Ponce's ruler-mode.el.)
;; We don't use which-func-mode, as we don't want to depend on the global
;; setting, we have to move the overlay anyhow, and this is fast enough
;; not to need the which-func timer.
(defun pdb-post-command-function ()
  "Update overlay and mode line indicator for current field.
Added to `post-command-hook'."
  (let* ((col (1+ (min 79 (current-column))))
	 (tag (save-excursion
		(beginning-of-line)
		;; Look at characters to avoid consing by `looking-at'
		;; and `match-string'.
		(let ((c (char-after)))
		  (cond ((eq ?A c)
			 (if (eq ?T (char-after (1+ (point))))
			     "ATOM"
			   (if (eq ?N (char-after (1+ (point))))
			       "ANISOU")))
			((eq ?H c) "HETATM")
			((eq ?T c) "TER")
			((eq ?C c) "CRYST1")
			((eq ?S c) "SCALE")
			((eq ?R c) "REMARK")))))
	 (fields (cdr (assoc tag pdb-column-defs)))
	 field spec)
    (dolist (spec fields)
      (if (and (>= col (car spec))
	       (<= col (cadr spec)))
	  (setq field spec)))
    (move-overlay pdb-box-overlay 0 0)
    (setq which-func-format nil)
    (if (null field)
	(setq which-func-format "")
      (setq tab-stop-list (cdr (assoc tag pdb-tab-stop-alist))
	    which-func-format (nth 2 field))
      (move-overlay pdb-box-overlay
		    (+ (line-beginning-position) (1- (car field)))
		    (min (+ (line-beginning-position)
			    (cadr field))
			 (line-end-position))))
    (force-mode-line-update)))

(defun pdb-insert-comment-function ()
  "`comment-insert-comment-function' for PDB mode.
Inserts a REMARK line before the current line."
  (beginning-of-line)
  (open-line 1)
  (insert comment-start))

(defun pdb-comment-region-function (beg end &optional arg)
  "`comment-region-function' for PDB mode.
Inserts `REMARK ' at the start of lines in the region."
  (setq end (min end (point-max)))
  (goto-char beg)
  (beginning-of-line)
  (while (< (point) end)
    (insert comment-start)
    (forward-line 1)))

(defun pdb-right-justify ()
  "Right-justify the contents of the current field relative to the column end."
  (interactive)
  (when (member pdb-box-overlay (overlays-at (point)))
    (let ((beg (overlay-start pdb-box-overlay))
	  (end (overlay-end pdb-box-overlay)))
      (pdb-with-restriction beg end
	(goto-char (point-max))
	(delete-horizontal-space)
	(goto-char (point-min))
	(insert-char ?\ (- end beg (- (point-max) (point-min))))
	(list end beg (point-min) (point-max))))))

(defun pdb-ensure-end ()
  "Ensure file has an END record.  For use in a `write-file' hook."
  (save-restriction
    (widen)
    (save-excursion
      (goto-char (point-max))
      ;; Check terminating newline first (like `require-final-newline').
      (unless (eq ?\n (char-before))
	(insert ?\n))
      (previous-line 1)
      (unless (looking-at "END *$")
	(next-line 1)
	(insert "END\n")))))

(define-derived-mode pdb-mode fundamental-mode "PDB"
  "Major mode for editing Protein Databank files.

Tab stops are set appropriately for the fields of the record type
around point so that TAB moves between the fields; it inserts
space only to extend the record to sufficient columns.  The
current field is normally highlighted (on capable terminals) and
a description of it appears in the mode line.

Chains are treated as `pages' and residues as `paragraphs' with
the normal key bindings.  REMARKs are treated as comments.

Consider also Transient Mark, Column Number, and Overwrite minor
modes.

\\{pdb-mode-map}"
  :group 'pdb
  ;; Abbrevs probably not useful.  No obvious reason to change syntax
  ;; table, though it might be worth making `.' say, symbol, for more
  ;; convenient motion across real numbers.
  (set (make-local-variable 'tab-stop-list)
       ;; Reset in post-command-hook appropriate to record type.
       (cdr (assoc "ATOM" pdb-tab-stop-alist)))
  (set (make-local-variable 'which-func-mode) t)
  ;; Reset in post-command-hook.
  (set (make-local-variable 'which-func-format) "")
  ;; Tabs not valid, and need to ensure char/column correspondence.
  (setq indent-tabs-mode nil)
  ;; Perhaps this could be a field?  Not clear that's terribly
  ;; helpful, but perhaps keeping text right-justified in it could be
  ;; useful.
  (unless (overlayp pdb-box-overlay)
    (setq pdb-box-overlay (make-overlay 0 0)))
  (overlay-put pdb-box-overlay 'face pdb-highlight-face)
  (set (make-local-variable 'imenu-create-index-function)
       #'pdb-imenu-create-index-function)
  ;; This allows M-; to comment-out a region in Emacs 21.3, but
  ;; doesn't do anything sensible otherwise.
  (setq comment-column 0)
  (set (make-local-variable 'comment-start) "REMARK ")
  ;; These two are only relevant post-Emacs 21.3.
  (set (make-local-variable 'comment-insert-comment-function)
       #'pdb-insert-comment-function)
  (set (make-local-variable 'comment-region-function)
       #'pdb-comment-region-function)
  (add-hook 'post-command-hook 'pdb-post-command-function nil t)
  (add-hook 'local-write-file-hooks 'pdb-ensure-end))

(custom-add-option 'pdb-mode-hook 'column-number-mode)

;;;; Operating over multiple records

;; This is the basic iterator over atom records which abstracts a lot
;; of the required behaviour.

(defun pdb-replace-atom-field (beg end field replacement)
  "Replace fields in atom records between BEG and END.
FIELD is the name of the field.  REPLACEMENT is a string with which to
replace the field or a function applied to the field to transform it
to a new string.  The replacement string is truncated to fit the field
and right justified if necessary."
  (pdb-with-restriction beg end
    (let* ((col1 (pdb-column-of "ATOM" field))
	   (col2 (pdb-end-column-of "ATOM" field))
	   (width (1+ (- col2 col1))))
      (while (re-search-forward pdb-atom-record-regexp nil t)
	;; Do nothing if record too short enough.
	(when (<= col2 (line-end-position))
	  (move-to-column col1)
	  ;; Generate appropriately-truncated replacement string.
	  (let ((str (truncate-string-to-width
		      (if (functionp replacement)
			  (funcall replacement
				   (buffer-substring (point) (+ (point)
								width)))
			replacement)
		      width)))
	    ;; Pad if necessary.
	    (if (< (length str) width)
		(insert-char ?\  (- width (length str))))
	    (insert str))
	  ;; Delete old contents after point.
	  (delete-char width))))))

(defun pdb-dehydrogenate (beg end)
  "Remove hydrogens in region."
  (interactive "r")
  (flush-lines (eval-when-compile
		 (format "%s.\\{%d\\} H" pdb-atom-record-regexp
			 (- (pdb-column-of "ATOM" "symbol") 6)))
	       beg end))

(defun pdb-remove-non-atoms (beg end)
  "Remove all non-atom records in region."
  (interactive "r")
  (keep-lines pdb-atom-record-regexp))

(defun pdb-remove-non-CA (beg end)
  "Remove non-CA atoms in region."
  (interactive "r")
  (keep-lines (format "^ATOM.\\{%d\\} CA"
		      (- (pdb-column-of "ATOM" "symbol") 4))))

(defun pdb-reduce-to-poly-ala (beg end)
  "Reduce atoms in region to poly-ALA (leave GLY alone)."
  (interactive "r")
  (pdb-replace-atom-field beg end "residue name" (lambda (str)
						   (if (string= str "GLY")
						       str
						     "ALA"))))

(defun pdb-hetatm-to-atom (beg end)
  "Convert HETATMs in region to ATOM."
  (interactive "r")
  (pdb-with-restriction beg end
    (while (re-search-forward "^HETATM" nil t)
      (replace-match "ATOM  "))))

(defun pdb-atom-to-hetatm (beg end)
  "Convert ATOMs in region to HETATM."
  (interactive "r")
  (pdb-with-restriction beg end
    (while (re-search-forward "^ATOM  " nil t)
      (replace-match "HETATM"))))

(defun pdb-set-bfactor (beg end b)
  "Set B-factor of all atoms in region to B."
  (interactive "r\nnNew B: ")
  (pdb-replace-atom-field beg end "B" (number-to-string b)))

(defun pdb-increment-bfactor (beg end inc)
  "Increment B-factor of all atoms in region by INC."
  (interactive "r\nnIncrement: ")
  (pdb-replace-atom-field beg end "B"
			  (lambda (str)
			    (format "%.2f" (+ (string-to-number str) inc)))))

(defun pdb-translate-atoms (beg end x+ y+ z+)
  "Translate all atoms in region by vector [X+ Y+ Z+]."
  (interactive "r\nnX increment: \nnY increment: \nnZ increment: ")
  (pdb-replace-atom-field beg end "x"
			  (lambda (str)
			    (format "%.3f" (+ x+ (string-to-number str)))))
  (pdb-replace-atom-field beg end "y"
			  (lambda (str)
			    (format "%.3f" (+ y+ (string-to-number str)))))
  (pdb-replace-atom-field beg end "z"
			  (lambda (str)
			    (format "%.3f" (+ z+ (string-to-number str))))))

(defun pdb-set-chain (beg end id)
  "Set chain id of all atoms in region to ID."
  (interactive "r\ncNew chain id: ")
  (pdb-replace-atom-field beg end "chain" (upcase id)))

(defun pdb-set-alternate (beg end id)
  "Set alternate convert id of all atoms in region to ID."
  (interactive "r\ncConformation id: ")
  (pdb-replace-atom-field beg end "alternate loc" (upcase id)))

(defun pdb-set-name (beg end name)
  "Set name of all atoms in region to NAME."
  (interactive "r\nsAtom name (4 chars, leading space if not metal): ")
  (if (/= 4 (length name))
      (error "Name not 4 characters: %s" name))
  (pdb-replace-atom-field beg end "symbol" (upcase name)))
(add-to-list 'debug-ignored-errors "Name not 4 characters: ")

(defun pdb-set-occupancy (beg end occ)
  "Set occupancy of all atoms in region to OCC."
  (interactive "r\nnOccupancy (1.0): ")
  (unless occ (setq occ 1.0))
  (pdb-replace-atom-field beg end "occupancy" (number-to-string occ)))

(defun pdb-set-residue (beg end res)
  "Set residue of all atoms in region to RES."
  (interactive "r\nnResidue: ")
  (pdb-replace-atom-field beg end "residue seq #" (upcase res)))

(defun pdb-set-segid (beg end id)
  "Set segment id of all atoms in region to ID."
  (interactive "r\nsSegment id (current id): ")
  (unless id (setq id (pdb-atom-field "seg id")))
  (pdb-replace-atom-field beg end "seg id" (upcase id)))

(defun pdb-set-type (beg end type)
  "Set residue type of all atoms in region to TYPE."
  (interactive "r\nsResidue type: ")
  (pdb-replace-atom-field beg end "residue name" (upcase type)))

(defun pdb-renumber-atoms (beg end start)
  "Renumber atoms in region in sequence from START."
  (interactive "r\nnRenumber starting from: ")
  (pdb-replace-atom-field beg end "serial #" (lambda (str)
					       (prog1 (format "%d" start)
						 (setq start (1+ start))))))

;;;; Viewing

(defcustom pdb-viewer-command "rasmol -pdb %s"
  "Shell command template to view pdb file.
Must contain a field `%s' with which the file name is replaced.  Any other
`%' in the command must be written as `%%'."
  :type 'string
  :group 'pdb)

(defun pdb-view (beg end)
  "View atoms in region graphically with `pdb-viewer-command'."
  (interactive "r")
  (save-excursion
    (goto-char beg)
    (unless (bolp) (error "Incomplete records in region"))
    (goto-char end)
    (unless (eolp) (error "Incomplete records in region")))
  (let ((temp-file (make-temp-file "pdb")))
    (write-region beg end temp-file)
    (let ((proc (start-process-shell-command "PDB viewer" nil
					     (format pdb-viewer-command
						     temp-file))))
      ;; Clean up afterwards.
      (set-process-sentinel proc `(lambda (proc string)
				    (delete-file ,temp-file))))))
(add-to-list 'debug-ignored-errors "Incomplete records in region")

;;;; Movement and marking

(defun pdb-forward-chain (&optional arg)
  "Move point to start of the next chain.
With arg, move forward that many chains.
Return non-nil iff point moved to a different record."
  (interactive "p")
  (unless arg (setq arg 1))
  (let ((initial (line-beginning-position)))
    (dotimes (i (abs arg))
      (if (and (< arg 1)
	       (looking-at pdb-atom-record-regexp))
	  (forward-line -1))
      (if (> arg 0)
	  (re-search-forward pdb-atom-record-regexp nil t)
	(if (< arg 0)
	    (re-search-backward pdb-atom-record-regexp nil t)))
      (let* ((chain (save-excursion
		      (beginning-of-line)
		      (and (looking-at pdb-atom-record-regexp)
			   (pdb-atom-field "chain"))))
	     (search
	      (and chain (format "%s.\\{%d\\}%s" pdb-atom-record-regexp
				 (eval-when-compile
				   (- (pdb-column-of "ATOM" "chain") 6))
				 ;; Shouldn't need regexp-quote.
				 chain))))
	(end-of-line)
	(cond ((null search))
	      ((> arg 0)
	       (while (re-search-forward search nil t)
		 t)
	       (beginning-of-line 2))
	      ((< arg 0)
	       (while (re-search-backward search nil t)
		 (beginning-of-line))))))
    (/= initial (line-beginning-position))))

(defun pdb-backward-chain (&optional arg)
  "Move point to start of the previous chain.
With arg, move backward that many chains."
  (interactive "p")
  (unless arg (setq arg 1))
  (pdb-forward-chain (- arg)))

(defun pdb-mark-chain ()
  "Mark the current chain."
  (interactive)
  (pdb-forward-chain)
  (push-mark nil t t)
  (pdb-forward-chain -1))

(defun pdb-forward-residue (&optional arg)
  "Move point to start of the next residue.
With arg, move forward that many residues.
Return nil iff point moved to a different record."
  (interactive "p")
  (unless arg (setq arg 1))
  (let ((initial (line-beginning-position)))
    (dotimes (i (abs arg))
      (if (and (< arg 1)
	       (looking-at pdb-atom-record-regexp))
	  (forward-line -1))
      (if (> arg 0)
	  (re-search-forward pdb-atom-record-regexp nil t)
	(if (< arg 0)
	    (re-search-backward pdb-atom-record-regexp nil t)))
      (let* ((residue (save-excursion
			(beginning-of-line)
			(and (looking-at pdb-atom-record-regexp)
			     (pdb-atom-field "residue name"))))
	     (seq (and residue (pdb-atom-field "residue seq #")))
	     (search
	      (and residue
		   ;; Shouldn't need regexp-quote for residue or seq.
		   (format "%s.\\{%d\\}%s.\\{%d\\}%s" pdb-atom-record-regexp
			   (eval-when-compile
			     (- (pdb-column-of "ATOM" "residue name") 6))
			   residue
			   (eval-when-compile
			     (- (pdb-column-of "ATOM" "residue seq #")
				(pdb-end-column-of "ATOM" "residue name")
				1))
			   seq)))
	     start)
	(end-of-line)
	(cond ((null search))
	      ((> arg 0)
	       (while (re-search-forward search nil t) nil)
	       (beginning-of-line 2))
	      ((< arg 0)
	       (while (re-search-backward search nil t)
		 (beginning-of-line))))))
    (/= initial (line-beginning-position))))

(defun pdb-backward-residue (&optional arg)
  "Move point to start of the previous residue.
With arg, move backward that many residues."
  (interactive "p")
  (unless arg (setq arg 1))
  (pdb-forward-residue (- arg)))

(defun pdb-mark-residue ()
  "Mark the current residue."
  (interactive)
  (pdb-forward-residue)
  (push-mark nil t t)
  (pdb-forward-residue -1))

(provide 'pdb)

;; Local variables:
;; eval: '(dolist (elt '(pdb-end-column-of pdb-column-of pdb-with-restriction)) (put elt 'lisp-indent-function 2) (put elt 'edebug-form-spec t))
;; eval: '(progn (put 'pdb-atom-field 'lisp-indent-function 1) (put 'pdb-atom-field 'edebug-form-spec t))
;; End:

;;; pdb.el ends here
