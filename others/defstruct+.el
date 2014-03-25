;;; defstruct+.el --- extensions to Common Lisp structs

;; Copyright (C) 2007  Tom Schutzer-Weissmann
;;
;; Author: Tom Schutzer-Weissmann <trmsw at yahoo.co.uk>
;; Maintainer: Tom Schutzer-Weissmann
;; Version: 0.1
;; Keywords: extensions, lisp
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;;; Commentary: 

;; This library provides functions and macros for use with vector-based
;; structs created with the `cl' package.

;;; Code:
(require 'cl)
(require 'advice)


(defmacro defstruct+ (name-etc &rest etc)
  "Define a STRUCT using `defstruct' and also ensure that a
function called @<slot name> exists for every slot.
Additionally, create a custom version of `with-struct' specifically for the new
struct, called with-<struct-name>.
\"with-struct\".

NAME-ETC and ETC are passed directly to `defstruct'"
  (let* ((struct-name (if (listp name-etc) (car name-etc) name-etc))
	 (with-sym (barred-sym "with" struct-name))
	 (doc ""))
    (when (stringp (car etc))
      (setq doc (car etc)
	    etc (cdr etc)))
    `(prog1
	 ;; define the struct
	 (defstruct ,name-etc ,doc ,@etc)
       ;; define the @ functions for slot access
       ,@(mapcar
	  #'(lambda (slot-desc)
	      `(def-arroba ,(atom-or-car slot-desc)))
	  etc)
       ;; define the with- macro
       (defmacro ,with-sym
	 (spec-list struct &rest body)
	 ;; documentation
	 ,(format
	   "A version of `with-struct' specially for %s, which means using
 :all in SPEC-LIST doesn't require runtime expansion.
STRUCT's slots are: %s"
		 struct-name
		 (struct-type-slots struct-name))
	 ;; body
	 (let ((struct-s (gensym)))
	   `(let ((,struct-s ,struct))
	      ,(with-struct-expand spec-list struct-s ',struct-name body))))
       (put ',with-sym 'lisp-indent-function 2)
       (defstruct+-add-macro-highlighting ,(symbol-name with-sym)))))


(defmacro defun-for-struct (struct-type fn-name fn-arglist spec-list &rest fn-body)
  "Define a function called <FN-NAME>-<STRUCT-TYPE> that receives a struct instance
as its first argument, called self, and any remaining arguments specified in FN-ARGLIST.

Additionally, ensure that a function ~<FN-NAME> exists, that can be called in place of
the new function.

The new function binds the slots of its first argument to local variables. The binding
is specified by SPEC-LIST, and is the same as for `with-struct'.

If STRUCT-TYPE includes another struct type, its own FN-NAME function
can be called inside FN-BODY using call-included-fn, a marker that is
then expanded to something similar to an object's \"super\" method."
  (let ((real-fn-name (barred-sym fn-name struct-type))
	(fn-doc       ""))
    (when  (and (stringp (car fn-body)) (cdr fn-body))
      (setq fn-doc  (car fn-body)
	    fn-body (cdr fn-body)))
    ;; Expansion
    `(progn
       (def-tilde ,fn-name)
       (defun ,real-fn-name ,(cons 'self fn-arglist)
	 ,fn-doc
	 ,(with-struct-expand spec-list 'self struct-type
			      ;; deal with any call-included-fn
			      (expand-call-included fn-body fn-name struct-type fn-arglist))))))


(defun expand-call-included (forms name type fn-arglist)
  (ad-substitute-tree
   (function (lambda (form) (eq form 'call-included-fn)))
   (function (lambda (form)
	       `(let ((included (get ',type 'cl-struct-include)))
		  (let ((fn (when included (struct-type-fn included ',name))))
		    (when fn (apply fn (list ,@(cons 'self fn-arglist))))))))
   forms))



(defmacro do-struct (vars struct end-form &rest body)
  "Similar to `dolist', but for iterating over a struct's slots and
  their values.

Given a cl vector-based struct, STRUCT, evaluate BODY and return
END-FORM. Within BODY, the variables specified in VARS are set.

VARS is evaluated as \(slot-value &optional slot-name struct\), and
SLOT-VALUE is bound to the slot's value using `symbol-macrolet', so
changing it will change the struct.

For example:
    \(do-struct \(v name\)  my-struct nil
        \(setq \(v \(* 2 v\)\)\)\)

will double the value of all the slots in my-struct, and return nil."
  (destructuring-bind (value-s &optional slot-s struct-s) vars
    ;; prepare the symbols
    (let* ((slot-s   (or slot-s   (gensym)))
	   (struct-s (or struct-s (gensym)))
	   (slots-s  (gensym))
	   (index-s  (gensym)))
      `(let ((,struct-s ,struct))
	 (do ((,index-s 1  (1+ ,index-s))
	      (,slots-s (struct-slots ,struct-s) (cdr ,slots-s)))
	     ((null ,slots-s) ,end-form)
	   (let ((,slot-s (car ,slots-s)))
	     (symbol-macrolet ((,value-s (aref ,struct-s ,index-s)))
	       ,@body)))))))
(put 'do-struct 'lisp-indent-function 3)



(defmacro with-struct (spec-list struct &rest body)
  "Given a cl vector-based struct, STRUCT, evaluate BODY with the
symbols specified in SPEC-LIST bound to the STRUCT's slots.

Changing the value of one of the bound variables changes the value of
the corresponding slot. Additionally, STRUCT is bound to \"self\"
within BODY, with `let'. 

Each member of SPEC-LIST is either a symbol corresponding to a slot,
or a list \(alias slot\). In the first case the slot is bound to a
variable of the same name, in the second the slot is bound to an
alias. 

Two keywords are also possible, alone or in conjunction, at the
 beginning of SPEC-LIST. 
 :all means bind all slots. Aliases can still be specified, as
above. 
 :pfx followed by a symbol means prefix all the bindings with that
symbol.

To simply bind all slots, you can use :all instead of \(:all\)."
(let ((struct-s (gensym)))
  ;; Expansion
  `(let ((,struct-s ,struct))
     ,(if (or (eq :all spec-list)
	      (member :all spec-list))
	  ;; need another macro
	  `(with-struct1 ,spec-list ,struct-s ,@body)
	;; get the simple expansion
	(with-struct-expand spec-list struct-s nil body)))))



(defmacro with-struct1 (spec-list struct  &rest body)
  (let ((struct-type   (eval `(struct-type ,struct))))
    (with-struct-expand spec-list struct struct-type body)))



(defun with-struct-expand (spec-list struct struct-type body)
  ;; deal with :all shorthand
  (when (eq :all spec-list) (setq spec-list '(:all)))
  ;; deal with (:all )
  (let ((all (member :all spec-list)))
    (when all (setq spec-list (remove :all spec-list)))
    ;; deal with :pfx
    (let ((prefix (member :pfx spec-list)))
      (when prefix (setq spec-list (cddr prefix)
			 prefix    (cadr prefix)))
      ;; local fn to create the bindings
      (flet ((macrolet-binding (spec)
	      (let ((alias (atom-or-car spec))
		    (slot  (atom-or-cadr spec)))
		`(,(join-syms nil prefix alias)         ; alias with prefix
		  (,(arroba-sym slot) self) ; (<type>-<slot> self)
		  ))))
	;; :all can be used in conjunction with aliases
	(let ((spec-bindings (mapcar #'macrolet-binding spec-list))
	      (all-bindings
	       (when all
		 (mapcar #'macrolet-binding
			 (struct-type-slots struct-type)))))
	  ;; Expansion
	  `(let ((self ,struct))
	     (symbol-macrolet
		 (,@(append spec-bindings
			   ;; avoid duplicate bindings
			   (set-difference all-bindings spec-bindings
					   :key #'atom-or-car)))
	       
	       ,@body)))))))



(defun @-position (slot struct &optional no-error)
  "For a vector-based structure STRUCT, return SLOT's position
in the structure, or raise an error if it doesn't exist.

A '@-positions property is added to the structure containing a hash
of slot name - slot position."
  (let* ((type (struct-type struct))
	 (positions (slot-positions type))
	 (position (gethash (keyword-symbol slot) positions)))
    (or position
	(unless no-error
	  (error "No slot %s was found in %s" slot struct)))))



(defun slot-positions (struct-type)
  "For a struct type STRUCT-TYPE, return a hash of slot name -> position,
and if the hash hasn't already been calculated, store is as the struct type's
'struct-positions property."
  (let ((positions (get struct-type 'struct-positions)))
    (if positions positions
      (let ((slots (get struct-type 'cl-struct-slots)))
	(setq positions (make-hash-table :size (1- (length slots))))
	(do ((pos 1 (1+ pos)) ; starting at 2nd position
	     (slots (cdr slots) (cdr slots)))
	    ((null slots) (put struct-type 'struct-positions positions)) ; returns positions
	  (puthash (caar slots) pos positions))))))



(defmacro def-arroba (name)
  "Create a function called '@NAME' which returns the
NAME slot of its argument, a struct, and a `defsetf'
that allows it to be set."
  (let ((fn-name (arroba-sym name)))
    (unless (fboundp fn-name)
      `(progn
	 (defsetf ,fn-name (self) (value)
	   (list 'aset self (list '@-position ,(symbol-keyword name) self) value))
	 (defun ,fn-name (self)
	   ,(format "Return the %s slot in the struct SELF." name)
	   (aref self (@-position ',name self)))))))


		
(defmacro def-tilde (name)
  "Create a function called '~NAME' which can be used to
call different functions depending on the type of its first
argument, a struct.
Eg
 \(~warble a-bird\) calls \(warble-bird a-bird\)
whereas
\(~warble b-wooster\) calls \(warble-Wooster b-wooster\),
naturally with very different results.

It is not necessary to use this macro if functions are defined with
`defun-for-struct'"
  (let ((~name (tilde-sym name)))
    (unless (fboundp ~name)
      `(defun ,~name (self &rest args)
	 ,(format "Applies a suitable %s function to a struct, SELF, and
ARGS. The actual function depends on SELF's type, and if found with
`struct-type-fn'" name)
	 (let* ((type (struct-type self))
		(fn   (struct-type-fn type ',name)))
	   (if fn (apply fn self args)
	     (error ,(format "No %s function found for %%s" name) type)))))))



(defun struct-type-fn (struct-type fn)
  "Return the function FN for STRUCT-TYPE, if it is fbound.
The function looked for is called <fn>-<struct-type>,
but included struct types are checked too, if necessary.
Nil is returned if no suitable function is found."
  (let ((fn-name (barred-sym fn struct-type)))
    (if (fboundp fn-name) fn-name
      (let ((included (get type 'cl-struct-include)))
	(when included (struct-fn included fn))))))



(defun struct-type (struct)
  "Return the type of struct STRUCT is, or raise an error if STRUCT isn't
a vector-based STRUCT."
  (condition-case nil
      (let* ((marker (symbol-name (aref struct 0)))
	     (type   (replace-regexp-in-string "^cl-struct-" "" marker)))
	(assert (not (equal marker type)))
	(intern type))
    (error (error "%s doesn't seem to be a vector-based struct" struct))))



(defun struct-slots (struct)
  "Return a list of the slots of STRUCT."
  (struct-type-slots (struct-type struct)))



(defun struct-type-slots (struct-type)
  "Return a list of the slots of STRUCT-TYPE,
a symbol, being the name of a struct type."
  (mapcar 'car (cdr (get struct-type 'cl-struct-slots))))



(defun keyword-symbol (k)
  "For a keyword K return the corresponding symbol.
Eg, :name -> 'name"
  (if (keywordp k) (intern (substring (symbol-name k) 1)) k))



(defun symbol-keyword (s)
  "For a symbol S return the corresponding keyword.
Eg, 'name -> :name"
  (if (keywordp s) s
    (intern (concat ":" (symbol-name s)))))



(defun join-syms (sep &rest syms)
  "Join the names of the symbols SYMS with the separator string SEP
and return the result as a symbol."
  (intern
   (mapconcat '(lambda (sym) (format "%s" (or sym ""))) ; allow for strings
	      syms
	      sep)))



(defun barred-sym (&rest syms)
  "Join the names of the symbols SYMS with a hyphen and return the
result as a symbol."
  (apply 'join-syms "-" syms))



(defun tilde-sym (sym) 
  "Return SYM prefixed with a tilde"
  (join-syms "" "~" sym))



(defun arroba-sym (sym) 
  "Return SYM prefixed with an arroba (at sign)"
  (join-syms "" "@" sym))



(defun atom-or-car (x)
  (if (atom x) x (car x)))


(defun atom-or-cadr (x)
  (if (atom x) x (cadr x)))




(defun put-slopt (struct slot option value)
  "Store STRUCT's SLOT's slot option OPTION's value as VALUE.
It can be retrieved with `(get-slopt STRUCT SLOT OPTION)'.

Common Lisp supports two slot options, :type and :read-only, when
defining structs. 

STRUCT can either be a struct type or an instance. 
SLOT and OPTION can both be given as either a symbol or a keyword:
options are treated as keywords, and slots as symbols."
  (let* ((slot        (keyword-symbol slot))
	(option      (symbol-keyword option))
	(struct-type (if (symbolp struct) struct
		       (struct-type struct)))
	(slots (get struct-type 'cl-struct-slots))
	(pos (position slot slots :key #'car)))
    (if pos ; the slot exists
	(let ((options (nth pos slots)))
	  (let ((modified (plist-put (cddr options) option value)))
	    (push (cadr options) modified) ; default slot value
	    ;; gnarly in-place modification
	    (setf (cdr (nth pos (get struct-type
				     'cl-struct-slots)))
		  modified)))
      (error "No %s slot found in %s" slot struct-type))))



(defun get-slopt (struct slot option)
  "Return the value of STRUCT's SLOT's slot option OPTION.

Common Lisp supports two slot options, :type and :read-only, when
defining structs. More can be added and modified with `put-slopt'

STRUCT can either be a struct type or an instance. 
SLOT and OPTION can both be given as either a symbol or a keyword:
options are treated as keywords, and slots as symbols."
  (let* ((struct-type (if (symbolp struct) struct
			(struct-type struct)))
	 (options (assoc (keyword-symbol slot) 
			 (cdr (get struct-type 'cl-struct-slots)))))
    (if options
	(plist-get (cddr options)
		   (symbol-keyword option))
      (error "No %s slot found in %s" slot struct-type))))



;; set up syntax-highlighting
(defun defstruct+-add-macro-highlighting (&rest names)
  (mapc '(lambda (mode)
	   (font-lock-add-keywords
	    mode
	    `((,(concat "(\\(" (regexp-opt names) "\\)\\>") (1 font-lock-keyword-face)))))
	(list 'emacs-lisp-mode 'lisp-interaction-mode)))



(defstruct+-add-macro-highlighting
 "defstruct+" "with-struct" "do-struct" "defun-for")
     

(provide 'defstruct+)
;;; defstruct+.el ends here
