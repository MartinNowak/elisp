;;; cap-words.el --- minor mode for motion in CapitalizedWordIdentifiers

;; Copyright (C) 2002, 2003, 2009
;;   Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>
;; Keywords: languages convenience
;; URL: http://www.loveshack.ukfsn.org/emacs/
;; $Revision: 1 $

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides Capitalized Words minor mode for word movement -- in fact
;; a general definition of words -- in identifiers
;; CapitalizedLikeThis.  [Terms for this include `medial case',
;; `CamelCase', `CapitalizedWords', `CapWords', `mixed case' (leading
;; lower case), `InterCaps', `compoundNames'.  See the Wikipedia entry
;; for CamelCase, which looks reasonably believable.]  In common with,
;; for instance, http://www.python.org/dev/peps/pep-0008/, we'll
;; consider all-caps sequences to be words unless the last character
;; starts a capitalized word, e.g. `HTTPError' comprises `HTTP' and
;; `Error'.

;; You might expect to do this sort of thing by adjusting the local
;; category table and `word-separating-categories' so that upper case
;; characters produce word boundaries, but the necessary processing
;; isn't done for ASCII characters (see the end of category.h).

;; Fixme: This doesn't work properly for mouse double clicks --
;; e.g. clicking on an initial capital includes the capitalized words
;; before and after it, which looks like a bug in mouse.el.

;;; Code:

(defun capitalized-find-word-boundary (pos limit)
  "Function for use in `find-word-boundary-function-table'.
Looks for word boundaries before capitals."
  (save-excursion
    (goto-char pos)
    (let ((find-word-boundary-function-table capitalized-null-table)
	  (case-fold-search nil))
      (if (< pos limit)
	  (progn
	    ;; `limit' is actually point after `forward-word', but
	    ;; `find-word-boundary-function-table' doesn't say that.
	    (setq limit (min limit (save-excursion (forward-word) (point))))
	    (or
	     (cond
	      ;; Looking at a non-capital sequence, possible initial
	      ;; cap, possibly terminating at a cap.  (Use anchored
	      ;; regexps as `looking-at' doesn't have a limit arg;
	      ;; maybe narrowing would be clearer.  Avoid using
	      ;; `[:lower:]' to account for possible non-alphameric
	      ;; characters with word syntax.)
	      ((re-search-forward
		"\\=[[:upper:]]?\[^[:upper:]]+\\([[:upper:]]\\)?" limit t)
	       (if (match-beginning 1)
		   (1- (point))
		 (point)))
	      ;; Looking at a sequence of caps: one word unless it's
	      ;; followed by a non-cap.
	      ((re-search-forward "\\=[[:upper:]]+\\([^[:upper:]]\\)?" limit t)
	       (if (match-beginning 1)
		   (- (point) 2)
		 (point)))
	      ;; Else a normal word.
	      (t limit))))
	;; In this case, the input limit isn't the boundary of a
	;; normal word and, indeed always seems to be point-min; maybe
	;; that's a bug.
	(setq limit (max limit (save-excursion
				 ;; Forward and back in case of single
				 ;; character word.
				 (forward-word) (backward-word)
				 (point))))
	(cond
	 ;; Also in this case the spec of
	 ;; `find-word-boundary-function-table' (POS off-by-one) or
	 ;; the implementation of `scan_words' seems to be wrong,
	 ;; which complicates things.  Here we were at the second
	 ;; letter of a capitalized word before `backward-word' was
	 ;; invoked.
	 ((and (looking-at "[[:upper:]][^[:upper:]]")
	       ;; The second character must be part of a word, not off
	       ;; the end.
	       (looking-at "[[:upper:]]\\w"))
	  (match-beginning 0))
	 ;; We were at the beginning of a capitalized word before
	 ;; `backward-word' was invoked, or between words.
	 ((and (looking-at "\\=[^[:upper:]]")
	       (re-search-backward "[[:upper:]]\\=" limit t))
	  (point))
	 ;; We were at the end of an all-caps run at the end of a
	 ;; symbol, or between all-caps and capitalized words.
	 ((/= 0 (skip-chars-backward "[:upper:]" limit))
	  (point))
	 ;; In the middle of a capitalized word.
	 ((re-search-backward "[[:upper:]][^[:upper:]]+\\=" limit t))
	 (t limit))))))

(defconst capitalized-find-word-boundary-function-table
  (let ((tab (make-char-table nil)))
    (set-char-table-range tab t #'capitalized-find-word-boundary)
    tab)
  "Assigned to `find-word-boundary-function-table' in Capitalized Words mode.")

(defconst capitalized-null-table (make-char-table nil))

;;;###autoload
(define-minor-mode capitalized-words-mode
  "Toggle Capitalized Words mode.

In this minor mode, a word boundary occurs immediately before an
uppercase letter in a symbol where the letter starts an all-caps word
or a capitalized word.  This is in addition to all the normal
boundaries given by the syntax and category tables.  There is no
restriction to ASCII or alphameric characters as word constituents.

E.g. the beginning of words in the following identifier are as marked:

 normalCAPSCapitalCAPS
 ^     ^   ^      ^

Note that these word boundaries only apply for word motion and
marking commands such as \\[forward-word].  This mode does not affect word
boundaries found by regexp matching (`\\>', `\\w' &c).  Word selection
by double mouse clicks currently doesn't work properly when you click
on a capital.

This style of identifiers is common in environments like Java ones,
where hypens or underscores aren't trendy enough.  Also capitalization
rules are sometimes part of the language, like Haskell, and typical
wiki markup.  It is appropriate to add `capitalized-words-mode' to the
mode hook for modes in which you may encounter variables like this,
e.g. `java-mode-hook';  it's unlikely to cause trouble if such
identifiers aren't actually used.

See also `glasses-mode' and `studlify-word'.

Obsoletes `c-forward-into-nomenclature' and similar things in various
language-specific modes."
  nil " Caps" nil
  ;; These may not be the best groups, but then they won't currently
  ;; get used as far as I konw.
  :group 'programming
  :group 'tools				; per glasses.el
  (set (make-local-variable 'find-word-boundary-function-table)
       (if capitalized-words-mode
	   capitalized-find-word-boundary-function-table
	 capitalized-null-table)))

(provide 'cap-words)

;; arch-tag: 46513b64-fe5a-4c0b-902c-ed235c22975f
;;; cap-words.el ends here
