;;; bytecomp-fns.el --- bytecode maintenance functions

;; Copyright (C) 1996, 97, 98, 1999 Noah S. Friedman

;; Author: Noah Friedman <friedman@splode.com>
;; Maintainer: friedman@splode.com

;; $Id: bytecomp-fns.el,v 1.3 2005/05/24 17:46:05 friedman Exp $

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, you can either send email to this
;; program's maintainer or write to: The Free Software Foundation,
;; Inc.; 51 Franklin Street, Fifth Floor; Boston, MA 02110-1301, USA.

;;; Commentary:
;;; Code:

(require 'byte-compile "bytecomp")
(require 'backquote)

;; Only used if bytecomp didn't define it already.
(defvar emacs-lisp-file-regexp
  (if (eq system-type 'vax-vms)
      "\\.EL\\(;[0-9]+\\)?$"
    "\\.el$"))

;;;###autoload
(defvar defun-compile-compile-p t
  "*If non-`nil', compile forms defined with `defun-compile'.")

;;;###autoload
(defvar bcf-byte-compile-dest-file-table nil
  "Map between Emacs Lisp source file names and compiled file names.
This table is used by the function `bcf-byte-compile-dest-file'.

Each member of this table is a cons containing a predicate and a mapping
function.  For each cell, the car is called with a single argument, a file
name.  If that function returns non-`nil', the cdr function is called
with the same argument; that function should return a name to use
as the compiled file name.  Otherwise, the next pair in this table is
tried.

Regular expression match data is saved between the call of the predicate
and map functions, so the latter can use string-match results from the
former.

Implementation note: The first element of this table is special; it is a
pointer to the tail of the table so that new records can be appended
quickly.")

;;;###autoload
(defmacro defun-compile (&rest args)
  "Define a function and optionally compile it.
Syntax is exactly like `defun', but the function body is immediately
byte-compiled if the variable `defun-compile-compile-p' is non-nil."
  (if (not defun-compile-compile-p)
      (cons 'defun args)
    (` (progn
         (defun (,@ args))
         (byte-compile '(, (car args)))
         ;; be like defun, which returns the function name, not body.
         '(, (car args))))))

;;;###autoload
(defmacro defvar-compile (&rest args)
  "Define a symbol as a variable, compiling value forms if appropriate.
Syntax is exactly like `defvar', but the initial value is scanned for
inlined functions \(lambda expressions\) which are immediately compiled
if the variable `defun-compile-compile-p' is non-nil.

This form is only useful if you know that the initial value of a defvar
will contain lambda expressions which should be byte-compiled.

In Emacs 18, defvar forms are never compiled."
  (setq args (cons 'defvar args))
  (if (and defun-compile-compile-p
           (string-lessp "19" emacs-version))
      ;; Bug in v19 bytecomp?  byte-compile-top-level is unhappy if
      ;; byte-compile-warnings is not a list, even though `t' is not only
      ;; an officially allowed value but is actually the default!
      (let ((byte-compile-warnings nil))
        (byte-compile-top-level args))
    args))

;; Todo: delete existing pred from table if action is nil.
;;;###autoload
(defun bcf-byte-compile-set-dest-file (pred action &optional prependp)
  "Register PRED and ACTION in `bcf-byte-compile-dest-file-table'.
If PRED already exists in table, replace existing action with new ACTION.
If optional third arg PREPENDP is non-nil, prepend new items to the
front of the table so they will be matched first; by default new items
are appended to the end so they are matched last."
  (let* ((table (cdr bcf-byte-compile-dest-file-table))
         (tail-ptr (car bcf-byte-compile-dest-file-table))
         (existing (assoc pred table)))
    (cond (existing
           (setcdr existing action))
          ((null bcf-byte-compile-dest-file-table)
           (setq bcf-byte-compile-dest-file-table
                 (list nil (cons pred action)))
           (setcar bcf-byte-compile-dest-file-table
                   (cdr bcf-byte-compile-dest-file-table)))
          (prependp
           (setcdr bcf-byte-compile-dest-file-table
                   (cons (cons pred action) table)))
          (t
           (nconc tail-ptr (list (cons pred action)))
           (setcar bcf-byte-compile-dest-file-table (cdr tail-ptr)))))
  bcf-byte-compile-dest-file-table)

;; Indent like save-excursion
(put 'bcf-byte-compile-set-dest-file 'lisp-indent-function 0)

;;;###autoload
(defun bcf-byte-compile-dest-file (filename)
  "Convert an Emacs Lisp source file name to a compiled file name.
This function uses `bcf-byte-compile-dest-file-table' to compute the
destination file name."
  (and (fboundp 'byte-compiler-base-file-name)
       (setq filename (byte-compiler-base-file-name filename)))
  (setq filename (file-name-sans-versions filename))

  (let ((table (cdr bcf-byte-compile-dest-file-table))
        (result nil)
        (match-data (match-data)))
    (while table
      (cond ((funcall (car (car table)) filename)
             (setq result (funcall (cdr (car table)) filename))
             (setq table nil))
            (t
             (setq table (cdr table)))))
    ;; Default is simply to replace .el extension with .elc
    (and (null result)
         (string-match emacs-lisp-file-regexp filename)
         (setq result
               (concat (substring filename 0 (match-beginning 0)) ".elc")))
    (store-match-data match-data)
    result))

;; Save original definition.
(and (fboundp 'byte-compile-dest-file)
     (not (fboundp 'bcf-byte-compile-dest-file-orig))
     (defalias 'bcf-byte-compile-dest-file-orig
       (symbol-function 'byte-compile-dest-file)))

(defalias 'byte-compile-dest-file 'bcf-byte-compile-dest-file)

(provide 'bytecomp-fns)

;;; bytecomp-fns.el ends here.
