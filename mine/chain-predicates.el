;;; chain-predicates.el --- List/Sequence of Number/String/Symbol Predicates.
;; Author: Per Nordlöw

(eval-when-compile (require 'cl))

;; Sequence of stuff
(defmacro sequence-of-p (predicate)
  "Generate a function that checks that its argument OBJECT is
a sequence and that each element of this sequence fullfils
PREDICATE."
  `(lambda (object) (and (sequencep object)
                         (every (function ,predicate) object))))
;; Use: (funcall (sequence-of-p integerp) '(1 2))

(defun sequence-of-numbers-p (object) (funcall (sequence-of-p numberp) object))
(defalias 'sequence-of-numbers? 'sequence-of-numbers-p)

;; Use: (sequence-of-numbers-p '(1 2)) => t
;; Use: (sequence-of-numbers-p '[1 2]) => t
;; Use: (sequence-of-numbers-p '(1 "2")) => nil
;; Use: (sequence-of-numbers-p '[1 "2"]) => nil
(defun sequence-of-strings-p (object) (funcall (sequence-of-p stringp) object))
(defalias 'sequence-of-strings? 'sequence-of-strings-p)
;; Use: (sequence-of-strings-p '(1 2)) => nil
;; Use: (sequence-of-strings-p '[1 2]) => nil
;; Use: (sequence-of-strings-p '("1" "2")) => t
;; Use: (sequence-of-strings-p '["1" "2"]) => t

;; Note: Simple but only for lists.
(defun list-of-numbers-p-recursive (object)
  "Return t if OBJECT is a list of numbers."
  (or (null object)
      (and (consp object)
           (numberp (first object))
           (list-of-numbers-p-recursive (rest object)))))
;; Use: (bench (list-of-numbers-p-recursive '(1 2 3 4 5 6 7 8 9)))

(defun list-of-numbers-fast-p (object)
  "Return t if OBJECT is a list of numbers."
  (and (listp object) (every (function numberp) object)))
(defalias 'list-of-numbers-fast? 'list-of-numbers-fast-p)
;; Use: (bench (list-of-numbers-fast-p '(1 2 3 4 5 6 7 8 9)))
;; Use: (bench (list-of-numbers-fast-p '(1 "2" 3 4 5 6 7 8 9)))

;; List of stuff
(progn
  (defmacro list-of-p (predicate)
    "Generate a function that checks that each element of its
argument OBJECT fullfils PREDICATE."
    `(lambda (object) (and (listp object)
                           (every (function ,predicate) object))))
  (defalias 'list-of? 'list-of-p)
  ;; Use: (funcall (list-of-p integerp) '(1 2 3 4))

  (defun list-of-numbers-p (object)
    "Return non-nil if OBJECT is a List of Numbers."
    (funcall (list-of-p numberp) object))
  (defalias 'list-of-numbers? 'list-of-numbers-p)
  ;; Use: (list-of-numbers-p '(1 2)) => t
  ;; Use: (list-of-numbers-p '(1 "2")) => nil
  ;; Use: (list-of-numbers-p '[1 "2"]) => nil

  (defun list-of-strings-p (object)
    "Return non-nil if OBJECT is a List of Strings."
    (funcall (list-of-p stringp) object))
  (defalias 'list-of-strings? 'list-of-strings-p)
  ;; Use: (list-of-strings-p '(1 2)) => nil
  ;; Use: (list-of-strings-p '(1 "2")) => nil
  ;; Use: (list-of-strings-p '("1" "2")) => t

  (defun list-of-symbols-p (object)
    "Return non-nil if OBJECT is a List of Symbols."
    (funcall (list-of-p symbolp) object))
  (defalias 'list-of-symbols? 'list-of-symbols-p)
  ;; Use: (list-of-symbols-p '(a b)) => nil
  ;; Use: (list-of-symbols-p '(a "b")) => nil
  ;; Use: (list-of-symbols-p '("a" "b")) => nil
  ;; Use: (list-of-symbols-p '('a 'b)) => nil
  ;; Use: (list-of-symbols-p '(a b)) => t

  (defun cons-of-numbers-p (x)
    "Return non-nil if X is a cons cell of two numbers."
    (and (consp x)
         (numberp (car x))
         (numberp (cdr x))))
  (defalias 'region-p 'cons-of-numbers-p)
  ;; Use: (cons-of-numbers-p '(1 . 2))
  ;; Use: (cons-of-numbers-p '(1))

  (defun number-array-pair-p (x)
    "Return non-nil if X is an array of two numbers."
    (and (arrayp x)
         (= 2 (length x))
         (numberp (aref x 0))
         (numberp (aref x 1))))
  ;; Use: (array-of-number-pair-p '[1 2])
  ;; Use: (array-of-number-pair-p '[1])
)

;; Array of stuff
(progn
  (defmacro array-of-p (predicate)
    "Generate a function that checks that its argument OBJECT is
a array and that each element of this array fullfils
PREDICATE."
    `(lambda (object) (and (arrayp object)
                           (every (function ,predicate) object))))
  (defalias 'array-of? 'array-of-p)
  ;; Use: (funcall (array-of-p integerp) '[1 2])

  (defun array-of-numbers-p (object) (funcall (array-of-p numberp) object))
  (defalias 'array-of-numbers? 'array-of-numbers-p)
  ;; Use: (array-of-numbers-p '(1 2)) => nil
  ;; Use: (array-of-numbers-p '[1 2]) => t
  ;; Use: (array-of-numbers-p '(1 "2")) => nil
  ;; Use: (array-of-numbers-p '[1 "2"]) => nil
  (defun array-of-strings-p (object) (funcall (array-of-p stringp) object))
  (defalias 'array-of-strings? 'array-of-strings-p)
  ;; Use: (array-of-strings-p '(1 2)) => nil
  ;; Use: (array-of-strings-p '[1 2]) => nil
  ;; Use: (array-of-strings-p '("1" "2")) => nil
  ;; Use: (array-of-strings-p '["1" "2"]) => t
  )

(when nil ;Warning: Don't know how this works so I disable it for now.
  ;; You may write a macro to build these functions automatically:
  (defun proper-list-p (object)
    (cl-labels ((step (slow fast)
                      (cond ((eq slow fast)           nil) ; circular list
                            ((null (cdr fast))       t)
                            ((atom (cdr fast))       nil) ; dotted list
                            ((null (cdr (cdr fast))) t)
                            ((atom (cdr (cdr fast))) nil) ; dotted list
                            (t (step (cdr slow) (cdr (cdr fast)))))))
      (cond
       ((null object)       t)   ; empty list
       ((atom object)       nil) ; not a list
       ((null (cdr object)) t)   ; one-element list
       (t (step object (cdr object))))))
  (defalias 'proper-listp 'proper-list-p)
  )

(provide 'chain-predicates)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; chain-predicates.el ends here
