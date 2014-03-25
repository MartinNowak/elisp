;;; rx-delim.el --- Delimitation Interaction with rx delim symbols.
;; Merge strings and symbols into an alist with explanations.

(defun rx-read-delim-string (&optional prompt default)
  (completing-read (or prompt
                       (format "Delimitation context (default %s): "
                               (faze (if default default "none") 'string)))
                   '("word"
                     "word-start"
                     "word-end"
                     "symbol"
                     "symbol-start"
                     "symbol-end"
                     "none"
                     )
                   nil t nil nil default))
(defun rx-read-delim-symbol (&optional prompt default)
  "Delimit `rx' delimation symbol."
  (let ((str (rx-read-delim-string prompt default)))
    (when (> (length str) 0)
      (intern str))))                   ;Note: `make-symbol' will not equal 'str!

(defun default-delim-of-thing-at-point (thing)
  (let* ((sym-atpt (symbol-at-point))
         (str-atpt (when sym-atpt
                     (symbol-name sym-atpt))))
    (if (and str-atpt
             (cond ((stringp thing)
                    (string-equal str-atpt
                                  thing))
                   ((listp thing)
                    (member str-atpt
                            thing))))
        "symbol"
      "word")))

(defun read-delim-of-thing-at-point (thing)
  "Read Delimitation of thing at point."
  (rx-read-delim-symbol nil (default-delim-of-thing-at-point thing)))

(defun rx-delim (expr &optional delim)
  "Delimit `rx' expression EXPR using delim."
  (let ((delim (if (eq delim 'ask)
                   (read-delim-of-thing-at-point expr)
                 delim)))
    (cond ((eq delim 'word)
           `(rx (: word-start ,expr word-end)))
          ((eq delim 'word-start)
           `(rx (: word-start ,expr)))
          ((eq delim 'word-end)
           `(rx (: ,expr word-end)))
          ((eq delim 'symbol)
           `(rx (: symbol-start ,expr symbol-end)))
          ((eq delim 'symbol-start)
           `(rx (: symbol-start ,expr)))
          ((eq delim 'symbol-end)
           `(rx (: ,expr symbol-end)))
          (t
           `(rx (: ,expr))))))
;; Use: (eval (rx-delim "Ob" 'word))
;; Use: (eval (rx-delim "Ob" 'symbol-start))
;; Use: (eval (rx-delim "Ob" 'ask))
;; Use: (eval (rx-delim "Ob" 'ask))Ob
;; Use: (eval (rx-delim '(group (| "Dir" "File")) 'word))

(defun rx-delim-things (things prefix suffix &optional delim)
  (let ((delim (if (eq delim 'ask)
                   (read-delim-of-thing-at-point things)
                 delim)))
    (rx-delim `(: ,prefix (group (| ,@things)) ,suffix) delim)))
;; Use: (eval (rx-delim-things '("Dir" "File") "gtk" "end" 'word))
;; Use: (eval (rx-delim-things '("Dir" "File") "gtk" "end" 'ask))
;; Use: (eval (rx-delim-things '("Dir" "File") "gtk" "end" 'ask))Dir
;; Use: (eval (rx-delim-things '("Dir" "File") "gtk" "end" 'ask))File
;; Use: (eval (rx-delim-things '("Dir" "File") "gtk" "end" 'ask))X
;; Use: (eval (rx-delim-things '("Dir" "File") "gtk" "end" 'ask))

(provide 'rx-delim)
