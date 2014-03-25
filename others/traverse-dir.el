;;; traverse-dir.el -- another rgrep more powerfull


;; Author: Thierry Volpiatto

;; Copyright (C) 2008 Thierry Volpiatto
;;
;; this file is NOT part of GNU Emacs
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301 USA

;; INSTALL:
;; =======

;; Install first the python backend TraverseDirectory
;; Put this file in your load path
;; and just (require 'traverse-dir)

;; NOTE: This program use TraverseDirectory as python backend.
;; Be sure to have it working correctly.

;; Created: Tue Feb 26 20:40:53 2008 +0100
;; Last modified: Tue Mar 25 23:26:48 2008 +0100

;; Code:


(require 'derived)
(require 'cl)

(define-derived-mode pygrep-mode muse-mode "pygrep"
  "Major mode to search regexp in files recursively
using a python backend called traverse-directory.py.
Special commands:
\\{pygrep-mode-map}")


(define-key pygrep-mode-map (kbd "q") #'(lambda ()
					  (interactive)
					  (quit-window t)))


(defgroup pygrep nil
  "Mode to search recursively regex like grep-find"
  :prefix "pygrep"
  :group 'muse)


(defcustom pygrep-size-max
  "1000000"
  "Maximum size allowed when searching"
  :group 'pygrep
  :type 'string)


(defcustom pygrep-command
  "traverse-bin.py"
  "Python command to call"
  :group 'pygrep
  :type 'string)


;;;###autoload
(defun pygrep-get-options-line (tree regex only)
  "return a list of all options"
  (let ((options ""))
    (if (equal only "")
	(setq options (split-string (concat
				     " -t "
				     (expand-file-name tree)
				     " -r "
				     regex
				     " -s "
				     pygrep-size-max)))
      (setq options (split-string (concat
				   " -t "
				   (expand-file-name tree)
				   " -r "
				   regex
				   " -s "
				   pygrep-size-max
				   " -o "
				   only)))
    options)))


;;;###autoload
(defun pygrep-call-traverse (tree regex only)
  "Run traverse-directory.py and return output
in a list"
  (let* ((options (pygrep-get-options-line tree regex only))
	 (list-result (with-temp-buffer
			(apply #'call-process pygrep-command nil t nil
			       options)
			(buffer-string))))
    (setq list-result (split-string list-result "\n"))
    list-result))


;;;###autoload
(defun pygrep-print-all (traverse-list)
  "print the traverse output at point"
  (let ((list-line nil))
    (dolist (x traverse-list)
      (setq list-line (split-string x))
      (when list-line
	(if (< (length list-line) 4)
	    (insert (concat "[["
			    (nth 0 list-line)
			    "]["
			    (nth 0 list-line)
			    " Access Denied]]\n"))
	  (insert (concat "[[pos://"
			  (nth 0 list-line)
			  "#"
			  (nth 4 list-line)
			  "]["
			  (nth 0 list-line)
			  "]] |<"
			  (mapconcat (lambda (y) y) (subseq list-line 5) " ")
			  ">\n")))))))
  

;; Main function that call traverse-directory.py
;;;###autoload
(defun tv-pygrep-find (tree regex &optional only)
  " write output to a dedicated buffer
in muse-mode"
  ;;TODO mettre un set de regexp en completing read
  (interactive "fTree: \nsRegexp: \nsMatchOnly: ")
  (let ((options (pygrep-get-options-line tree regex only))
	(list-result (pygrep-call-traverse tree regex only)))
    (set-buffer (get-buffer-create "*Traverse-directory*"))
    (text-mode) (erase-buffer)
    (insert "* Traverse-directory\n\n\n")
    (insert (concat "*" pygrep-command " " (mapconcat (lambda (x) x) options " ") "*\n\n"))
    (pygrep-print-all list-result)
  (switch-to-buffer-other-window "*Traverse-directory*")
  (goto-line (point-min))
  (if (re-search-forward "pos" nil t)
      (progn
	(pygrep-mode)
	(forward-char 1)
	(beginning-of-line)
	(forward-line -1))
    (forward-line 2)
    (insert (format "No occurences of *%s* found" regex))
    (pygrep-mode))))

(provide 'traverse-dir)

;;; traverse-dir.el ends here
