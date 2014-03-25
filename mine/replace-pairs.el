;;; replace-pairs.el

(defvar query-replace-from-to-history nil
  "Default history list FROM-TO-pairs for query-replace commands.
See `query-replace-from-history-variable' and
`query-replace-to-history-variable'.")

(when (require 'desktop nil t)
  (add-to-list 'desktop-globals-to-save 'query-replace-from-to-history t))

;; REPLACE ORIGINAL in `replace.el'.
;;
;; Store replace FROM-TO pair.
;;
(defun query-replace-read-args (prompt regexp-flag &optional noerror)
  (unless noerror
    (barf-if-buffer-read-only))
  (let* ((from (query-replace-read-from prompt regexp-flag))
         (to (if (consp from) (prog1 (cdr from) (setq from (car from)))
               (query-replace-read-to from prompt regexp-flag)))
         (args (list from to current-prefix-arg)))
    (add-to-history 'query-replace-from-to-history args) ;store replacement
    args))

(provide 'replace-pairs)
