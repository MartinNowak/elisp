;;; info-apropos.el --- Search all Info indices

;; Copyright (C) 2003 Jesper Harder

;; Author: Jesper Harder <harder@ifa.au.dk>
;; Created: 14 Aug 2003
;; Version: 1.1
;; Location: <http://purl.org/harder/>
;; Keywords: help

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Emacs; if not, write to the Free Software Foundation,
;; Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
;;

;;; Commentary:

;; `M-x info-apropos' does the same as `index-apropos' in the
;; standalone Info reader.  I'll just repeat from the Info manual:
;;
;;  `M-x info-apropos'
;;       Grovel the indices of all the known Info files on your system
;;       for a string, and build a menu of the possible matches.
;;
;;   If you don't know what manual documents something, try the `M-x
;;   info-apropos'.  It prompts for a string and then looks up that
;;   string in all the indices of all the Info documents installed on
;;   your system.

;;; History:

;; Version 1.1:
;;
;; * Works in XEmacs.
;; * Print progress messages.
;; * Protect against broken Info files.
;;
;; Version 1.0:
;;
;; * Initial release.

;;; Code:

(require 'info)

(eval-when-compile
  (require 'cl))

(defmacro info-apropos-ignore-errors (&rest body)
  `(condition-case nil (progn ,@body t) (error nil)))

(defalias 'info-apropos-make-temp-file
  (if (fboundp 'make-temp-file)
      'make-temp-file
    (lambda (prefix &optional dir-flag)
      (let ((file (expand-file-name
		   (make-temp-name prefix)
		   (if (fboundp 'temp-directory)
		       (temp-directory)
		     temporary-file-directory))))
	(if dir-flag
	    (make-directory file))
	file))))

(defvar info-apropos-temp-files nil
  "List of temporary files created by `info-apropos'.")

(defun info-apropos-delete-temp-files ()
  "Delete temporary files created by `info-apropos'."
  (mapcar (lambda (file) (ignore-errors (delete-file file)))
	  info-apropos-temp-files)
  (setq info-apropos-temp-files nil))

(defun info-apropos (&optional topic)
  "Grovel indices of all known Info files on your system for a string.
Build a menu of the possible matches."
  (interactive "sIndex apropos: ")
  (add-hook 'kill-emacs-hook 'info-apropos-delete-temp-files)
  (info-apropos-delete-temp-files)
  (unless (string= topic "")
    (let ((pattern (format "\n\\* +\\([^\n]*%s[^\n]*\\):[ \t]+\\([^.]+\\)."
			   (regexp-quote topic)))
	  (ohist Info-history)
	  (current-node Info-current-node)
	  (current-file Info-current-file)
	  manuals matches temp-file node)
      (flet ((Info-fontify-node (&rest args) nil)
	     (Info-display-images-node (&rest args) nil)
	     (Info-set-mode-line (&rest args) nil))
	(Info-directory)
	(message "Searching indices...")
	(goto-char (point-min))
	(re-search-forward "\\* Menu: *\n" nil t)
	(while (re-search-forward "\\*.*: (\\([^)]+\\))" nil t)
	  (add-to-list 'manuals (match-string 1)))
	(dolist (manual manuals)
	  (message "Searching %s" manual)
	  (save-excursion
	    (when (info-apropos-ignore-errors (Info-find-node manual "Top"))
	      (when (re-search-forward "\n\\* \\(.*\\<Index\\>\\)" nil t)
		(goto-char (match-beginning 1))
		(when (info-apropos-ignore-errors
		       (Info-goto-node (Info-extract-menu-node-name)))
		  (while
		      (progn
			(goto-char (point-min))
			(while (re-search-forward pattern nil t)
			  (push (list (match-string 1)
				      (match-string 2)
				      manual)
				matches))
			(and (setq node (Info-extract-pointer "next" t))
			     (string-match "\\<Index\\>" node)))
		    (Info-goto-node node))))))))
      (Info-goto-node (concat "(" current-file ")" current-node))
      (setq Info-history ohist)
      (message "Searching indices...done")
      (if (null matches)
	  (message "No matches found")
	(with-temp-file
	    (setq temp-file (info-apropos-make-temp-file "info-apropos"))
	  (insert "\n\nFile: info-apropos, Node: Top, Up: (dir)\n")
	  (insert "* Menu: \nNodes whose indices contain \"" topic "\"\n\n")
	  (dolist (entry matches)
	    (insert "* " (car entry) " [" (nth 2 entry)
		    "]: (" (nth 2 entry) ")" (nth 1 entry) ".\n")))
	(info-apropos-Info-revert-find-node temp-file "Top")))))

(if (fboundp 'Info-revert-find-node)
    (defalias 'info-apropos-Info-revert-find-node 'Info-revert-find-node)
  ;;
  ;; This function is from Emacs 21.3.50:
  ;;
  (defun info-apropos-Info-revert-find-node (filename nodename)
    "Go to an info node FILENAME and NODENAME, re-reading disk contents.
When *info* is already displaying FILENAME and NODENAME, the window position
is preserved, if possible."
    (pop-to-buffer "*info*")
    (let ((old-filename Info-current-file)
	  (old-nodename Info-current-node)
	  (pcolumn      (current-column))
	  (pline        (count-lines (point-min) (point-at-bol)))
	  (wline        (count-lines (point-min) (window-start)))
	  (old-history  Info-history)
	  (new-history (and Info-current-file
			    (list Info-current-file Info-current-node (point)))))
      (kill-buffer (current-buffer))
      (Info-find-node filename nodename)
      (setq Info-history old-history)
      (if (and (equal old-filename Info-current-file)
	       (equal old-nodename Info-current-node))
	  (progn
	    ;; note goto-line is no good, we want to measure from point-min
	    (beginning-of-buffer)
	    (forward-line wline)
	    (set-window-start (selected-window) (point))
	    (beginning-of-buffer)
	    (forward-line pline)
	    (move-to-column pcolumn))
	;; only add to the history when coming from a different file+node
	(if new-history
	    (setq Info-history (cons new-history Info-history))))))
  )

(provide 'info-apropos)

;;; info-apropos.el ends here
