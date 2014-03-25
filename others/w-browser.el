;;; w-browser.el --- Run Windows application associated with a file.
;;; FILE SHOULD BE NAMED w32-browser.el, but EmacsWiki doesn't like that.
;; 
;; Filename: w32-browser.el
;; Description: 
;; Author: Emacs Wiki, Drew Adams
;; Maintainer: Drew Adams
;; Copyright 
;; Created: Thu Mar 11 13:40:52 2004
;; Version: $Id$
;; Last-Updated: Tue Sep 21 18:39:19 2004
;;           By: dradams
;;     Update #: 94
;; Keywords: mouse, dired, w32, explorer
;; Compatibility: GNU Emacs 21.x, GNU Emacs 20.x
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Commentary: 
;; 
;;    Run Windows application associated with a file.
;;
;; `w32-browser' & `dired-w32-browser' are from the Emacs Wiki.
;;
;; I modified `w32-browser' to `find-file' if it cannot`w32-shell-execute'.
;;
;; I wrote `dired-mouse-w32-browser'.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Change log:
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Code:

(if (not (eq system-type 'windows-nt)) nil

  (defun w32-browser (file)
    "Run default Windows application associated with FILE.
If no associated application, then `find-file' FILE."
    (or (condition-case nil
            (w32-shell-execute nil file) ; Use Windows file association
          (error nil))
        (find-file file)))              ; E.g. no Windows file association

  (defun dired-w32-browser ()
    "Run default Windows application associated with current line's file.
If file is a directory, then `dired-find-file' instead.
If no application is associated with file, then `find-file'."
    (interactive)
    (let ((file (dired-get-filename)))
      (if (file-directory-p file)
          (dired-find-file)
        (w32-browser (dired-replace-in-string "/" "\\" file)))))

  (defun dired-mouse-w32-browser (event)
    "Run default Windows application associated with file under mouse click.
If file is a directory or no application is associated with file, then
`find-file' instead."
    (interactive "e")
    (let (file)
      (save-excursion
        (set-buffer (window-buffer (posn-window (event-end event))))
        (save-excursion
          (goto-char (posn-point (event-end event)))
          (setq file (dired-get-filename))))
      (select-window (posn-window (event-end event)))
      (if (file-directory-p file)
          (find-file (file-name-sans-versions file t))
        (w32-browser (file-name-sans-versions file t)))))

;;; Cannot use this.
;;; For some reason, only one or two of the files get opened.
;;;;;   (defun dired-multiple-w32-browser ()
;;;;;     "Run default Windows applications associated with marked files."
;;;;;     (interactive)
;;;;;     (let ((files (dired-get-marked-files)))
;;;;;       (while files
;;;;;         (w32-browser (car files))
;;;;;         (setq files (cdr files)))))

  (eval-after-load "dired+"
    '(progn
       (define-key dired-mode-map [f3] 'dired-w32-browser)
       (define-key menu-bar-dired-immediate-menu [dired-w32-browser]
         '("Open Associated Application" . dired-w32-browser))
       (define-key dired-mode-map [mouse-2] 'dired-mouse-w32-browser)
;;;;;        (define-key menu-bar-dired-operate-menu [dired-w32-browser]
;;;;;          '("Open Associated Applications" . dired-multiple-w32-browser))
       )))


;;;;;;;;

(provide 'w32-browser)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; FILE SHOULD BE NAMED w32-browser.el, but EmacsWiki doesn't like that.
;;; w-browser.el ends here
