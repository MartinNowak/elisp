;;; hash-table-utils.el --- Hash table Utitlies.
;; Author: Per Nordlöw

(defalias 'hash-table-clear 'clrhash)
(defalias 'hash-table-empty 'clrhash)

(defalias 'hash-table-map 'maphash)

(defun pp-hash-table (hash-table &optional buffer)
  "Pretty Print HASH-TABLE to BUFFER.
BUFFER defaults to `help-buffer'."
  (unless buffer (setq buffer (help-buffer)))
  (with-output-to-temp-buffer buffer
    (maphash (lambda (key value)
	       (pp key)
	       (princ " => ")
	       (pp value)
	       (terpri))
	     hash-table))
  (set-buffer buffer)
  (emacs-lisp-mode)
  (when (and (fboundp 'coolock-mode)
             coolock-mode)
    (coolock-mode -1)) ;note: disable for now; performance may be an issue here
  (setq buffer-read-only t))

;;; See: http://www.emacswiki.org/alex/2008-09-17_describe-hash-table
(defun describe-hash-table (variable &optional buffer)
  "Display the full documentation of VARIABLE (a symbol).
Returns the documentation as a string, also.  If VARIABLE has a
buffer-local value in BUFFER (default to the current buffer), it
is displayed along with the global value."
  (interactive
   (let ((v (variable-at-point))
	 (enable-recursive-minibuffers t)
	 val)
     (setq val (completing-read
		(if (and (symbolp v)
			 (hash-table-p (symbol-value v)))
		    (format
		     "Describe hash-table (default \"%s\"): " v)
		  "Describe hash-table: ")
		obarray
		(lambda (atom) (and (boundp atom)
				    (hash-table-p (symbol-value atom))))
		t nil nil
		(if (hash-table-p v) (symbol-name v))))
     (list (if (equal val "")
	       v (intern val)))))
  (let ((value (if (symbolp variable)
                   (symbol-value variable)
                 variable)))
    (if (hash-table-p value)
        (pp-hash-table value)
      (message "You didn't specify a hash-table"))))

(defalias 'display-hash-table 'describe-hash-table)
(defalias 'show-hash-table 'describe-hash-table)
(defalias 'view-hash-table 'describe-hash-table)
(defalias 'print-hash-table 'describe-hash-table)
;; Use: (describe-hash-table 'tramp-cache-data)

;; ---------------------------------------------------------------------------
;; Note: Emacs 23.2 now support hash-tables in `prin1'.

;; Steve Yegge published Ejacs over the weekend, which included some
;; (IMHO very reasonable) complaints about Emacs Lisp's lack of
;; hashtable serialization. I propose the following functions
;; (originalsb were contributed to Gnus by Andreas Fuchs <asf@...>):
(defun hash-table-to-alist (table)
  "Build an alist of elements in the hash table TABLE.
Useful for sorted access of hash tables."
  (let ((alist nil))
    (maphash (lambda (key value)
               (setq alist (cons (cons key value) alist)))
             table) alist))
;; Use: (hash-table-to-alist tramp-cache-data)

(defun hash-table-to-key-list (table)
  "Build a list of keys in the hash table TABLE.
Useful for key-sorted access of hash tables."
  (let ((alist nil))
    (maphash (lambda (key value)
               (setq alist (cons key alist)))
             table) alist))
;; Use: (hash-table-to-key-list tramp-cache-data)

(defun hash-table-to-value-list (table)
  "Build a list of values in the hash table TABLE.
Useful for value-sorted access of hash tables."
  (let ((alist nil))
    (maphash (lambda (key value)
               (setq alist (cons value alist)))
             table) alist))
;; Use: (hash-table-to-value-list tramp-cache-data)

(defun hash-table-to-vector (table)
  "Build a vector of elements in the hash table TABLE.
Useful for sorted access of hash tables."
  (let ((vec (make-vector (hash-table-count table) nil))
        (idx 0))                        ;vector index
    (maphash (lambda (key value)
               (aset vec idx (cons key value))
               (setq idx (1+ idx)))
             table) vec))
;; Use: (hash-table-to-vector tramp-cache-data)

(defun hash-table-to-key-vector (table)
  "Build a vector of keys in the hash table TABLE.
Useful for sorted access of hash tables."
  (let ((vec (make-vector (hash-table-count table) nil))
        (idx 0))                        ;vector index
    (maphash (lambda (key value)
               (aset vec idx key)
               (setq idx (1+ idx)))
             table) vec))
;; Use: (hash-table-to-key-vector tramp-cache-data)

(defun hash-table-to-value-vector (table)
  "Build a vector of values in the hash table TABLE.
Useful for sorted access of hash tables."
  (let ((vec (make-vector (hash-table-count table) nil))
        (idx 0))                        ;vector index
    (maphash (lambda (key value)
               (aset vec idx value)
               (setq idx (1+ idx)))
             table) vec))
;; Use: (hash-table-to-value-vector tramp-cache-data)

;; Use: (progn (hash-table-to-alist fmd-matcher-cache) (prin1
;; fmd-matcher-cache)) this would take the usual make-hash-table arguments
;; (:test, :size, :rehash-size, :rehash-threshold, :weakness) so those don't
;; have to get serialized with the alist.  This makes the implementation much
;; simpler, complicating life slightly for the API consumers
(defun alist-to-hash-table (alist &rest options)
  "Build a hash table from the key-value-pairs in ALIST."
  (let ((ht (apply 'make-hash-table options)))
    (mapc
     (lambda (kv-pair)
       (puthash (car kv-pair)
                (cdr kv-pair) ht))
     alist) ht))
(defalias 'hash-table-from-alist 'alist-to-hash-table)

;; Profile: (benchmark-run 100000 (hash-table-to-alist tramp-cache-data))
;; Profile: (benchmark-run 100000 (hash-table-to-vector tramp-cache-data))
;; Profile: (benchmark-run 100000 (hash-table-to-key-list tramp-cache-data))
;; Profile: (benchmark-run 100000 (hash-table-to-value-list tramp-cache-data))

;; Profile
(defun benchmark-hash-table-to (table &optional repetitions)
  "Benchmark hash table conversions."
  (interactive)
  (unless repetitions (setq repetitions 100))
  (eval
   `(list
     (cons "to-alist       " (benchmark-run ,repetitions (hash-table-to-alist table)))
     (cons "to-vector      " (benchmark-run ,repetitions (hash-table-to-vector table)))
     (cons "to-key-list    " (benchmark-run ,repetitions (hash-table-to-key-list table)))
     (cons "to-key-vector  " (benchmark-run ,repetitions (hash-table-to-key-vector table)))
     (cons "to-value-list  " (benchmark-run ,repetitions (hash-table-to-value-list table)))
     (cons "to-value-vector" (benchmark-run ,repetitions (hash-table-to-value-vector table))))))
;; Use: (benchmark-hash-table-to (fcache-dir-subs "/bin") 1000)
;; Use: (benchmark-hash-table-to dcache-gdirs 5000)

(provide 'hash-table-utils)
