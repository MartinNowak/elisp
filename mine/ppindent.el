;;; ppindent.el --- Indents C preprocessor directives

;; Copyright (C) 2007 Free Software Foundation, Inc.

;; Author: Craig McDaniel <craigmcd@gmail.com>
;; Keywords: languages, c
;; Maintainer: Craig McDaniel <craigmcd@gmail.com>

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; PPINDENT indents C-preprocessor statements depending on the current
;; #if..., #el.., #endif level. It only modifies lines with "#" as the
;; first non-blank character and therefore does not conflict with the
;; normal C indentation. Unlike a true indent, it inserts the
;; requisite number of spaces after, rather than before the "#"
;; character. This type of preprocesor indent is commonly used to
;; provide the most compatibility with different C-compilers.
;;
;; Example:

;;        #ifdef WOO
;;        ....
;;        #if defined(X) && !defined(Y)
;;        #ifdef Q8
;;        ...
;;        #else
;;        ...
;;        ....
;;        #elif defined (Z)
;;        ....
;;        #endif
;;        #endif
;;        #endif

;; After "M-x ppindent-c" becomes:

;;        #ifdef WOO
;;        ....
;;        #  if defined(X) && !defined(Y)
;;        #    ifdef Q8
;;        ...
;;        #    else
;;        ...
;;        ....
;;        #    elif defined (Z)
;;        ....
;;        #    endif
;;        #  endif
;;        #endif

;; Two functions are provided: PPINDENT-C indents as described
;; above. PPINDENT-H does not indent the first level, assuming that
;; .h/.hpp files use an #ifdef guard around the entire file.

;; You can customize PPINDENT-INCREMENT if you want to use something
;; other than 2 spaces for the indent.

;;; History:

;; 2007-01-19 WCM Initial version

;;; Code:

(provide 'ppindent)

(defcustom c++-source-ext-list '( "cc" "C" "CC" "cpp" "cxx" "c++" "c+" )
  "Extensions for C++ compileable source files."
  :type '(repeat string)
  :group 'compile-c++)

(defcustom c++-headers-ext-list '( "H" "hh" "HH" "h++" "h+" "h" "hpp" "hxx" )
  "Extensions for C++ headers source files."
  :type '(repeat string)
  :group 'compile-c++)

(defgroup pp-indent nil
  "Indent C preproccessor directives."
  :group 'c)

(defcustom ppindent-increment 2
  "Number of spaces per indention level.

Used in C pre-processor indent functions ppindent-c and ppindent-h"
  :type 'number
  :group 'pp-indent)

(defun starts-withp (str prefix)
  "str starts with prefix"
  (eql (compare-strings prefix nil nil str nil (length prefix)) t))

(defun my-make-string (length init)
  "just like make-string, but makes an empty string if length is negative"
  (when (minusp length)
    (setf length 0))
  (make-string length init))

(defcustom ppindent-modes '(c-mode c++-mode objc-mode java-mode csharp-mode d-mode)
  "List of major modes were ppindent should be automatically
  active.")

(defun ppindent-region (start end depth)
  (if (or (eq start (point-min))        ;if we are including beginning or
          (eq end (point-max)))         ;or end
      (setq depth                       ;
            (if (or (string-match (concat "\\."
                                          (regexp-opt c++-headers-ext-list)
                                          "\\'"
                                          )
                                  buffer-file-name)
                    )
                (- ppindent-increment) 0)))
  (let* ((cnt depth))
    (goto-char start)
    (while (re-search-forward "^[ \t]*#[ \t]*\\(.*\\)" end t)
      (cond ((starts-withp (match-string-no-properties 1) "if")
             (replace-match (concat "#" (my-make-string cnt ?\s) "\\1"))
             (incf cnt ppindent-increment))
            ((starts-withp (match-string-no-properties 1) "el")
             (when (< (- cnt ppindent-increment) depth)
               (throw 'err `(,(line-number-at-pos) "Unmatched #else or #elif")))
             (replace-match (concat "#" (my-make-string
                                         (- cnt ppindent-increment)
                                         ?\s) "\\1")))
            ((starts-withp (match-string-no-properties 1) "endif")
             (when (< (- cnt ppindent-increment) depth)
               (throw 'err `(,(line-number-at-pos) "Unmatched #endif")))
             (decf cnt ppindent-increment)
             (replace-match (concat "#" (my-make-string cnt ?\s) "\\1")))
            (t
             (replace-match (concat "#" (my-make-string cnt ?\s) "\\1")))))))

(defun ppindent-buffer (depth)
  (let ((depth
         (if (or (string-match (concat "\\."
                                       (regexp-opt c++-headers-ext-list)
                                       "\\'"
                                       )
                               buffer-file-name)
                 )
             (- ppindent-increment) 0))
        (result (catch 'err (save-excursion
                              (ppindent-region (point-min) (point-max) depth)))))
    (when result
      (goto-line (car result))
      (error "Error: %s" (cadr result)))))

(defadvice c-indent-region (after c-ppindent-region activate)
  (if (member major-mode ppindent-modes)
      (let ((transient-mark-mode nil))
        (ppindent-region (region-beginning)
                         (region-end) 0))))
(ad-activate 'c-indent-region)
