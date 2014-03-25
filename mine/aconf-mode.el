;;; -*- coding: utf-8 -*-
;;; aconf-mode.el

;; Author: Martin Buchholz (martin@xemacs.org)
;; Maintainer: Martin Buchholz
;; Keywords: languages, faces, m4, configure

;; This file is part of Autoconf

;; Copyright (C) 2001, 2006 Free Software Foundation, Inc.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; A major mode for editing autoconf input (like configure.in).
;; Derived from m4-mode.el by Andrew Csillag (drew@staff.prodigy.com)

;;; Your should add the following to your Emacs configuration file:

;;  (autoload 'aconf-mode "aconf-mode"
;;            "Major mode for editing autoconf files." t)
;;  (setq auto-mode-alist
;;        (cons '("\\.ac\\'\\|configure\\.in\\'" . aconf-mode)
;;              auto-mode-alist))

;;; Code:

;;thank god for make-regexp.el!
(defvar aconf-font-lock-keywords
  `(("\\bdnl \\(.*\\)"  1 font-lock-comment-face t)
    ("\\$[0-9*#@]" . font-lock-variable-name-face)
    ("\\b\\(m4_\\)?\\(builtin\\|change\\(com\\|quote\\|word\\)\\|d\\(e\\(bug\\(file\\|mode\\)\\|cr\\|f\\(ine\\|n\\)\\)\\|iv\\(ert\\|num\\)\\|nl\\|umpdef\\)\\|e\\(rrprint\\|syscmd\\|val\\)\\|f\\(ile\\|ormat\\)\\|gnu\\|i\\(f\\(def\\|else\\)\\|n\\(c\\(lude\\|r\\)\\|d\\(ex\\|ir\\)\\)\\)\\|l\\(en\\|ine\\)\\|m\\(4\\(exit\\|wrap\\)\\|aketemp\\|kstemp\\)\\|p\\(atsubst\\|opdef\\|ushdef\\)\\|regexp\\|s\\(hift\\|include\\|ubstr\\|ys\\(cmd\\|val\\)\\)\\|tra\\(ceo\\(ff\\|n\\)\\|nslit\\)\\|un\\(d\\(efine\\|ivert\\)\\|ix\\)\\)" . font-lock-keyword-face)
    ("^\\(\\(m4_\\)?define\\|A._DEFUN\\|m4_defun\\)(\\[?\\([A-Za-z0-9_]+\\)"
     3 font-lock-function-name-face)
    ((concat "\\(" "\"" "[^\"]*" "\"" "\\)")
     (1 font-lock-string-face)))
  "default font-lock-keywords")

(defvar aconf-mode-syntax-table nil
  "Syntax table used in autoconf mode")
(setq aconf-mode-syntax-table (make-syntax-table))
(modify-syntax-entry ?\" "\""  aconf-mode-syntax-table)
;;(modify-syntax-entry ?\' "\""  aconf-mode-syntax-table)
(modify-syntax-entry ?#  "<\n" aconf-mode-syntax-table)
(modify-syntax-entry ?\n ">#"  aconf-mode-syntax-table)
(modify-syntax-entry ?\( "()"   aconf-mode-syntax-table)
(modify-syntax-entry ?\) ")("   aconf-mode-syntax-table)
(modify-syntax-entry ?\[ "(]"  aconf-mode-syntax-table)
(modify-syntax-entry ?\] ")["  aconf-mode-syntax-table)
(modify-syntax-entry ?*  "."   aconf-mode-syntax-table)
(modify-syntax-entry ?_  "_"   aconf-mode-syntax-table)

(defvar aconf-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map '[(control c) (\;)] 'comment-region)
    map))

(defun aconf-current-defun ()
  "Autoconf value for `add-log-current-defun-function'.
This tells add-log.el how to find the current macro."
  (save-excursion
    (if (re-search-backward "^\\(m4_define\\|m4_defun\\|A._DEFUN\\)(\\[*\\([A-Za-z0-9_]+\\)" nil t)
	(buffer-substring (match-beginning 2)
			  (match-end 2))
      nil)))

;;;###autoload
(defun aconf-mode ()
  "A major-mode to edit Autoconf files like configure.ac.
\\{aconf-mode-map}
"
  (interactive)

  (make-local-variable 'add-log-current-defun-function)
  (setq add-log-current-defun-function 'aconf-current-defun)

  (make-local-variable 'comment-start)
  (setq comment-start "# ")
;;  (make-local-variable 'parse-sexp-ignore-comments)
;;  (setq parse-sexp-ignore-comments t)

;;  (setq font-lock-defaults `(aconf-font-lock-keywords nil))
  )

(provide 'aconf-mode)

;;; aconf-mode.el ends here
