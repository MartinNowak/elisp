;;; acronym.el --- Build string acronyms.

(defun acronymize-string (string &optional ctx group)
  (let ((mid (cond ((eq ctx 'word)
                    "[[:word:]]*?")
                   ((eq ctx 'symbol)
                    "[[:word:]_]*?"))))
    (concat
     (when group "\\(?:")
     (cond ((eq ctx 'word) "\\<")
           ((eq ctx 'symbol) "\\_<"))
     mid
     (mapconcat (lambda (x) (regexp-quote (string x)))
                (string-to-list string)
                "[[:word:]_]*?"         ;non-greedy-match
                )
     mid
     (cond ((eq ctx 'word) "\\>")
           ((eq ctx 'symbol) "\\_>"))
     (when group "\\)"))))
;; Use: (acronymize-string "alpha")
;; Use: (acronymize-string "a.b")
;; Use: (acronymize-string "a-b")
;; Use: (re-search-forward (acronymize-string "Dy"))
;; _Dummy_
;; Use: (re-search-forward (acronymize-string "Dy" 'word))
;; Use: (re-search-forward (acronymize-string "Dy" 'symbol t))
;; Use: (re-search-forward (acronymize-string "Dy" 'symbol))
;; _Dummy_
(defalias 'string-acronym 'acronymize-string)

(provide 'acronym)
