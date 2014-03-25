;;; acronym.el --- Build string acronyms.

(defun acrnoymize-string (string &optional ctx group)
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
;; Use: (acrnoymize-string "alpha")
;; Use: (acrnoymize-string "a.b")
;; Use: (acrnoymize-string "a-b")
;; Use: (re-search-forward (acrnoymize-string "Dy"))
;; _Dummy_
;; Use: (re-search-forward (acrnoymize-string "Dy" 'word))
;; Use: (re-search-forward (acrnoymize-string "Dy" 'symbol t))
;; Use: (re-search-forward (acrnoymize-string "Dy" 'symbol))
;; _Dummy_
(defalias 'string-acronym 'acrnoymize-string)

(provide 'acronym)
