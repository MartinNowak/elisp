;;; iswitchb-pnw-highlight.el --- Highlighting extension for iswitchb

;; Copyright (C) 2007 Per Nordlöw

;; Author: Per Nordlöw
;; Keywords; iswitchb, highlight

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;;_ + Commentary:

;; highlight elements in the iswitchb buffer list based on matching
;; MODE-NAME
;;
;; Example:
;;   by default, the following MODES are highlighted w/in the iswitchb
;;   buffer list

;;;_ + History:

;;; Code:

(require 'em-ls)			;needed for face inheriting
(require 'iswitchb)

(defface saint/iswitchb-pnw-highlight-1-face
  '((t (:inherit eshell-ls-directory-face)))
  "*Face used to highlight directories in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-2-face
  '((((class color) (background dark)) (:foreground "aquamarine" :bold nil))
    (((class color) (background light)) (:foreground "aquamarine" :bold nil))
    (t ()))
  "*Face used to highlight in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-3-face
  '((((class color) (background dark)) (:foreground "medium sea green" :bold nil))
    (((class color) (background light)) (:foreground "dark sea green" :bold nil))
    (t ()))
  "*Face used to highlight in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-4-face
  '((t (:inherit font-lock-warning-face)))
  "*Face used to highlight in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-5-face
  '((((class color) (background dark)) (:foreground "DeepSkyBlue1" :bold nil))
    (((class color) (background light)) (:foreground "DeepSkyBlue4" :bold nil))
    (t ()))
  "*Face used to highlight in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-6-face
  '((((class color) (background dark)) (:foreground "dim gray" :bold nil))
    (((class color) (background light)) (:foreground "dim gray" :bold nil))
    (t ()))
  "*Face used to highlight in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-7-face
  '((t (:inherit eshell-ls-executable-face)))
  "*Face used to highlight in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-8-face
  '((t (:inherit font-lock-doc-face)))
  "*Face used to highlight documentation (Man-pages) in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-9-face
  '((t (:inherit font-lock-variable-name-face :bold t)))
  "*Face used to highlight documentation (Info) in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-10-face
  '((t (:inherit font-lock-comment-face :bold nil)))
  "*Face used to highlight text in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-11-face
  '((((class color) (background dark)) (:foreground "orange red" :bold nil))
    (((class color) (background light)) (:foreground "firebrick" :bold nil))
    (t ()))
  "*Face used to highlight Makefiles in the iswitchb buffer"
  :group 'iswitchb)

(defface saint/iswitchb-pnw-highlight-12-face
  '((t (:inherit eshell-ls-special-face :bold nil)))
  "*Face used to highlight special files in the iswitchb buffer"
  :group 'iswitchb)

(defcustom saint/iswitchb-pnw-highlight-modes-alist
  '(("^Dired" . 1)
    ("^Outline" . 2)
    ("^Emacs-Lisp" . 3)
    ("^EShell" . 4)
    ("^C" . 5)
    ("^Buffer Menu" . 6)
    ("^Shell-script" . 7)
    ("^Man" . 8)
    ("^Info" . 8)
    ("^Debugger" . 9)
    ("^Text" . 10)
    ("^Makefile" . 11)
    ("^Default-Generic$" . 12)
    ("^Etc-.*-Generic$" . 12)
    )
  "*List specifying the mode name to face mapping for iswitchb.
Each entry specifies a map and is a list of the form of:
\(MODE-REGEXP FACE-NUMBER\) Resolves FACE-NUMBER to
saint/iswitchb-pnw-highlight-FACE-NUMBER-face."
  :type '(repeat sexp)
  :group 'iswitchb)

(defcustom saint/iswitchb-pnw-highlight-modes t
  "*Non-nil means that `iswitchb' will highlight matching modes as defined by
`saint/iswitchb-pnw-highlight-modes-list'."
  :type 'boolean
  :group 'iswitchb)

(defun saint/iswitchb-pnw-highlight-buflist ()
  "Highlight the buffer list based on the major mode that the buffer
is in.  This is a function to be hooked on to
`iswitchb-make-buflist-hook'.  Loops through `iswitchb-temp-buflist'
and retrieves the mode-name of each buffer.  Compares the buffer name
to the `saint/iswitch-highlight-modes-list' and if there's a match,
then replace the text-property of the buffer name string in the
buflist."
  (let ((my-highlight-buflist
         (mapcar
          (lambda (buf)
            (save-excursion
              (set-buffer buf)
              (let* ((match
                      (delq nil
                            (mapcar
                             (lambda (x)
                               (if (and (consp x)
                                        (string-match (car x) mode-name))
                                   (cdr x)))
                             saint/iswitchb-pnw-highlight-modes-alist)))
                     (face-num (if (and match
                                        (and (listp match)))
                                   (car match)
                                 0)))
                (cond
                 ((= face-num 1)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-1-face))
                 ((= face-num 2)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-2-face))
                 ((= face-num 3)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-3-face))
                 ((= face-num 4)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-4-face))
                 ((= face-num 5)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-5-face))
                 ((= face-num 6)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-6-face))
                 ((= face-num 7)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-7-face))
                 ((= face-num 8)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-8-face))
                 ((= face-num 9)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-9-face))
                 ((= face-num 10)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-10-face))
                 ((= face-num 11)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-11-face))
                 ((= face-num 12)
		  (propertize buf 'face 'saint/iswitchb-pnw-highlight-12-face))
                 (t buf)
                 ))))
          iswitchb-temp-buflist)))
    (setq iswitchb-temp-buflist my-highlight-buflist)))

(add-hook 'iswitchb-make-buflist-hook 'saint/iswitchb-pnw-highlight-buflist)

(provide 'iswitchb-pnw-highlight)

;;; iswitchb-pnw-highlight.el ends here

