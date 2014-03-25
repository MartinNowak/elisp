;; super-fold.el --- Minor mode which adds cool folding capabilities to Emacs
 
;; Copyright (C) 2003 Paolo Gianrossi 

;; Emacs Lisp Archive Entry
;; Filename: super-fold.el
;; Author: Paolo Gianrossi <paolino.gnu@disi.unige.it>
;; Maintainer: Paolo Gianrossi <paolino.gnu@disi.unige.it>
;; Version: 1.0
;; Created: 02/10/03
;; Revised: 19/11/03
;; Description: Minor mode which adds in-buffer folding capabilities
;; to Emacs.
;; URL: http://yersinia.org/homes/paolino/emacs/

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

;;; Commentary:
;;  Super folding makes possible to selectively hide portions of the buffer. It
;;  allows to fold a region,  a function or a block
;;  included in commented delimiters.

;;; TODOs and known bugs:
;; * when super-fold-defun is invoked from outside a function, it folds the 
;;   function right before the point. Don't really know if this is a bug or not...
;;
;; * unfolding of single folded block needs to have point in a precise position. 
;;   Possible positions are two, though...
;; 
;; * need a customizer interface
;;
;; * need a function to fold comments. that should be easy in C-like comment blocks,
;;   but in single line comment blocks (as lisp,e.g.), it should fold all commented
;;   lines of a block as a single fold.
;;
;; * need a "fold-dwim" function to do what i mean about folding at point (e.g., if 
;;   on a fold, unfold; if between delims, fold-delims, if a region is selected, fold
;;   region, and so on).


(defvar super-fold-sdelim "{{{"
  "*Super Fold folding starting delimiter."
)

(defvar super-fold-edelim "}}}"
  "*Super Fold folding ending delimiter."
)

(defvar super-folded-string "...\n"
  "*String that will appear instead of folded text."
)



(defun super-fold-region (beg end)
  "Fold selected region."
  (interactive "r")
  (let ((ovl (make-overlay beg end)))
    (overlay-put ovl 'evaporate t)
    (overlay-put ovl 'invisible t)
    (overlay-put ovl 'intangible t)
    (overlay-put ovl 'super-folding t)
    (overlay-put ovl 'before-string super-folded-string)
    )
)

(defun super-fold-delim ()
  "Fold between delimiters (`super-fold-sdelim' and `super-fold-edelim')."
  (interactive)
  (let (beg end (comm-delim-open (concat comment-start super-fold-sdelim)) 
	    (comm-delim-close (concat comment-start super-fold-edelim)))
    (search-backward comm-delim-open)
    (if comment-end
	(search-forward comment-end)
      (forward-char 1))
;;    (forward-line 1)
    (setq beg (point))
    (search-forward comm-delim-close)
    ;; (forward-line -1)
    (if comment-end
	(search-forward comment-end)
      (end-of-line)
      )
    (setq end (point))
    (super-fold-region beg end)
    )
)

(defun super-fold-defun ()
  "Fold function at point."
  (interactive)
  (let (beg end)
    (beginning-of-defun)
    (setq beg (point))
    (end-of-defun)
    (setq end (point))
    (super-fold-region beg end)
    )
)
 
(defun super-unfold ()
  "Unfold folding."
  (interactive)
  (let ((overlays (overlays-in (line-beginning-position)(line-end-position))))
    (while overlays
      (let ((ovlay (car overlays)))
	(if (overlay-get ovlay 'super-folding)
	    (delete-overlay ovlay)
	))
      (setq overlays (cdr overlays))))
  )

(defun super-unfold-all ()
  "Unfold all folded text in buffer."
  (interactive)
  (let ((overlays (overlays-in 0 (point-max))))
    (while overlays
      (let ((ovlay (car overlays)))
	(if (overlay-get ovlay 'super-folding)
	    (delete-overlay ovlay)
	  ))
      (setq overlays (cdr overlays))))
  )

(defun super-fold-all-delims ()
  "Fold text between all `super-fold-sdelim' and `super-fold-edelim'."
  (interactive)
  (goto-char 0)
  (while (search-forward (concat comment-start super-fold-sdelim) nil t)
    (super-fold-delim)
    )
  )

(defun super-insert-delims ()
  "Insert `super-fold-sdelim' and `super-fold-edelim'.
If a region is defined, put marked text between delimiters. 
Otherwise insert delimiters with a blank line in between and
put point in the blank line."
  (interactive)
  (if (or (not mark-active) (equal (region-beginning) (region-end)))
      (progn
	(insert (concat comment-start super-fold-sdelim " " comment-end "\n\n" comment-start 
			super-fold-edelim comment-end))
	(forward-line -1))
    (let ((beg (region-beginning)) (end (region-end)))
      (goto-char beg)
      (insert (concat comment-start super-fold-sdelim " " comment-end))
      (goto-char (+ (length (concat comment-start super-fold-sdelim " " comment-end )) end))
      (insert (concat comment-start super-fold-edelim " " comment-end )))
    )
  )

(defvar super-fold-mode nil
  "Mode variable for super-fold minor mode.")
(make-variable-buffer-local 'super-fold-mode)

(defvar super-fold-mode-map (make-sparse-keymap)
  "super-fold minor mode keymap."
  )

(defvar super-fold-mode-prefix-map (make-sparse-keymap)
  "Keymap for super-fold Minor Mode after `mmm-mode-prefix-key'.")

(defun super-fold-define-key (key binding)
  (define-key super-fold-mode-prefix-map
    (vector key)
    binding)
  )

(defvar super-fold-mode-prefix-key [(control ?c)\\]
"*Minor mode prefix key for super-fold-mode."
)

(defun super-fold-mode (&optional arg)
  "super-fold minor mode.

This minor mode allows you to fold portions of buffer within the buffer.

\\[super-fold-mode] with no prefix, toggles the mode;
with positive prefix (or argument) turns the mode on;
with negative prefix (or argument) turns the mode off.

When this mode is on, you can: \\[super-fold-region] with a selected region;
\\[super-fold-defun] inside a function to fold a function's body;
\\[super-fold-delim] to fold between closest `super-fold-sdelim' and `super-fold-edelim';
\\[super-unfold] to unfold a folded item;

\\[super-fold-all-delims] to fold all delimited groups;
\\[super-unfold-all] to unfold all foldings;
\\[super-insert-delims] to insert smartly delimiters.

\\{super-fold-mode-map}
INSTALLATION:
To install super-fold-mode:
 - Copy the `super-fold.el' file in a directory of your `load-path'; possibly compile it;
 - `(require 'super-fold)';
 - \\[super-fold-mode] to toggle it.

"
  (interactive "P")
  (setq super-fold-mode
        (if (null arg)
            (not super-fold-mode)
          (> (prefix-numeric-value arg) 0)))
  
  (make-local-hook 'after-folding-hook)	
  (make-local-hook 'before-folding-hook)
  (make-local-hook 'before-unfolding-hook)
  (make-local-hook 'after-unfolding-hook)
  (if (not (assq 'super-fold-mode minor-mode-alist))
      (setq minor-mode-alist
	    (cons '(super-fold-mode " SuperFold")
		  minor-mode-alist)))

  (super-fold-define-key ?] 'super-unfold)
  (super-fold-define-key ?[ 'super-fold-delim)
  (super-fold-define-key ?\{ 'super-fold-all-delims)
  (super-fold-define-key ?\} 'super-unfold-all)
  (super-fold-define-key ?\( 'super-fold-defun)
  (super-fold-define-key ?\` 'super-fold-region)
  (super-fold-define-key ?\; 'super-insert-delims)

  ;; Put it all onto the prefix key
  (define-key super-fold-mode-map super-fold-mode-prefix-key super-fold-mode-prefix-map)
  
  (add-to-list 'minor-mode-map-alist (cons 'super-fold-mode super-fold-mode-map))
)

(provide 'super-fold)




