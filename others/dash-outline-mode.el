;;; dash-outline-mode.el --- A major-mode similar to outline-mode

;; $Id: $

;; Copyright (C) 2000-2003 Free Software Foundation, Inc.
;; Copyright (C) 2000-2003 Kevin A. Burton (address@bogus.example.com)

;; Author: Kevin A. Burton (address@bogus.example.com)
;; Maintainer: Kevin A. Burton (address@bogus.example.com)
;; Location: http://relativity.yi.org
;; Keywords: 
;; Version: 1.0.0

;; This file is [not yet] part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 2 of the License, or any later version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program; if not, write to the Free Software Foundation, Inc., 59 Temple
;; Place - Suite 330, Boston, MA 02111-1307, USA.

;;; Commentary:

;; Mode which is similar to `outline-mode' but matches 'dash' outlines.
;;
;; Specifically:
;;
;; - is a beginning
;;     - is another level
;;         - is another level
;;
;; This is the way I think of outlines.  I assume some people would agree.
;;
;; NOTE: If you enjoy this software, please consider a donation to the EFF
;; (http://www.eff.org)

;;; TODO:
;;

;;; Code:

(defcustom dash-outline-regexp "^\\([ ]*\\)-.*"
  "*Regular expression to match the beginning of a heading. Hide Any line whose
beginning matches this regexp is considered to start a heading.  The recommended
way to set this is with a Local Variables: list in the file it applies to.  See
also `outline-heading-end-regexp'."
  :group 'dash-outline
  :type 'regexp)

(defcustom dash-outline-level-width 4
  "*The width that an outline level (in spaces) should be. n*1 == first level,
  n*2 == second level, etc."
  :group 'dash-outline
  :type 'integer)

(define-derived-mode dash-outline-mode outline-mode "DashOutline"
  "Mode which is similar to `outline-mode' but matches 'dash' outlines.

Specifically:

- - is a beginning
    - is another level
        - is another level

This is the way I think of outlines.  I assume some people would agree."

  (hs-minor-mode)

  (make-local-variable 'outline-level)
  (setq outline-level 'dash-outline-level)
  
  (make-local-variable 'outline-regexp)
  (setq outline-regexp dash-outline-regexp))

(defun dash-outline-level ()
  "Return the depth to which a statement is nested in the outline.
Point must be at the beginning of a header line.  This is actually either the
level specified in `outline-heading-alist' or else the number of characters
matched by `outline-regexp'."
  (save-excursion
    (if (not (looking-at dash-outline-regexp))
        ;; This should never happen
        1000
      (round (/ (- (match-end 1) (match-beginning 1)) 
dash-outline-level-width)))))

(provide 'dash-outline-mode)

;;; dash-outline-mode.el ends here
