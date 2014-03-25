;;; ascii-to-iso-8859-1.el  ---  Functions to convert from ASCII to iso-8859-1.

;; Copyright (C)  2003  Marco Parrone.

;; Filename: ascii-to-iso-8859-1.el
;; Version: 0.3.1 (alpha)
;; Updated: 2003-08-11
;; Keywords: ascii, iso-8859-1, conversion
;; Author: Marco Parrone <marc0@autistici.org>
;; Maintainer: Marco Parrone <marc0@autistici.org>
;; Description: Functions to convert from ASCII to iso-8859-1.
;; Language: Emacs Lisp
;; Compatibility: Emacs21
;; Location: http://savannah.nongnu.org/cgi-bin/viewcvs/*checkout*/emhacks/emhacks/elisp/ascii-to-iso-8859-1.el?rev=HEAD&content-type=text/plain

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

;;; Commentary:

;; Some peoples are used to use quotes instead of accents, and similar
;; other hackish things, so to not having to rely on iso-8859-1 but
;; only on ASCII.

;; This program is meant to replace that quoted letters with accented
;; ones, where appropriate, plus others characters conversions.

;; Customization:

;; See `M-x customize-group ascii-to-iso-8859-1'.

;; To make converting atomagically articles in Gnus:

;; (add-hook 'gnus-article-prepare-hook
;;   'ascii-to-iso-8859-1-on-other-maybe-readonly-window)

;; BUGS

;; `ascii-to-iso-8859-1-word-start' and `ascii-to-iso-8859-1-word-end'
;; need some tweaking, for example adding "~/-,^".
;;
;; `ascii-to-iso-8859-1-get-current-word' and
;; `ascii-to-iso-8859-1-on-buffer' should implement a mechanism that
;; permits to recognize when a symbol is part of a word and when it is
;; not, for example <<aba"nderliche>> works, but <<"aba"nderliche">>
;; does not.

;;; Code:

(defgroup ascii-to-iso-8859-1 nil
  "Replace the quoted letters with accented ones where appropriate,
and do other similar conversions."
  :prefix "ascii-to-iso-8859-1-"
  :group 'editing)

(defcustom ascii-to-iso-8859-1-words "/usr/share/dict/italian"
  "*The file containing the wordlist to use."
  :type '(string)
  :group 'ascii-to-iso-8859-1)

(defcustom ascii-to-iso-8859-1-other-words '("è")
  "*A list of additional valid words."
  :type '(sexp)
  :group 'ascii-to-iso-8859-1)

(defcustom ascii-to-iso-8859-1-word-start "[^a-zA-Z`'\"][a-zA-Z`'\"]"
  "*Regular expression that matches the start of a word."
  :type '(string)
  :group 'ascii-to-iso-8859-1)

(defcustom ascii-to-iso-8859-1-word-end "[a-zA-Z`'\"]\\([^a-zA-Z`'\"]\\|$\\)"
  "*Regular expression that matches the end of a word."
  :type '(string)
  :group 'ascii-to-iso-8859-1)

(defcustom ascii-to-iso-8859-1-symbols-table '(("([Cc])" . "©")
					       ("<<" . "«")
					       (">>" . "»")
					       ("([Rr])" . "®")
					       (" 1/4 " . " ¼ ")
					       (" 1/2 " . " ½ ")
					       (" 3/4 " . " ¾ "))
  "*Table containing rules to replace symbols."
  :type '(sexp)
  :group 'ascii-to-iso-8859-1)

(defcustom ascii-to-iso-8859-1-characters-table '(("A['`]" . ("À" "Á"))
						  ("A^" . ("Â"))
						  ("A~" . ("Ã"))
						  ("A\"" . ("Ä"))
						  ("AE" . ("Æ"))
						  ("C," . ("Ç"))
						  ("E['`]" . ("È" "É"))
						  ("E^" . ("Ê"))
						  ("E\"" . ("Ë"))
						  ("I['`]" . ("Ì" "Í"))
						  ("I^" . ("Î"))
						  ("I\"" . ("Ï"))
						  ("D-" . ("Ð"))
						  ("N~" . ("Ñ"))
						  ("O['`]" . ("Ò" "Ó"))
						  ("O^" . ("Ô"))
						  ("O~" . ("Õ"))
						  ("O\"" . ("Ö"))
						  ("O/" . ("Ø"))
						  ("U['`]" . ("Ù" "Ú"))
						  ("U^" . ("Û"))
						  ("U\"" . ("Ü"))
						  ("Y['`]" . ("Ý"))
						  ("a['`]" . ("à" "á"))
						  ("a^" . ("â"))
						  ("a~" . ("ã"))
						  ("a\"" . ("ä"))
						  ("ae" . ("æ"))
						  ("c," . ("ç"))
						  ("e['`]" . ("è" "é"))
						  ("e^" . ("ê"))
						  ("e\"" . ("ë"))
						  ("i['`]" . ("ì" "í"))
						  ("i^" . ("î"))
						  ("i\"" . ("ï"))
						  ("n~" . ("ñ"))
						  ("o['`]" . ("ò" "ó"))
						  ("o^" . ("ô"))
						  ("o~" . ("õ"))
						  ("o\"" . ("ö"))
						  ("o/" . ("ø"))
						  ("u['`]" . ("ù" "ú"))
						  ("u^" . ("û"))
						  ("u\"" . ("ü"))
						  ("y['`]" . ("ý"))
						  ("y\"" . ("ÿ")))
  "*Table containing rules to replace characters."
  :type '(sexp)
  :group 'ascii-to-iso-8859-1)

(defun ascii-to-iso-8859-1-word-exists (word)
  "Return true if a word exists in the words list, else return nil."
  (if (member word ascii-to-iso-8859-1-other-words)
      t
    (with-current-buffer
	(find-file-noselect ascii-to-iso-8859-1-words)
      (goto-char 0)
      (re-search-forward (concat "^" word "$") nil t))))

(defun ascii-to-iso-8859-1-get-current-word ()
  "Get the word on which the point is on."
  (interactive)
  (let* ((original-point (point))
	 (begin (progn
		  (goto-char (+ (point) 1))
		  (re-search-backward ascii-to-iso-8859-1-word-start
				      nil t)))
	 (end (re-search-forward ascii-to-iso-8859-1-word-end nil nil)))
    (buffer-substring (+ 1 (if begin begin 0))
		      (if end (- end 1) (point-max)))))

(defun ascii-to-iso-8859-1-new-word (old-word base dest)
  "Get the new word, making the trasformations s/base/dest/."
  (interactive)
  (with-temp-buffer
    (insert old-word)
    (goto-char 0)
    (re-search-forward base nil t)
    (replace-match dest nil nil)
    (goto-char 1)
    (buffer-substring 1 (point-max))))

(defun ascii-to-iso-8859-1-on-region (start end)
  "Replace the quoted letters with accented ones where appropriate,
and do other similar conversions.
Works on a region.
Maintains the region bounds."
  (interactive "r")
  (let ((case-fold-search nil)
	(original-point (point))
	(replaced 0)
	(change-symbol
	 (lambda (base dest)
	   (goto-char
	    (if start start original-point))
	   (while
	       (re-search-forward base
				  (if end
				      (+ (- end replaced) 1)
				    nil)
				  t)
	     (progn
	       (replace-match dest nil nil)
	       (if (< (point) original-point)
		   (setq replaced
			 (+ replaced 1)))))))
	(change-character-helper
	 (lambda (base dest)
	   (goto-char
	    (if start start original-point))
	   (while
	       (re-search-forward base
				  (if end
				      (+ (- end replaced) 1)
				    nil)
				  t)
	     (progn
	       (goto-char (- (point) 2))
	       (if (ascii-to-iso-8859-1-word-exists
		    (ascii-to-iso-8859-1-new-word
		     (ascii-to-iso-8859-1-get-current-word) base dest))
		   (progn
		     (goto-char
		      (if start start original-point))
		     (re-search-forward base
					(if end
					    (+ (- end replaced) 1)
					  nil)
					t)
		     (replace-match dest nil nil)
		     (if (< (point) original-point)
			 (setq replaced
			       (+ replaced 1)))))))))
	(change-character
	 (lambda (base dest)
	   (dolist (current dest)
	     (funcall change-character-helper base current)))))

    (dolist (rule ascii-to-iso-8859-1-symbols-table)
      (funcall change-symbol (car rule) (cdr rule)))

    (dolist (rule ascii-to-iso-8859-1-characters-table)
      (funcall change-character (car rule) (cdr rule)))

    (goto-char (- original-point
		  replaced))))

(defun ascii-to-iso-8859-1-forward ()
  "Replace the quoted letters with accented ones where appropriate,
and do other similar conversions.
Works from point to End Of Buffer.
Does not move the point."
  (interactive)
  (ascii-to-iso-8859-1-on-region nil nil))

(defun ascii-to-iso-8859-1-on-buffer ()
  "Replace the quoted letters with accented ones where appropriate,
and do other similar conversions.
Works on the current buffer.
Moves the point to char 0."
  (interactive)
  (goto-char 0)
  (ascii-to-iso-8859-1-on-region nil nil))

(defun ascii-to-iso-8859-1-on-maybe-readonly-buffer ()
  "Replace the quoted letters with accented ones where appropriate,
and do other similar conversions.
Works on the current buffer.
Moves the point to char 0.
Does not fail if the buffer is read-only."
  (interactive)
  (let ((buffer-was-read-only buffer-read-only))
    (goto-char 0)
    (if buffer-was-read-only
	(toggle-read-only -1))
    (ascii-to-iso-8859-1-on-region nil nil)
    (if buffer-was-read-only
	(toggle-read-only 1))))

(defun ascii-to-iso-8859-1-on-other-window ()
  "Replace the quoted letters with accented ones where appropriate,
and do other similar conversions.
Works on the other window buffer.
Moves the point to char 0."
  (interactive)
  (with-current-buffer (window-buffer (other-window 1))
    (ascii-to-iso-8859-1-on-buffer)))

(defun ascii-to-iso-8859-1-on-other-maybe-readonly-window ()
  "Replace the quoted letters with accented ones where appropriate,
and do other similar conversions.
Works on the other window buffer.
Moves the point to char 0.
Does not fail if the buffer is read-only."
  (interactive)
  (with-current-buffer (window-buffer (other-window 1))
    (ascii-to-iso-8859-1-on-maybe-readonly-buffer)))

;; Local Variables:
;; mode: emacs-lisp
;; mode: auto-fill
;; fill-column: 70
;; comment-column: 32
;; End:

;;;; ascii-to-iso-8859-1.el ends here.
