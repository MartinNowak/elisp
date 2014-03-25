;;; protect-files.el --- hooks and minor mode to avoid modifying files

;; Copyright (C) 2005  Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>
;; Created: 2005-11-14
;; Keywords: tools
;; Version: $Revision: 1.3 $
;; URL: http://www.loveshack.ukfsn.org/emacs

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

;; This is a mechanism for preventing at least accidental modification
;; of files matching defined patterns (see `protect-files-alist').  It
;; is assumed that modifying such files causes trouble.  An example is
;; corruption of a darcs revision control system repository, if you
;; edit or create files in the _darcs/current directory.

;; Functions are defined for use on hooks to try to prevent such
;; problems.  When you find such a file, the buffer is made read-only,
;; with backups and autosave turned off on the assumption that writing
;; anything into its directory is bad news.  You get an error if you
;; try to write a file with a matching name.

;; How to use this is complicated by the fact that the appropriate
;; hook mechanisms changed in the unreleased (at time of writing)
;; Emacs 22 code base.  That might be relevant should it ever get
;; released [:-(] with the hooks unchanged -- see below.  To avoid
;; such issues, use the global minor mode `protect-files-mode'.
;; [monnier says that the old hook names should still work, though
;; presumably there's no guarantee they will continue to.]

;; To start with, put this file somewhere on your `load-path',
;; byte-compile it, and to your .emacs add:
;; 
;;    (require 'protect-files)
;;
;; once you've loaded it, you can invoke the command
;; `protect-files-mode', or customize the option of that name.
;; [Compiling is required to have Custom do the right thing with the
;; minor mode.]

;; If for some reason you don't want to use Custom, in Emacs 21 use:
;; 
;;    (add-hook 'find-file-hooks 'protect-files-check-find)
;;    (add-hook 'write-file-hooks 'protect-files-check-write)
;; 
;; and in Emacs 22:
;;
;;    (add-hook 'find-file-hook 'protect-files-check-find)
;;    (add-hook 'before-save-hook 'protect-files-check-write)

;; Confused?  Just use the minor mode.

;; If you're not using Emacs 21 or later (e.g. XEmacs), this may not
;; all work, but you can probably add to the hooks explicitly.

;; [Fixme:  Maybe this is better done with file-name handlers?]

;;; Code:

(defgroup protect-files ()
  "Protecting (groups of) files from being edited accidentally"
  :group 'files)

(defcustom protect-files-alist
  '(("/_darcs/\\([^/]+\\)/" . (lambda (name)
				(not (string= "prefs"
					      (match-string 1 name))))))
  "Alist of regexps matching file names and functions to qualify them.

A file is potentially protected from writing if, for any element of
the alist, it matches the car.  Matches may be qualified.  They
actually succeed iff the element's cdr is nil or is a function which
returns non-nil when applied to the file name.  It may use the match
data from the regexp with the name it gets as argument.

The default value is appropriate for darcs revision control
repositories.  If you want to try a function directly, rather than the
regexp match, just use regexp \".\", for instance.  You can match
\"/\" as the path separator even on MS Windows."
  :group 'protect-files
  :type '(alist :key-type regexp
		:value-type (choice (const :tag "Just match regexp" nil)
				    (function :tag "Qualifying function"))))

(defun protect-files-match-p (name)
  "Whether file NAME should be protected according to `protect-files-alist'.

The condition is that the car of an element of the alist matches NAME
and the cdr is either nil or is a function that returns non-nil when
applied to NAME."
  (save-match-data			; probably not necessary
    (catch 'found
      (dolist (elt protect-files-alist)
	(if (string-match (car elt) name)
	    (if (cdr elt)
		(condition-case ()
		    (if (funcall (cdr elt) name)
			(throw 'found t))
		  (error nil))
	      (throw 'found t)))))))

(defun protect-files-check-find ()
  "Function to add to `find-file-hooks'/`find-file-hook' if using darcs.
\(The latter is for Emacs 22 and later.)

Makes the buffer read-only when you find a file which is protectable
according to `protect-files-alist'.  (It is assumed that modifying
such files causes corruption, e.g. of a darcs repository.)  Also turns
off autosaving and backups in case you do edit the file.

See also `protect-files-check-write'."
  (when (protect-files-match-p (buffer-file-name))
    (toggle-read-only 1)
    (auto-save-mode 0)
    (set (make-local-variable 'backup-inhibited) t)
    (message "\
Warning: buffer readonly, not autosaved; see `protect-files-check-find' doc.")))

(defun protect-files-check-write ()
  "Function to add to `write-file-hooks'/`before-save-hook' if using darcs.
\(The latter is for Emacs 22 and later.)

Signals an error if you try to write a file which is protectable
according to `protect-files-alist'.  (It is assumed that modifying
such files causes corruption, e.g. of a darcs repository.)  If you
_really_ want to update a file there, save the edited version
somewhere else and use \\[rename-file].

See also `protect-files-check-find'."
  (when (protect-files-match-p (buffer-file-name))
    (error "\
Can't write to %s; see `protect-files-check-write'" (buffer-file-name))))

(when (boundp 'before-save-hook)	; Emacs 22
  (custom-add-option 'before-save-hook 'protect-files-check-write)
  (custom-add-option 'find-file-hook 'protect-files-check-find))

;;;###autoload
(define-minor-mode protect-files-mode
  "Twiddle hooks to protect files according to `protect-files-alist'.
It is assumed that modifying such files causes corruption, e.g. of a
darcs repository.

This works by modifying `find-file-hooks'/`find-file-hook' and
`write-file-hooks'/`before-save-hook', depending on the Emacs version.

See also `protect-files-check-find' and `protect-files-check-write'."
  :group 'files
  :global t
  (if protect-files-mode
      (progn (if (boundp 'before-save-hook) ; Emacs 22
		 (add-hook 'before-save-hook 'protect-files-check-write)
	       (add-hook 'write-file-hooks 'protect-files-check-write))
	     (if (boundp 'find-file-hook) ; Emacs 22
		 (add-hook 'find-file-hook 'protect-files-check-find)
	       (add-hook 'find-file-hooks 'protect-files-check-find)))
    (remove-hook 'find-file-hooks 'protect-files-check-find)
    (remove-hook 'write-file-hooks 'protect-files-check-write)
    ;; Check they're bound to avoid `remove-hook' binding them.
    (if (boundp 'find-file-hook)
	(remove-hook 'find-file-hook 'protect-files-check-find))
    (if (boundp 'before-save-hook)
	(remove-hook 'before-save-hook 'protect-files-check-write)))
  (when (fboundp 'custom-mark-as-set)	; Emacs 22
    (customize-mark-as-set 'before-save-hook)
    (customize-mark-as-set 'find-file-hooks)))

(add-hook 'protect-files-unload-hook (lambda () (protect-files-mode 0)))

(provide 'protect-files)
;;; protect-files.el ends here
