;; timingup.el --- Minor mode which adds timing informations to buffer

;; Copyright (C) 2003 Paolo Gianrossi 

;; Emacs Lisp Archive Entry
;; Filename: timingup.el
;; Author: Paolo Gianrossi <paolino.gnu@disi.unige.it>
;; Maintainer: Paolo Gianrossi <paolino.gnu@disi.unige.it>
;; Version: 1.0
;; Created: 05/02/03
;; Revised: 05/12/03
;; Description: Minor mode which adds last save time, last compile 
;; time, build number, etc. information to buffer
;; URL: http://digilander.iol.it/linsky/emacs/

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

(require 'hyper-compile)

;; Insert date and time in buf
(defvar insert-time-format "%X"
  "*Format for \\[insert-time] (c.f. `format-time-string').")

(defvar insert-date-format "%x"
  "*Format for \\[insert-date] (c.f. `format-time-string').")

(defun insert-time ()
  "Insert the current time according to insert-time-format."
  (interactive "*")
  (insert (format-time-string insert-time-format
                              (current-time))))

(defun insert-date ()
  "Insert the current date according to insert-date-format."
  (interactive "*")
  (insert (format-time-string insert-date-format
                              (current-time))))


;; insert last saved time and date
(defvar writestamp-format "%x %X"
  "*Format for writestamps (c.f. `format-time-string').")

(defvar writestamp-prefix "^Last saved:[ \t]?"
  "*Unique string identifying start of writestamp.")

(defvar writestamp-suffix "$"
  "*String that terminates a writestamp.")

(defun update-writestamps ()
  "Find writestamps and replace them with the current time."
  (save-excursion
    (save-restriction
      (save-match-data
        (widen)
        (goto-char (point-min))
        (let ((regexp (concat  writestamp-prefix
                              "\\(.*\\)"
                               writestamp-suffix
			       )))
          (while (re-search-forward regexp nil t)
            (replace-match (format-time-string writestamp-format
                                               (current-time))
                           t t nil 1))))))
  nil)


;; insert last compiled time and date (uses hypercompile)

(defvar compilestamp-format "%x %X"
  "*Format for compilestamps (c.f. `format-time-string').")

(defvar compilestamp-prefix "^Last compiled:[ \t]?"
  "*Unique string identifying start of compilestamp.")

(defvar compilestamp-suffix "$"
  "*String that terminates a compilestamp.")

(defun update-compilestamps (&optional pref)
  "Find compilestamps and replace them with the current time."
  (save-excursion
    (save-restriction
      (save-match-data
        (widen)
        (goto-char (point-min))
        (let ((regexp (concat  compilestamp-prefix
                              "\\(.*\\)"
                               compilestamp-suffix
			       )))
	  (if (not (null pref))
	      (setq regexp (concat pref "\\(.*\\)" "\.")))
          (while (re-search-forward regexp nil t)
            (replace-match (format-time-string compilestamp-format
                                               (current-time))
                           t t nil 1)
	    )
	  (if compilestamp-add-build-num
	      (update-build-number))
	  ))))
  nil)


;; build numbers when compile

(defvar compilestamp-add-build-num nil
  "*Flags whether an incremental build number should be inserted and kept up to date by \\[update-compilestamps]."
)

(make-local-variable 'compilestamp-add-build-num)

(defvar compilestamp-build-prefix "^Build:[ \t]?"
"*Prefix for compilestamp build number."
)

(defvar compilestamp-build-suffix "$"
"*Suffix for compilestamp build number."
)

(defun update-build-number ()
  (save-excursion
    (save-restriction
      (save-match-data
        (widen)
        (goto-char (point-min))
        (let ((regexp (concat  "\\(" compilestamp-build-prefix "\\)"
                              "\\([ \t]*\\)\\([0-9]*\\)\\([ \t]*\\)"
                               "\\(" compilestamp-build-suffix "\\)"
			       )) incpt pt)
	  (while (re-search-forward regexp nil t)
	    (setq pt (point))
	    (setq incpt (progn (goto-char (match-beginning 3))
				       (increment-num-at-point)))
	  (goto-char pt)
	  (replace-match incpt
			 t t nil 3)
	  )))))
  nil)

(defun increment-num-at-point ()
  (save-excursion
    (let ((begin (point)) numstring)
      (next-line 1)
      (setq numstring (buffer-substring begin (point)))
      (number-to-string (1+ (string-to-number numstring))))))


;; make it a minor mode

(defvar timing-mode nil
  "Mode variable for timing minor mode.")
(make-variable-buffer-local 'timing-mode)

(defun timing-mode (&optional arg)
  "Timing minor mode."
  (interactive "P")
  (setq timing-mode
        (if (null arg)
            (not timing-mode)
          (> (prefix-numeric-value arg) 0)))
  (make-local-hook 'after-change-functions)
  (make-local-hook 'local-write-file-hooks)
  (if timing-mode
      (progn
	(add-hook 'after-change-functions 'remember-change-time)
	(add-hook 'local-write-file-hooks 'update-writestamps)
	(add-hook 'hyper-after-compile-hook 'update-compilestamps)
	)
    (remove-hook 'after-change-functions 'remember-change-time)
    (remove-hook 'local-write-file-hooks 'update-writestamps)
    (remove-hook 'hyper-after-compile-hook 'update-compilestamps)
    ))


(if (not (assq 'timing-mode minor-mode-alist))
    (setq minor-mode-alist
          (cons '(timing-mode " Timing")
                minor-mode-alist)))

(provide 'timestamp)
