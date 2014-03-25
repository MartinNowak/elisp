;;; phrase.el --- movement by `phrases' in text  -*-coding: utf-8;-*-

;; Copyright (C) 2005  Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>
;; Keywords: convenience

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

;; 

;;; Code:

(defvar phrase-char-alist
  '((?` . ?')				; Emacs-style ASCII quotes
    (?\" . ?\")
    ;; These are locale-specific.
    (?\‘ . ?\’)
    (?\“ . ?\”)
    (?\« . ?\»)
    (?\‹ . ?\›)
    ;; Potentially useful for Spanish, though these are sentence boundaries:
;;     (?¿ . ??)
;;     (?¡ . ?!)
    ))

(defvar phrase-other-syntax-table
  (let ((table (copy-syntax-table)))
    (dolist (elt phrase-char-alist)
      (modify-syntax-entry (car elt) "_" table)
      (modify-syntax-entry (cdr elt) "_" table))
    (modify-syntax-entry ?. "-" table)	; avoid abbreviations, initials
    table)
  "Syntax table ecluding characters from `phrase-char-alist'.
Used by `phrase-match-position'.")

(defun phrase-match-position (alist &optional back)
  "Move to the end of the next `phrase', backwards if BACK is non-nil.
Looks for matching characters from ALIST."
  (if back
      (let ((c (preceding-char)))
	;; Account for things like `"...",' after the comma.
	(with-syntax-table phrase-other-syntax-table
	  (when (eq ?. (char-syntax c))
	    (backward-char)
	    (setq c (preceding-char))))
	(let ((match (car (rassq c alist))))
	  (when (and match (not (eq ?w (char-syntax (following-char)))))
	    (backward-char)
	    (if (/= (skip-chars-backward (format "^%c" match)) 0)
		(max (point-min) (1- (point)))))))
    (let* ((c (following-char))
	   (match (cdr (assq c alist))))
      (when (and match (not (eq ?w (char-syntax (preceding-char)))))
	(forward-char)
	(if (/= (skip-chars-forward (format "^%c" match)) 0)
	    (min (point-max) (1+ (point))))))))

(defun forward-phrase (&optional arg)
  "Move forward over the next `phrase'.
With argument, move over that many phrases, backwards if ARG is negative.

A `phrase' can be delimited by brackets (in which case sexp motion is
used), by character pairs from `phrase-char-alist', or by point and a
punctuation character not in `phrase-char-alist'.  All else failing,
move by sentences."
  (interactive "p")
  (unless arg (setq arg 1))
  (if (< arg 0)
      ;; Going backwards.
      (let (sentence)
	(skip-syntax-backward "-")
	(dotimes (i (abs arg))
	  (goto-char
	   (cond ((eq (char-syntax (preceding-char)) ?\))
		  (backward-sexp)
		  (point))
		 ((phrase-match-position phrase-char-alist t))
		 ((save-excursion
		    (save-excursion
		      (backward-sentence)
		      (setq sentence (point)))
		    (with-syntax-table phrase-other-syntax-table
		      (if (re-search-backward "\\s.\\Sw" sentence t)
			  (1+ (point))))))
		 (t (backward-sentence)
		    (point))))))
    ;; Going forwards.
    (let (sentence)
      (skip-syntax-forward "-")
      (dotimes (i arg)
	(goto-char
	 (cond ((eq (char-syntax (following-char)) ?\()
		(forward-sexp)
		(point))
	       ((phrase-match-position phrase-char-alist))
	       ((save-excursion
		  (save-excursion (forward-sentence) (setq sentence (point)))
		  (with-syntax-table phrase-other-syntax-table
		    (if (re-search-forward "\\s.\\Sw" sentence t)
			(1- (point))))))
	       (t (forward-sentence)
		  (point))))))))

(defun backward-phrase (&optional arg)
  "Move backwards by a phrase, or with ARG, by that number of phrases."
  (interactive "p")
  (forward-phrase (and arg (- arg))))

(defun mark-phrase (&optional arg)
  "Mark ARG phrases forward from point.
Mark backwards if ARG is negative.
See `forward-phrase'."
  (interactive "p")
  (push-mark
   (save-excursion
     (if (and (eq last-command this-command) (mark t))
	 (goto-char (mark)))
     (forward-phrase arg)
     (point))
   nil t))

(provide 'phrase)
;;; phrase.el ends here
