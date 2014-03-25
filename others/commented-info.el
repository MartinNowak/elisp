;; commented-info.el --- Inserts an information/license header in the 
;; buffer

;; Copyright (C) 2003 Paolo Gianrossi 

;; Emacs Lisp Archive Entry
;; Filename: commented-info.el
;; Author: Paolo Gianrossi <paolino.gnu@disi.unige.it>
;; Maintainer: Paolo Gianrossi <paolino.gnu@disi.unige.it>
;; Version: 2.0
;; Created: 11/18/02
;; Revised: 05/12/03
;; Description: Inserts an information/license header in the buffer
;; URL: http://digilander.iol.it/linsky/

;;  This file is not part of GNU Emacs.

;; This program is free software;  you can redistribute it and/or 
;; modify it under the terms of the GNU General Public License as  
;; published by the Free Software Foundation; either version 2 of the 
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but 
;; WITHOUT ANY WARRANTY; without even the implied warranty of 
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR  PURPOSE.  See the  GNU 
;; General Public License for more details.

;; You  should  have received  a copy of the GNU General Public 
;; License  along with this program; if not, write to the Free 
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 
;; 02111-1307, USA.

;; Installation:

;; just compile commented-info.el and put it in your load-path
;; copy license files to a suitable directory (default is ~/emacs/licenses/)
;; in your .emacs add
;; (load-library "commented-info")
;; possibly bind `insert-license-header' to some key.



(defvar license-file-dir "~/emacs/licenses/" 
"*Directory where the license files are found."
)
(defvar license-file-name "gpl-header"
"*File name of license file used."
)
(defvar license-file (concat license-file-dir license-file-name)
"*Full pathname of license file used."
)
(defvar license-box-border 1
"*Width of license box border."
)
(defvar license-right-column 67
"*Column after which license must be filled."
)

(defvar comment-box-function 'comment-region
"*Function to be used to build the comment box.
Should take three args: BEG, END, BORDER.
BEG and END delimit the region which must be commented, 
BORDER tells how large the box border should be.
"
)

(defvar commented-info-replace-alist '(
				       ("%L" . (drop-in-license))
				       ("%f" . (throw-in-file-or-buffer-name))
				       ("%F" . (file-name-nondirectory (buffer-file-name)))
				       ("%n" . (file-name-sans-extension      
					      	(file-name-nondirectory (buffer-file-name))))
				       ("%u" . user-full-name)
				       ("%e" . user-mail-address)
				       ("%Y" . (format-time-string "%Y"))
				       ("%t" . (format-time-string "%X"))
				       ("%d" . (format-time-string "%x"))
				       ("%w" . (insert-desc))
				       ("%v" . (insert-vers))
				       ))

(defvar commented-info-format-string 
  "%f - %w \n v. %v \n Copyright (C) %Y %u - All rights reserved \n by %u <%e> \n %L \nLast compiled: .\n"
  )



(defun insert-license-header ()
  "Inserts a comment box with the license notes in current buffer."
  (interactive)
  (save-excursion
    (let ((old-buf (current-buffer)) (new-buf (generate-new-buffer "*License*")) 
		      (rplc commented-info-replace-alist) (text commented-info-format-string) )
      (goto-char (point-min))
      (while rplc
	(while (string-match (car (car rplc)) text)
	  (setq text (replace-match (eval (cdr (car rplc))) t nil text)))
	(setq rplc (cdr rplc)) )

      (switch-to-buffer new-buf)	     
      (insert text)
      (goto-char (point-min))
      (while (< (point) (point-max))
	(forward-word 1)
	(if (> (current-column) license-right-column)
	    (progn (forward-word -1)
		   (insert "\n")
		   )
	  )
	)
      (setq text (buffer-string))
      (switch-to-buffer old-buf)
      (kill-buffer new-buf)
      (goto-char (point-min))
      (insert text)
      (let ((tmpfnc (list comment-box-function (point-min) (point) license-box-border)))
	(eval tmpfnc)
	)
;;      (insert "\n\n")
      )))

(defun set-license-box-border (border)
  "Sets `license-box-border' variable."
  (interactive "nBorder width: ")
  (setq license-box-border border)
)

;; set license file for license header

(defun set-license-file ()
  "Sets `license-file' variable."
  (interactive)
  (let (fname))
  (setq fname (read-file-name "License file: " license-file-dir nil t nil))
  (setq license-file fname))



(defun drop-in-license ()
  (insert "\n")
  (let ((old-buf (current-buffer)) (new-buf (generate-new-buffer "*LicenseF*")) text ) 
	(switch-to-buffer new-buf)
	(insert-file-contents license-file)
	(insert "\n")
	(setq text (buffer-string))
	(kill-buffer new-buf)
	(switch-to-buffer old-buf)
	text
  ))

(defun throw-in-file-or-buffer-name()
  (if (buffer-file-name)
      (file-name-nondirectory (buffer-file-name))
    (buffer-name)
    )
)


(defun insert-desc()
  (read-from-minibuffer "Short Description: "))

(defun insert-vers()
  (read-from-minibuffer "Version: "))

