;;; benchmarks.el --- Various Key Performance Benchmarks of Emacs Lisp.
;; Author: Per Nordlöw

(require 'benchmark)

(defalias 'timed-run 'benchmark-run)

(defmacro bench (&rest forms)
  "Convenience wrapper for benchmark-run-compiled."
  `(let ((n 1))
     (/ (nth 0 (benchmark-run-compiled n ,@forms)) n)))
;; Use: (bench (directory-files "/usr/lib"))
;; Use: (bench (sha1sum "/bin/ls"))

(when nil				;TODO: Fix and activate!
  (when (require 'elk-test nil t)
    (deftest "bench-1"
      (let ((length 100000))
	(cons
	 (bench (aref (make-vector length 0) (/ length 2)))
	 (bench (nth (/ length 2) (make-list length 0)))
	 )))))
;; Use: (let ((l '(x))) (message "setq-cons: %s" (benchmark-run 100000 (setq l (cons 'x l)))))
;; Use: (let ((l '(x))) (message "setq-nconc: %s" (benchmark-run 100000 (setq l (nconc l 'x)))))
;; Use: (let ((l '(x))) (message "nconc: %s" (benchmark-run 100000 (nconc l 'x))))

(defun benchmark-vector-list-middle-indexing (n &optional compile-flag)
  "Benchmark the indexing of the middle element of a vector and list both of length N."
  (let ((m (/ n 2))
        (bencher (if compile-flag 'benchmark-run-compiled 'benchmark-run)))
    (message "vector: aref: %s\n list:   nth:  %s\n list:   elt:  %s"
             (let ((x (make-vector n 'a))) (eval `(,bencher 10000 (aref x ,m))))
             (let ((x (make-list n 'a))) (eval `(,bencher 10000 (nth ,m x))))
             (let ((x (make-list n 'a))) (eval `(,bencher 10000 (elt x ,m)))))))
;; Use: (benchmark-vector-list-middle-indexing 10)
;; Use: (benchmark-vector-list-middle-indexing 100)
;; Use: (benchmark-vector-list-middle-indexing 1000)

(defmacro measure-time (&rest body)
  "Measure the time it takes to evaluate BODY."
  `(let ((time (float-time)))
     ,@body
     (message "%.03f" (- (float-time) time))))
;; It's used like this:
;; Use: (measure-time (dotimes (i 100000) (1+ 1)))
;; Use: (benchmark-run (dotimes (i 100000) (1+ 1)))

(provide 'benchmarks)
