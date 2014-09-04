;;; d-backtrace.el --- D backtrace compilation highlighting.
;;; Author: Per Nordlöw
;;; Commentary:
;;; Code:

(require 'compile)

(defconst d-backtrace-regexp
  (rx (: bol
         "#" (group-n 9 (+ (in digit))) ": "
         (group-n 2 (+ (not (in space))))
         " line (" (group-n 3 (+ (in digit))) ")"
         (? (: " in " (group-n 8 (+ nonl))))
         eol)))

(defconst d-backtrace-entry
  `(d-backtrace
    ,d-backtrace-regexp              ;REGEXP
    2                                ;FILE'th subexpression
    3                                ;LINE'th subexpression
    nil                              ;COLUMN'th subexpression
    0                                ;TYPE: 0:info, 1:warning, 2/nil:error
    nil                              ;HYPERLINK/TYPELINK'th named_subexpressions
    ;; HIGHLIGHT...
    (0 'default)
    (1 'error)
    (2 'font-lock-file-name-face)
    (3 'compilation-line-number)
    (4 'compilation-column-number)
    (5 'compilation-error)
    (6 'compilation-warning)
    (7 'compilation-info)
    (8 'font-lock-comment-face)
    (9 'font-lock-number-face)
    )
  "Regexp matching of D module backtraces.")

(defun d-backtrace-install ()
  "Install d-backtrace."
  ;; TODO: Functionize this
  (let ((entry (assq 'd-backtrace
                     compilation-error-regexp-alist-alist)))
    (if entry
        (setcdr entry
                (cdr d-backtrace-entry))
      (add-to-list 'compilation-error-regexp-alist-alist d-backtrace-entry))))
;;; Use: (d-backtrace-install)

(add-to-list 'compilation-error-regexp-alist 'd-backtrace)

(provide 'd-backtrace)
;;; d-backtrace.el ends here