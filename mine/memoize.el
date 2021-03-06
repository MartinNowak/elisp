;;; memoize.el --- memoize elisp functions

;; Written by Christopher Wellons <mosquitopsu@gmail.com>
;; This program is public domain.
;; See: http://nullprogram.com/blog/2010/07/26/

;;; Commentary:

;; Memoizing an interactive function will render that function
;; non-interactive. It would be easy to fix this problem when it comes
;; to non-byte-compiled functions, but recovering the interactive
;; definition from a byte-compiled function is more complex than I
;; care to deal with. Besides, interactive functions are always used
;; for their side effects anyway.

;; There's no way to memoize nil returns, but why would your expensive
;; functions do all that work just to return nil? :-)

;; If you wait to byte-compile the function until *after* it is
;; memoized then the function and memoization wrapper both get
;; compiled at once, so there's no special reason to do them
;; separately. But there really isn't much advantage to compiling the
;; memoization wrapper anyway.

(defun memoize-function (func &optional test-fn)
  "Memoize function FUNC. If argument is a symbol then install
the memoized function over the original."
  (typecase func
    (symbol (fset func (memoize-wrap (symbol-function func))) func)
    (function (memoize-wrap func test-fn))))
(defalias 'memoize 'memoize-function)

;; ID: 83bae208-da65-3e26-2ecb-4941fb310848
(defun memoize-wrap (func &optional test-fn)
  "Return the memoized version of the function FUNC."
  (let ((table-sym (gensym))
        (val-sym (gensym))
        (args-sym (gensym)))
    (set table-sym (make-hash-table :test (or test-fn 'equal)))
    `(lambda (&rest ,args-sym)
       ,(concat (documentation func) "\n(memoized function)")
       (let ((,val-sym (gethash ,args-sym ,table-sym)))
         (if ,val-sym
             ,val-sym
           (puthash ,args-sym (apply ,func ,args-sym) ,table-sym))))))

(defun whiten (key)
  "Perform key whitening with the MD5 Hash Function."
  (dotimes (i 100000 key)
    (setq key (md5 key))))
;; Use: (memoize 'whiten)
;; Use: (memoize-wrap 'whiten)
;; Use: (whiten "password")

(fset 'shell-command-to-string-memoized
      (memoize-wrap (symbol-function 'shell-command-to-string)))
;; Use: (shell-command-to-string-memoized "gdb --version")

(provide 'memoize)
