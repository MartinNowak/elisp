;; trimwhite.el --- Save buffer without trailing spaces

;; Copyright (C) 2003 Paolo Gianrossi 

;; Emacs Lisp Archive Entry
;; Filename: trimwhite.el
;; Author: Paolo Gianrossi <paolino.gnu@disi.unige.it>
;; Maintainer: Paolo Gianrossi <paolino.gnu@disi.unige.it>
;; Version: 1.0
;; Created: 10/11/03
;; Revised: 10/11/03
;; Description: Function to save buffer removing trailing spaces first

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

;; USAGE: put file in load-path
;; (load-library "trimwhite")
;; (global-set-key "\C-x\C-s" 'save-no-blanks-at-eol) ; or whatever else
;; use at pleasure ;)





(defun save-no-blanks-at-eol (&optional arg)
  (interactive "P")
  (save-excursion
    (goto-char 0)
    (perform-replace "[ \t]*$" "" nil t nil)
    (save-buffer arg)
    ))
