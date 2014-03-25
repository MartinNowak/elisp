;;; combinations.el --- generating combinations of set elements
;; Author: Per Nordlöw

(eval-when-compile (require 'cl))

(defun all-combinations (seq)
  "Generate a listing of all the possible combinations of the
elements in the sequence N. Time-Complexity is N! Uses elt() for
sequence and nth() for lists. Contains optimized cases for when
lenght of SEQ is 0, 1, 2, 3, 4."
  (if (null seq) nil
    (case (length seq)
      (0 nil)
      (1 `(,seq))
      (2 (let ((a (elt seq 0))
               (b (elt seq 1)))
           `((,a ,b) (,b ,a)
             )
           ))
      (3 (let ((a (elt seq 0))
               (b (elt seq 1))
               (c (elt seq 2)))
           `((,a ,b ,c) (,a ,c ,b)
             (,b ,a ,c) (,b ,c ,a)
             (,c ,a ,b) (,c ,b ,a)
             )
           ))
      (4 (let ((a (elt seq 0))
               (b (elt seq 1))
               (c (elt seq 2))
               (d (elt seq 3)))
           `((,a ,b ,c ,d) (,a ,c ,b ,d) (,b ,a ,c ,d) (,b ,c ,a ,d) (,c ,a ,b ,d) (,c ,b ,a ,d)
             (,a ,b ,d ,c) (,a ,c ,d ,b) (,b ,a ,d ,c) (,b ,c ,d ,a) (,c ,a ,d ,b) (,c ,b ,d ,a)
             (,a ,d ,b ,c) (,a ,d ,c ,b) (,b ,d ,a ,c) (,b ,d ,c ,a) (,c ,d ,a ,b) (,c ,d ,b ,a)
             (,d ,a ,b ,c) (,d ,a ,c ,b) (,d ,b ,a ,c) (,d ,b ,c ,a) (,d ,c ,a ,b) (,d ,c ,b ,a)
             )
           ))
      (t                                ;general case
       (mapcan (lambda (e)
                   (mapcar (lambda (p) (cons e p))
                           (all-combinations ;Note: recurse
                            (remove* e seq :count 1)))) ;Note: For Common Lisp use remove() instead.
               seq))
      )))
;; Use: (all-combinations nil)
;; Use: (all-combinations '(nil))
;; Use: (all-combinations '(1))
;; Use: (all-combinations '(1 2))
;; Use: (all-combinations `(1 2 ,(+ 1 2)))
;; Use: (all-combinations `(1 2 3 4))
;; Use: (all-combinations `(1 2 3 4 5))
;; Use: (length (all-combinations `(1 2 3 4 5))) => 120
;; Use: (length (all-combinations `(1 2 3 4 5 6))) => 120
(defalias 'all-permutations 'all-combinations)

(defun all-combinations-general (seq)
  "Return a list of all the permutations of the input. Warning:
This is a compacter but much slower implementation compared to
all-combinations()."
  (if (null seq) '(())
    ;; Otherwise, take an element, e, out of the bag.
    ;; Generate all permutations of the remaining elements,
    ;; And add e to the front of each of these.
    ;; Do this for all possible e to generate all permutations.
    (mapcan (lambda (e)
                (mapcar (lambda (p) (cons e p))
                        (all-combinations-general
                         (remove* e seq :count 1)))) ;Note: For Common Lisp use remove() instead.
            seq)))

;; Note: This proves that my all-combinations() is about 10 times
;; faster than all-combinations-general().

;; Use: (benchmark-run 100 (all-combinations `(1 2 3 4 5)))
;; Use: (benchmark-run 100 (all-combinations-general `(1 2 3 4 5)))

(defun string-list-to-regexp (keys &optional regexp-flag way regexp-style)
  "Combine the list of strings KEYS in WAY into a regular expression.
If REGEXP-FLAG is non-nil treat each element in KEYS as a regexp
string otherwise as a literal string (returned `regexp-quote'd).
WAY can be either `all', `any' or `opt'."
  (cond ((null keys)                    ;empty list
         "")                            ;empty string
        ((= (length keys) 1)            ;one-element list
         (if regexp-flag
             keys
           (list (regexp-quote (car keys)))))
        (t                              ;general case
         (cond ((eq way 'all)
                (mapconcat (lambda (x) 
                             (mapconcat (lambda (y)
                                          (concat (if (eq regexp-style 'posix) "\(" "\\(?:")
                                                  (if regexp-flag y (regexp-quote y))
                                                  (if (eq regexp-style 'posix) "\)" "\\)")
                                                  ))
                                        x ".*"))
                           (all-combinations keys) (if (eq regexp-style 'posix) "\|" "\\|")))
               (t
                (mapconcat (lambda (x)
                             (concat
                              (if (eq regexp-style 'posix) "\(" "\\(")
                              (if regexp-flag x (regexp-quote x))
                              (if (eq regexp-style 'posix) "\)" "\\)")))
                           keys (if (eq regexp-style 'posix) "\|" "\\|")))))))
;; Use: (string-list-to-regexp nil)
;; Use: (string-list-to-regexp '(".txt") t)
;; Use: (string-list-to-regexp '(".txt"))
;; Use: (string-list-to-regexp '("a"))
;; Use: (string-list-to-regexp '("a" "b"))
;; Use: (string-list-to-regexp '("a" "b") nil 'all)

(provide 'combinations)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; combinations.el ends here
