;;; sh-beg-end.el --- Something for C-M-a,
;;; C-M-e, M-a and M-e in shell-script-mode

;; Copyright (C) 2007 by Andreas Röhler
;; <andreas.roeh...@online.de>

;; Keywords: languages

;; This file is free software; you can redistribute it
;; and/or modify it under the terms of the GNU General
;; Public License as published by the Free Software
;; Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the
;; implied warranty of MERCHANTABILITY or FITNESS FOR A
;; PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.

;; You should have received a copy of the GNU General
;; Public License along with GNU Emacs; see the file
;; COPYING.  If not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; sh-beg-end addresses the writers side of point:
;; provide predictable moves through shell-scripts
;; while writing, i.e. it don't require things,
;; which might not be finished, not be written
;; yet.

;; C-M-a, C-M-e: jump to the beginning or end of a
;; top-level-form in sh-mode -
;; "Shell-script"-mode. Repeated execution forward
;; or backward. With argument as many times.

;; M-a, M-e: jump to the beginning or end of command in
;; a given line, forward or backward next beginning or
;; end. With argument do this as many times.

;; Thanks to Stefan Monnier and Richard Stallman
;; being helpful. Errors are mine, any comments
;; welcome.

;;; Code:

(defcustom sh-beginning-of-form-regexp "^[A-Za-z_][A-Za-z_0-9]*"
  "Regexp indicating the beginning of a form to edit. "
  :type 'regexp
  :group 'lisp)

(defun sh-beginning-of-form (&optional arg)
  "Move to the beginning of a top-level-form in sh-script.
With numeric argument, do it that many times."
  (interactive "p")
  (let ((arg (or arg 1)))
    (re-search-backward sh-beginning-of-form-regexp nil t arg)))

(defun sh-end-of-form (&optional arg)
  "Move to the end of a top-level-form in sh-script.
With numeric argument, do it that many times."
  (interactive "p")
  (let ((arg (or arg 1)))
    (while (forward-comment 1) (forward-comment 1))
    (unless (looking-back "^[ \t]*")
      (setq arg (1+ arg)))
    (forward-paragraph arg)
    (skip-chars-backward " \t\r\n\f")
    (unless (looking-at "}")
      (back-to-indentation))
    (if (looking-back "^[ \t]+")
        (progn
          (end-of-line)
          (sh-end-of-form))
      (end-of-line)
      (skip-chars-backward " \t\r\n\f"))))

(defun sh-set-beginning-of-form ()
  "Sets `sh-beginning-of-form' as `beginning-of-defun-function'"
  (interactive)
  (set
   (make-local-variable 'beginning-of-defun-function) 'sh-beginning-of-form))

(defun sh-set-end-of-form ()
  "Sets `sh-end-of-form' as `end-of-defun-function'"
  (interactive)
  (set (make-local-variable 'end-of-defun-function) 'sh-end-of-form))

(defun sh-beginning-of-command (&optional arg)
  "Move point to successive beginnings of commands."
  (interactive "p")
  (let ((arg (or arg 1))
        (pos (point)))
    (back-to-indentation)
    (unless (eq pos (point))
      (setq arg (1- arg)))
    (while (< 0 arg)
      (forward-line (- arg))
      (setq arg (1- arg))
      ;; skip comments and empty lines and closing braces
      (let ((pos (point)))
        (if (forward-comment -1)
            (while (forward-comment -1) (forward-comment -1))
          (goto-char pos)))
      (while (or (empty-line-p)
                 (looking-at "}"))
        (forward-line -1))
      (back-to-indentation))))

(defun sh-end-of-command (&optional arg)
  "Move point to successive ends of commands."
  (interactive "p")
  (let ((arg (or arg 1))
        (pos (point)))
    (end-of-line)
    (skip-chars-backward " \t\r\n\f" (line-beginning-position))
    (unless (eq pos (point))
      (setq arg (1- arg)))
    (while (< 0 arg)
      (forward-line arg)
      (setq arg (1- arg)))
    (end-of-line)
    (skip-chars-backward " \t\r\n\f" (line-beginning-position))
    (while (or
            (empty-line-p)
            (forward-comment 1))
      (forward-line 1)
      (end-of-line))
    (skip-chars-backward " \t\r\n\f")))

(defcustom empty-line-p-chars "^[ \t\f\r]*$"
  "empty-line-p-chars"
  :type 'regexp
  :group 'convenience)

(defun empty-line-p (&optional ispec)
  "Returns t if cursor is at an empty line, nil otherwise."
  (interactive "p")
  (save-excursion
    (beginning-of-line)
    (when ispec
      (message "%s" (looking-at empty-line-p-chars)))
    (looking-at empty-line-p-chars)))

(defconst sh-beg-end-version "1.0" "
Version number of this sh-beg-end.el. ")

(defun sh-beg-end-version (&optional ispec)
  "Print and/or return sh-beg-end-version"
  (interactive "p")
  (when ispec
    (message "%s" sh-beg-end-version))
  sh-beg-end-version)

(add-hook 'sh-mode-hook 'sh-set-beginning-of-form)
(add-hook 'sh-mode-hook 'sh-set-end-of-form)

(provide 'sh-beg-end)

;;; sh-beg-end.el ends here
