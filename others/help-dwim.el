;;; help-dwim.el --- Show help information

;; Copyright 2007 Ye Wenbin
;;
;; Author: wenbinye@gmail.com
;; Version: $Id: help-dwim.el,v 0.0 2007/08/22 06:35:00 ywb Exp $
;; Keywords: 
;; X-URL: not distributed yet

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
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;; I write a number of commands to search documents of symbols and
;; display them. It is hard to bind a common key for those command.
;; One command is need. So I write it to provide one command that
;; almost does everything.
;;
;; Woman Note: The woman-topic-all-completions is create using
;;  woman-file-name which will prompt for the file name. So you
;;  may have to M-x woman before active woman.

;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'help-dwim)
;;   

;;; Code:

(eval-when-compile
  (require 'cl))

(defgroup help-dwim nil
  "Show help information from different source."
  :group 'help)

(defcustom help-dwim-type-alist
  '((elisp-function . [function-called-at-point obarray fboundp describe-function])
    (elisp-variable . [variable-at-point obarray boundp describe-variable]))
  "*List of types for `help-dwim'.
"
  :type '(alist :key-type symbol)
  :group 'help-dwim)

;; is there a buildin widget?
(define-widget 'option-list 'list
  "A widget like check list for customize option is list.
It has a :options which car part indicate the options type. 
"
  :convert-widget (lambda (widget)
                    (let ((options (widget-get widget :options)))
                      (cond ((eq (car options) 'variable)
                             (setq options (symbol-value (cadr options))))
                            ((eq (car options) 'function)
                             (setq options (funcall (cadr options))))
                            ((eq (car options) 'list)
                             (setq options (cdr options)))
                            (t (error "Not a valid options!")))
                      (if (listp options)
                          (if (listp (car options))
                              (setq options (mapcar 'car options)))
                        (error "Not a valid list options!"))
                      (widget-put widget :args
                                  `((checklist
                                     :inline t
                                     ,@(mapcar (lambda (entry)
                                                 `(const ,entry))
                                               options))))
                      widget))
  :tag "Options")

(defvar help-dwim-autoload nil
  "Autoload code for `help-dwim-load-extra'")

(defun help-dwim-load-extra ()
  (interactive)
  (dolist (extra help-dwim-autoload)
    (when (and (memq (car extra) help-dwim-active-types)
               (null (help-dwim-obarray (assoc (car extra) help-dwim-type-alist))))
      (eval (cdr extra)))))

(defcustom help-dwim-active-types '(elisp-function)
  "*Activated types.
The order of this list is important for the default behavior of
`help-dwim'."
  :type 'option-list
  :set (lambda (symbol value)
         (set symbol value)
         (if (boundp 'help-dwim-active-types)
             (help-dwim-load-extra))
         value)
  :options '(variable help-dwim-type-alist)
  :group 'help-dwim)

(defvar help-dwim-last-item nil
  "")

(defvar help-dwim-obarray nil
  "Global variable for predicate function.")

(defsubst help-dwim-type (type)
  (car type))
(defsubst help-dwim-chars (type)
  (aref (cdr type) 0))
(defsubst help-dwim-obarray (type)
  (and (boundp (aref (cdr type) 1))
       (symbol-value (aref (cdr type) 1))))
(defsubst help-dwim-predicate (type)
  (aref (cdr type) 2))
(defsubst help-dwim-handler (type)
  (aref (cdr type) 3))

(defun help-dwim-guess-types (name)
  (let (types sym predicate)
    (mapc
     (lambda (type)
       (setq help-dwim-obarray (help-dwim-obarray type))
       (when (and (setq sym (intern-soft name help-dwim-obarray))
                  (if (setq predicate (help-dwim-predicate type))
                      (funcall predicate sym) t))
         (push (help-dwim-type type) types)))
     (help-dwim-active-types))
    (nreverse types)))

(defun help-dwim-active-types ()
  (mapcar (lambda (type)
            (assoc type help-dwim-type-alist))
          help-dwim-active-types))

(defun help-dwim-things-ap ()
  (let (things thing chars sym predicate)
    (dolist (type (help-dwim-active-types) things)
      (save-excursion
        (setq chars (help-dwim-chars type))
        (if (symbolp chars)
            (if (setq thing (funcall chars))
                (and (symbolp thing)
                     (push (cons (help-dwim-type type) thing) things)))
          (skip-chars-forward chars)
          (setq thing (buffer-substring
                       (progn (skip-chars-backward chars) (point))
                       (progn (skip-chars-forward chars) (point))))
          (and (setq help-dwim-obarray (help-dwim-obarray type))
               (setq sym (intern-soft thing help-dwim-obarray))
               (if (setq predicate (help-dwim-predicate type))
                   (funcall predicate sym)
                 t)
               (push (cons (help-dwim-type type) sym) things)))))))

(defun help-dwim (name &optional type)
  (interactive 
   (let ((things (help-dwim-things-ap))
         ;; for speedup completion functions, Is it really help?
         (colletions (mapcar (lambda (type)
                               (cons (help-dwim-obarray type)
                                     (help-dwim-predicate type)))
                             (help-dwim-active-types)))
         types name)
     (setq name
           (completing-read
            (if things
                (format "Describe(default %S): " (cdar things))
              "Describe: ")
            (lambda (str pred flag)
              (let ((types colletions) complete)
                (cond ((eq flag 'lambda) ; for test-completion
                       (while (and (not complete) types)
                         (setq complete (test-completion str (caar types)
                                                         (cdar types))
                               types (cdr types)))
                       complete)
                      ((null flag)      ; for try-completion
                       (while (and (not complete) types)
                         (setq complete (try-completion str (caar types)
                                                        (cdar types)))
                         (unless (or (eq complete 't)
                                     (= (length complete) (length str)))
                           (setq complete nil))
                         (setq types (cdr types)))
                       complete)
                      (t                ; for all-completions
                       (apply 'append
                              (mapcar 
                               (lambda (type)
                                 (all-completions str (car type) (cdr type)))
                               colletions))))))
            nil t nil nil
            (if things (symbol-name (cdar things)))))
     (setq types (help-dwim-guess-types name))
     (if (= (length types) 1)
         (list name (car types))
       (list name (intern (completing-read
                           (format "Type of description(default %S): "
                                   (car types))
                           (mapcar 'list types)
                           nil t nil nil (symbol-name (car types))))))))
  (let ((types (help-dwim-guess-types name)))
    (setq type (assoc type help-dwim-type-alist))
    (setq help-dwim-last-item (list name (car type) types))
    (funcall (help-dwim-handler type)
             (intern-soft name (help-dwim-obarray type)))))

(defun help-dwim-active-type (type &optional append)
  "Active type for current buffer.
If APPEND is non-nil, that mean the TYPE is an additional help command.
Use `help-dwim-customize-type' for active or deactive type globally."
  (interactive
   (list (intern (completing-read "Activate type: "
                                  help-dwim-type-alist
                                  (lambda (type)
                                    (not (memq (help-dwim-type type) help-dwim-active-types)))
                                  t))
         current-prefix-arg))
  (help-dwim-deactive-type type)
  (add-to-list 'help-dwim-active-types type append)
  (help-dwim-load-extra))

(defun help-dwim-deactive-type (type)
  "Deactive type for current buffer.
If APPEND is non-nil, that mean the TYPE is an additional help command.
Use `help-dwim-customize-type' for active or deactive type globally."
  (interactive
   (list (intern (completing-read "Deactive type: "
                                  (mapcar 'list help-dwim-active-types)
                                  nil t))))
  (make-local-variable 'help-dwim-active-types)
  (setq help-dwim-active-types (remove type help-dwim-active-types)))

(defun help-dwim-customize-type ()
  (interactive)
  (customize-variable 'help-dwim-active-types))

(defun help-dwim-register (type activate &optional body)
  "Register a new type of help.
TYPE is an element of `help-dwim-type-alist'.
If ACTIVATE is non-nil, the type will add to
`help-dwim-active-type', and BODY will eval intermediately.
BODY is the code to eval when the type is activated. If the type is
register without activated, the BODY will add to `help-dwim-autoload'.
When you use `help-dwim-active-type' or `help-dwim-customize-type' add
the type, the code will eval then."
  (add-to-list 'help-dwim-type-alist type t)
  (if activate
      (progn
        (add-to-list 'help-dwim-active-types (car type) t)
        (and body
             (eval (cons 'progn body))))
    (if body
        (add-to-list 'help-dwim-autoload
                     (cons (car type) (cons 'progn body))))))

(help-dwim-register
 '(woman . ["-+.:[_a-zA-Z0-9" help-dwim-woman-obarray nil help-dwim-woman] )
 nil
 '((require 'woman)
   (defvar help-dwim-woman-obarray nil
     "Items in `woman-topic-all-completions'")
   (defun help-dwim-build-woman-obarray ()
     (interactive)
     (if woman-topic-all-completions
         (progn
           (setq help-dwim-woman-obarray (make-vector 1519 0))
           (mapc (lambda (elt)
                   (intern (car elt) help-dwim-woman-obarray))
                 woman-topic-all-completions))
       (message "Woman topices not load! M-x help-dwim-build-woman-obarray again after load them.")))
   (help-dwim-build-woman-obarray)
   (defun help-dwim-woman (symbol)
     (woman (symbol-name symbol)))))

(help-dwim-load-extra)
(provide 'help-dwim)
;;; help-dwim.el ends here
