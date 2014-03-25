;;; html-pagetoc.el --- MS Windows style feeling

;;;;;;;; PLEASE CHANGE THE NAME TO w32-feeling.el

;; Copyright (C) 2004 by Lennart Borgman

;; Author:     Lennart Borgman <lennart DOT borgman DOT 073 AT student DOT lu DOT se>
;; Created: 2004-10-12
;; Version: 0.8
;; Keywords: tools hypermedia html

;; This file is not part of Emacs

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; html-pagetoc.el has functions for building a table of contents for
;; a single html file.

;; To use this module put it in emacs load-path and enter the line
;; below in your .emacs:
;;
;;    (require 'html-pagetoc)
;;
;; Then when editing a html file put your cursor where you want the
;; table of contents and do M-x html-pagetoc-insert-toc.

;;; Code:

;;(define-key global-map [f2] 'eval-buffer)
;;(define-key global-map [f3] 'html-pagetoc-insert-toc)

(defgroup html-pagetoc nil
  "Html page local table of contents settings"
  :group 'hypermedia)

(defcustom html-pagetoc-max 3
  "Default for max header level"
  :group 'html-pagetoc)

(defun html-pagetoc-insert-toc(min-level max-level)
  (interactive (let* ((maxstr)
		       (max 0)
		       (min 1)
		       (prmax (format "Max header level (%s): " html-pagetoc-max))
		       (prmax2 (concat "Please give an integer 1-5. " prmax))
		       (prmin "Include header level 1? ")
		       )
		  (while (= max 0)
		    (setq maxstr (read-string prmax))
		    (if (equal maxstr "") 
			(setq max html-pagetoc-max)
		      (when (not (string-match "\\." maxstr))
			(setq max (string-to-int maxstr)) ))
		    (when (> max 5) (setq max 0))
		    (when (< max 0) (setq max 0))
		    (setq prmax prmax2) )
		  (when (> max 1) 
		    (when (not (y-or-n-p prmin)) (setq min 2)))
		  (list min max)))
		    
  (let ((curr-buffer (current-buffer))
	(toc-buffer (get-buffer-create "*html-pagetoc*"))
	(toc)
	)
    (save-excursion
      (set-buffer toc-buffer)
      (erase-buffer))
    (with-temp-buffer
      (insert-buffer curr-buffer)
      (replace-regexp "<!--.*?-->" "")
      ;;(message "%s" (buffer-string))
      (save-excursion 
	(goto-char (point-min))
	(let ((b (current-buffer))
	      (standard-output toc-buffer)
	      (level (- min-level 1))
	      (skip-level (- min-level 1))
	      (prev-level)
	      )
	  (princ "<!-- Table of contents BEGIN -->\n")
	  (princ "<div style=\"margin-left:5em;\">\n")
	  (princ "<!-- PLEASE NOTE: Style tag should be head tag (but it still works) -->\n")
	  (princ "<style type=\"text/css\">\n")
	  (princ "  ul.toc {\n")
  	  (princ "    list-style-type: none;\n")
  	  (princ "    margin-top: 0em;\n")
  	  (princ "    margin-left: 0em;\n")
  	  (princ "    padding-left: 1em;\n")
	  (princ "  }\n")
	  (princ "</style>\n")
	  (princ "<strong>Contents:</strong>\n")
	  (while (re-search-forward "<h\\([1-9]\\)\\([^>]*\\)>\\(.*?\\)</h[1-9]>" nil t)
	    (let ((m0 (match-string 0))
		  (m1 (match-string 1))
		  (m2 (match-string 2))
		  (title (match-string 3))
		  (id)
		  (new-level)
		  )
	      ;;(setq title (concat title m0))
	      (setq new-level (string-to-number m1))
	      (when (and (<= new-level max-level) (<= min-level new-level))
		(setq prev-level level)
		(setq level new-level)
		(while (< prev-level level)
		  (princ (make-string (* (- prev-level skip-level) 4) 32))
		  (when (> prev-level (- min-level 1)) (princ "<li>"))
		  (princ "<ul class=\"toc\">\n")
		  (setq prev-level (+ prev-level 1)))
		(while (> prev-level level)
		  (princ (make-string (* (- prev-level skip-level) 4) 32))
		  (princ "</ul></li>\n")(setq prev-level (- prev-level 1)))
		(when (nth 3 (match-data t))
		  (when (string-match "id=\"\\([^\"]*\\)\"" m2)
		    (setq id (substring m2 (match-beginning 1) (match-end 1)))))
		(princ (make-string (* (- level skip-level) 4) 32))
		(princ "<li>")
		(if id 
		    (princ (format "<a href=\"#%s\">%s</a>" id title))
		  (princ title))
		(princ "</li>\n")
		)))
	  ;;(while (> level 0)
	  (while (> level (- min-level 1))
	    (setq level (- level 1))
	    (princ (concat (make-string (* (- level skip-level) 4) 32) "</ul>"))
	    (when (> level (- min-level 1)) (princ "</li>"))
	    (princ "\n"))
	  (princ "</div>\n")
	  (princ "<!-- END of Table of contents -->\n")
	  (save-excursion
	    (set-buffer toc-buffer)
	    (setq toc (buffer-string)))
	  ) 
	) ; save-excursion
      ) ; with-temp-buffer
    (when toc
      ;;(backward-char 1)
      (set-mark (point))
      (insert toc)
      ;;(setq mark-active t)
      (setq deactivate-mark nil)
      (message "Toc created"))
    )
  )

;;(message "evaled")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Ready:
(provide 'html-pagetoc)

;;; html-pagetoc.el ends here
