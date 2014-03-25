;;; diary-outlook.el --- snarf MS Outlook appointments into Emacs diary

;; Copyright (C) 2002, 2003  Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>
;; Keywords: calendar, mail
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

;; Provides a simple framework for snarfing the pestilential
;; Outlook-format appointments from mail messages in Gnus or Rmail
;; using command `diary-from-outlook'.  This, or specialized functions
;; `diary-from-outlook-gnus' and `diary-from-outlook-rmail', could be
;; run from hooks to notice appointments automatically (in which case
;; they will prompt about adding to the diary).
;; `gnus-article-prepare-hook' is probably the right one for Gnus; I
;; don't know about Rmail.

;; The message formats recognized are customizable through
;; `diary-outlook-formats', but this may be a losing battle generally,
;; given the variety of random formats such messages take, in the
;; usual MS way.  I think `diary-outlook-formats' doesn't currently
;; cover all the varieties I've received, but does most of them.
;; There's also a German example whose source I don't remember.

;;; Code:

(autoload 'make-diary-entry "diary-lib")
(autoload 'gnus-fetch-field "gnus-util")
(autoload 'gnus-narrow-to-body "gnus")
(autoload 'mm-get-part "mm-decode")
(eval-when-compile (defvar gnus-article-mime-handles))

(defgroup diary-outlook ()
  "Snarfing MS Outlook appointments into Emacs diary"
  :link '(emacs-commentary-link "diary-outlook")
  :group 'diary
  :group 'mail)

(defcustom diary-outlook-formats
  '(
    ;; When: 11 October 2001 12:00-14:00 (GMT) Greenwich Mean Time : Dublin, ...
    ;; [Current UK format?  The timezone is meaningless.  Sometimes the
    ;; Where is missing.]
    ("When: \\([0-9]+ [[:alpha:]]+ [0-9]+\\) \
\\([^ ]+\\) [^\n]+
\[^\n]+
\\(?:Where: \\([^\n]+\\)\n+\\)?
\\*~\\*~\\*~\\*~\\*~\\*~\\*~\\*~\\*~\\*"
     . "\\1\n \\2 %s, \\3")
    ;; When: Tuesday, April 30, 2002 03:00 PM-03:30 PM (GMT) Greenwich Mean ...
    ;; [Old UK format?]
    ("^When: [[:alpha:]]+, \\([[:alpha:]]+\\) \\([0-9][0-9]*\\), \\([0-9]\\{4\\}\\) \
\\([^ ]+\\) [^\n]+
\[^\n]+
\\(?:Where: \\([^\n]+\\)\\)?\n+"
     . "\\2 \\1 \\3\n \\4 %s, \\5")
    (
     ;; German format, apparently.
     "^Zeit: [^ ]+, +\\([0-9]+\\)\. +\\([[:upper:]][[:lower:]][[:lower:]]\\)[^ ]* +\\([0-9]+\\) +\\([^ ]+\\).*$"
     . "\\1 \\2 \\3\n \\4 %s"))
  "Alist of regexps matching message text and replacement text.

The regexp must match the start of the message text containing an
appointment, but need not include a leading `^'.  If it matches the
current message, a diary entry is made from the corresponding
template.  If the template is a string, it should be suitable for
passing to `replace-match', and so will have occurrences of `\\D' to
substitute the match for the Dth subexpression.  It must also contain
a single `%s' which will be replaced with the text of the message's
Subject field.  Any other `%' characters must be doubled, so that the
template can be passed to `format'.

If the template is actually a function, it is called with the message
body text as argument, and may use `match-string' etc. to make a
template following the rules above."
  :type '(alist :key-type (regexp :tag "Regexp matching time/place")
		:value-type (choice
			     (string :tag "Template for entry")
			     (function :tag "Unary function providing template")))
  :group 'diary-outlook)

(eval-when-compile
  (defvar gnus-article-buffer)
  (defvar rmail-buffer)
  ;; dynamically bound:
  (defvar body)
  (defvar subject))

(defun diary-from-outlook-internal (&optional test-only)
  "Snarf a diary entry from a message assumed to be from MS Outlook.
Assumes `body' is bound to a string comprising the body of the message and
`subject' is bound to a string comprising its subject.
Arg TEST-ONLY non-nil means return non-nil iff the message contains an
appointment, don't make a diary entry."
  (catch 'finished
    (let (format-string)
      (dotimes (i (length diary-outlook-formats))
	(when (eq 0 (string-match (car (nth i diary-outlook-formats))
				  body))
	  (unless test-only
	    (setq format-string (cdr (nth i diary-outlook-formats)))
	    (save-excursion
	      (save-window-excursion
		;; Fixme: References to optional fields in the format
		;; are treated literally, not replaced by the empty
		;; string.  I think this is an Emacs bug.
		(make-diary-entry
		 (format (replace-match (if (functionp format-string)
					    (funcall format-string body)
					  format-string)
					t nil (match-string 0 body))
			 subject))
		(save-buffer))))
	  (throw 'finished t))))
    nil))

(defun diary-from-outlook ()
  "Maybe snarf diary entry from current Outlook-generated message.
Currently knows about Gnus and Rmail modes."
  (interactive)
  (let ((func (cond
	       ((eq major-mode 'rmail-mode)
		#'diary-from-outlook-rmail)
	       ((memq major-mode '(gnus-summary-mode gnus-article-mode))
		#'diary-from-outlook-gnus)
	       (t (error "Don't know how to snarf in `%s'" major-mode)))))
    (if (interactive-p)
	(call-interactively func)
      (funcall func))))

(defun diary-from-outlook-gnus ()
  "Maybe snarf diary entry from Outlook-generated message in Gnus."
  (interactive)
  (with-current-buffer gnus-article-buffer
    (let ((subject (gnus-fetch-field "subject"))
	  (body (if gnus-article-mime-handles
		    ;; We're multipart.  Don't get confused by part
		    ;; buttons &c.  Assume info is in first part.
		    (mm-get-part (nth 1 gnus-article-mime-handles))
		  (save-restriction
		    (gnus-narrow-to-body)
		    (buffer-string)))))
      (when (diary-from-outlook-internal t)
	(when (or (and (not (interactive-p))
		       (y-or-n-p "Snarf diary entry? "))
		  (interactive-p))
	  (diary-from-outlook-internal)
	  (message "Diary entry added"))))))

(defun diary-from-outlook-rmail ()
  "Maybe snarf diary entry from Outlook-generated message in Rmail."
  (interactive)
  (with-current-buffer rmail-buffer
    (let ((subject (mail-fetch-field "subject"))
	  (body (buffer-substring (save-excursion
				    (rfc822-goto-eoh)
				    (point))
				  (point-max))))
      (when (diary-from-outlook-internal t)
	(when (or (and (not (interactive-p))
		       (y-or-n-p "Snarf diary entry? "))
		  (interactive-p))
	  (diary-from-outlook-internal)
	  (message "Diary entry added"))))))

(custom-add-option 'gnus-article-prepare-hook 'diary-from-outlook-gnus)

(provide 'diary-outlook)
;;; diary-outlook.el ends here
