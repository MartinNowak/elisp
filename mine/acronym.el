;;; acronym.el --- Build string acronyms.

(defun acronymize-string (str &optional ctx group mode)
  (let ((mid (cond ((eq ctx 'word)
                    "[[:word:]]*?")
                   ((eq ctx 'symbol)
                    (if (memq mode '(emacs-lisp-mode elisp-mode))
                        "[[:word:]_-]*?"
                      "[[:word:]_]*?")))))
    (concat
     (when group "\\(?:")
     (cond ((eq ctx 'word) "\\<")
           ((eq ctx 'symbol) "\\_<"))
     mid
     (mapconcat (lambda (x)
                  (regexp-quote (string x)))
                str
                (if (memq mode '(emacs-lisp-mode elisp-mode))
                    "[[:word:]_-]*?"
                  "[[:word:]_]*?")      ;non-greedy-match
                )
     mid
     (cond ((eq ctx 'word) "\\>")
           ((eq ctx 'symbol) "\\_>"))
     (when group "\\)"))))
;; Use: (acronymize-string "alpha")
;; Use: (acronymize-string "alpha" nil nil 'emacs-lisp-mode)
;; Use: (acronymize-string "a.b")
;; Use: (acronymize-string "a-b")
;; Use: (re-search-forward (acronymize-string "Dy"))
;; _Dummy_
;; Use: (re-search-forward (acronymize-string "Dy" 'word))
;; Use: (re-search-forward (acronymize-string "Dy" 'symbol t))
;; Use: (re-search-forward (acronymize-string "Dy" 'symbol))
;; _Dummy_
;; (acronymize-string "E_F" 'symbol t)
(defalias 'string-acronym 'acronymize-string)

(provide 'acronym)
