;;; autocap.el --- auto-capitalize beginning of sentences

;; Copyright (C) 2002  Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>
;; Keywords: convenience, abbrev, wp
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

;; auto-capitalize-mode attempts to capitalize (only) the beginning of
;; sentences.  It uses the abbrev expansion hook.  You probably want to
;; put it on `text-mode-hook', i.e.
;;    (add-hook 'text-mode-hook 'auto-capitalize-mode)
;; or via Custom.

;; Defining specific abbrevs can help too, and this file defines a
;; couple of useful hook functions, e.g.:
;;  (define-abbrev-table 'text-mode-abbrev-table
;;      ("i'm" "I'm")  ; ... egocentric
;;      ("i've" "I've")
;;      ("i'd" "I'd")
;;      ("i'll" "I'll")
;;      ("i" "I" autocap-not-at-stop)  ; not, e.g. in `i.e.'
;;      ("emacs" "Emacs" autocap-delimited))) ; arbitrary example

;; Normal abbrevs expanded at the start of a sentence get their first
;; word capitalized as you'd hope.

;;; Code:

(defun autocap-maybe-capitalize-bos ()
  "If point is at the end of the first word in a sentence, capitalize it."
  (if (= (point)
	 (save-excursion
	   (backward-sentence)
	   (forward-word 1)
	   (point)))
      ;; We're at the end of the first word in the sentence.  Do
      ;; nothing if its last letter is uppercase (presumably an acronym).
      (unless (eq (char-before) (upcase (char-before)))
	(capitalize-word -1))))

;;;###autoload
(define-minor-mode auto-capitalize-mode
  "Toggle Auto-Capitalize minor mode.
With arg, turn Auto-Capitalize mode on in the current buffer if ARG is
positive, off otherwise.

In this mode the start of the current sentence is automatically
capitalized when a character is typed that expands abbrevs.  To avoid
this happening, enter such a character with \\[quoted-insert].
Capitalization is not done if the last letter of the word is
uppercase, on the assumption it is an acronym.

Consider defining specific abbrevs to do capitalization like the following:

 (define-abbrev-table 'text-mode-abbrev-table
   '((\"i'\" \"I'\")
     (\"i\" \"I\" autocap-not-at-stop)
     (\"emacs\" \"Emacs\" autocap-delimited)))

The mode depends on Abbrev mode, which it turns on in the buffer."
  :group 'convenience
  :group 'abbrev
  (if auto-capitalize-mode
      (progn
	(abbrev-mode 1)
	(add-hook 'pre-abbrev-expand-hook #'autocap-maybe-capitalize-bos
		  nil t))
    ;; Can't tell whether to turn off abbrev-mode.
    (remove-hook 'pre-abbrev-expand-hook #'autocap-maybe-capitalize-bos t)))

;;;###autoload
(defun autocap-not-at-stop ()
  "Unexpand abbrev if it was just expanded by a full stop.
Intended as an abbrev hook function, e.g. to avoid `i.e.' -> `I.e.'."
  (if (eq ?. last-command-char)
      (unexpand-abbrev)))

;;;###autoload
(defun autocap-delimited ()
  "Unexpand single-word abbrev if it doesn't follow appropriate delimiters.
These comprise whitespace (includeing beginning-of-line), brackets and quotes."
  (backward-word 1)
  (let* ((pc (preceding-char))
	 (pcs (char-syntax pc)))
  (unless (or (eq pcs ?\ )		; includes bol
	      (eq pcs ?\()
	      (eq pc ?\")
	      (eq pc ?\`))
    (unexpand-abbrev)))
  (forward-word 1))

(provide 'autocap)
;;; autocap.el ends here
