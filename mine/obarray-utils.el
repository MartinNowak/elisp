;;; obarray-utils.el ---
;; Author: Per Nordlöw

;; TODO: Merge with obarray-fns.el?

(defun make-obarray (num)
  "Construct an obarray suitable for storing NUM number of
objects."
  (make-vector (+ num 1) 0)) ;TODO: Reuse this-or-next-power-of-two-plus-one() is good guess for a prime.
;; Use: (make-obarray 10)
;; Test: (benchmark-run 10 (make-obarray 1000000))
;; Test: (benchmark-run 10 (make-vector 1000000 0))
;; Test: (benchmark-run 10 (make-list 1000000 nil))
;; Test: (benchmark-run 10 (make-string 1000000 ?a))
;; Test: (benchmark-run 10 (make-bool-vector 1000000 0))

(defun make-obarray-ideal (&optional num)
  "Construct an obarray with a length ideally suitable for
storing NUM number of objects.  Beware that time complexity of
this function is O(num^2)."
  (make-vector
   (if num (if (require 'primes nil t)
               (this-or-next-prime num)
             num)
     4099)
   0))
;; Use: (make-obarray-ideal 10)
;; Test: (benchmark-run 100 (make-obarray-ideal 100000))

(defun obarray-length (&optional ob)
  "Determine number of elements present in SAMPLE-OBARRAY.
Optional arg OB is an obarray, which defaults to the global variable
`obarray'."
  (let ((num 0))
    (mapatoms (lambda (sym)
                (setq num (1+ num)))
              ob)
    num))
;; Use: (obarray-length)
;; Use: (benchmark-run 1 (obarray-length))

;; TODO: Generalize `propname' to `plist` and remove STRING.
(defun obarray-equal (string &optional propname kind-char scope ob)
  "Seek a match for STRING in `ob''.
Return a list of matches as strings (keys)."
  (let ((hits))
    (mapatoms `(lambda (sym)
                 (let* ((sym-name (symbol-name sym))
                        (val (when (and (or (not ,kind-char)
                                            (eq ,kind-char (get sym :kind)))
                                        (or (not ,scope)
                                            (string-equal ,scope (get sym :structure))
                                            (string-equal ,scope (get sym :namespace))))
                               (if ,propname (get sym ,propname)
                                 sym-name))))
                   (when (and val (string= ,string val))
                     ;;(intern sym-name *echits*) ;"copy" symbol name (tag-key)
                     (setq hits (cons sym-name hits)))))
              ob)
    (nreverse hits)))
;; use: (obarray-equal "find-file")
;; use: (all-completions "find-file" obarray)

(defun obarray-match-regexp (regexp &optional propname kind-char scope ob)
  "Seek a match for REGEXP in `ob''.
Return a list of matches as strings (keys)."
  (let ((hits))
    (mapatoms `(lambda (sym)
                 (let* ((sym-name (symbol-name sym))
                        (val (when (and (or (not ,kind-char)
                                            (eq ,kind-char (get sym :kind)))
                                        (or (not ,scope)
                                            (string-equal ,scope (get sym :structure))
                                            (string-equal ,scope (get sym :namespace))))
                               (if ,propname (get sym ,propname)
                                 sym-name))))
                   (when (and val (string-match ,regexp val))
                     ;;(intern sym-name *echits*) ;"copy" symbol name (tag-key)
                     (setq hits (cons sym-name hits)))))
              ob)
    (nreverse hits)))
;; use: (obarray-match-regexp "find-file")
;; use: (obarray-match-regexp "pobj")
;; use: (obarray-match-regexp "\\`pOb\\'" :name ?f nil *ectags*)
;; use: (obarray-match-regexp "pOb\\'" :name ?f nil *ectags*)
;; use: (obarray-match-regexp "pOb\\'" :name ?c nil *ectags*)

;; TODO: Generalize `propname' to `plist` and remove STRING.
(defun obarray-match-string (string &optional propname match-type kind-char scope ob)
  ""
  (case match-type
    (exact                ;TODO: Reuse `all-completions' to improve performance.
     (obarray-equal string propname kind-char scope ob))
    (prefix               ;TODO: Reuse `all-completions' to improve performance.
     (obarray-match-regexp (concat "\\`" (regexp-quote string)) propname kind-char scope ob))
    (partial
     (obarray-match-regexp (regexp-quote string) propname kind-char scope ob))
    (t                                  ;exact or partial
     (or (obarray-equal string propname kind-char scope ob)
         (obarray-match-regexp (concat (regexp-quote string)) propname kind-char scope ob)))
    ))
;; use: (obarray-match-string "find")
;; use: (obarray-match-string "find-file" nil 'exact)
;; use: (obarray-match-string "find-file" nil 'partial)
;; use: (obarray-match-string "pOb" :name 'partial)
;; use: (obarray-match-string "pOb" :name 'partial ?c nil *ectags*)
;; use: (obarray-match-string "pOb" :name 'partial ?f nil *ectags*)

(defun obarray-multi-match-string (string &optional propname match-type kind-chars scope ob)
  ""
  (catch 'hit
    (dolist (kind-char kind-chars)
      (let ((val (obarray-match-string string propname match-type kind-char scope ob)))
        (when val
          (throw 'hit val))))))
;; use: (obarray-multi-match-string "Unit" :name 'partial '(?C) nil *ectags*)
;; use: (obarray-multi-match-string "Unit" :name 'partial '(?C) "ud" *ectags*)
;; use: (obarray-multi-match-string "Unit" :name 'partial '(?C) "ud" *ectags*)
;; use: (obarray-multi-match-string "m_unit" :name 'partial '(118 100 101 102) nil *ectags*)

(defun copy-symbol (sym-name from to)
  "Copy symbol named SYM-NAME from obarray FROM to obarray TO."
  (let ((old-sym (intern-soft sym-name from))
        (new-sym (intern sym-name to)) )
    (set new-sym (symbol-value old-sym)) ;value
    (fset new-sym (symbol-function old-sym)) ;function
    (setplist new-sym (symbol-plist old-sym)))) ;property list (plist)

(defun move-symbol (sym-name from to)
  "Move symbol named SYM-NAME from obarray FROM to obarray TO."
  (copy-symbol sym-name from to)
  (unintern sym-name from))

(defun obarray-lazy-completion-table (&optional ob)
  "Return the names of symbols contained in OB colorized by type.
OB defaults to `obarray' if nil."
  (let ((names))
    (mapatoms (lambda (sym)
                (let ((name (propertize (symbol-name sym)
                                        'face (symbol-def-face sym))))
                  (setq names (cons name names))
                  ;;(if names (setq names (nconc names name)) (setq names (list name)))
                  ))
              ob)
    names))
;; Use: (obarray-lazy-completion-table)
;; Use: (benchmark-run 1 (obarray-lazy-completion-table))

(provide 'obarray-utils)
