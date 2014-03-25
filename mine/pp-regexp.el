;;; pp-regexp.el --- Pretty Print Regular Expressions.
;; Author: Per Nordlöw

(defun translate-rnt (regexp)
  "REGEXP is a string.  Translate any \t \n \r and \f characters
to wierd non-ASCII printable characters: \t to Î (206, \xCE), \n
to ñ (241, \xF1), \r to ® (174, \xAE) and \f to £ (163, \xA3).
The original string is modified."
  (let (pos)
    (while (setq pos (string-match "[\t\n\r\f]" regexp))
      (let ((ch (aref regexp pos)))
        (aset regexp pos
              (cond ((eq ch ?\t) ?Î)
                    ((eq ch ?\n) ?ñ)
                    ((eq ch ?\r) ?®)
                    (t           ?£)))))
    regexp))

(defun pp-regexp (regexp)
  "Pretty print a regexp.  This means, contents of \\\\\(s are lowered a line."
  (or (stringp regexp) (error "parameter is not a string"))
  (let ((depth 0)
        (re (copy-sequence regexp))
        (start 0)       ; earliest position still without an acm-depth property.
        (pos 0)         ; current analysis position.
        (max-depth 0)   ; How many lines do we need to print?
        (min-depth 0)   ; Pick up "negative depth" errors.
        pr-line         ; output line being constructed
        line-no ; line number of pr-line, varies between min-depth and max-depth.
        result
        )
    (translate-rnt re)
    ;; apply acm-depth properties to the whole string.
    (while (< start (length re))
      (setq pos (string-match "\\\\\\((\\(\\?:\\)?\\||\\|)\\)"
                              re start))
      (put-text-property start (or pos (length re)) 'acm-depth depth re)
      (when pos
        (let ((ch (aref (match-string 1 re) 0)))
          (cond
           ((eq ch ?\()
            (put-text-property pos (match-end 1) 'acm-depth depth re)
            (setq depth (1+ depth))
            (if (> depth max-depth) (setq max-depth depth)))

           ((eq ch ?\|)
            (put-text-property pos (match-end 1) 'acm-depth (1- depth) re)
            (if (< (1- depth) min-depth) (setq min-depth (1- depth))))

           (t                           ; (eq ch ?\))
            (setq depth (1- depth))
            (if (< depth min-depth) (setq min-depth depth))
            (put-text-property pos (match-end 1) 'acm-depth depth re)))))
      (setq start (if pos (match-end 1) (length re))))

    ;; print out the strings
    (setq line-no min-depth)
    (while (<= line-no max-depth)
      (with-temp-buffer
        (goto-char (point-max)) (insert ?\n)
        (setq pr-line "")
        (setq start 0)
        (while (< start (length re))
          (setq pos (next-single-property-change start 'acm-depth re (length re)))
          (setq depth (get-text-property start 'acm-depth re))
          (setq pr-line
                (concat pr-line
                        (if (= depth line-no)
                            (substring re start pos)
                          (make-string (- pos start) ?\ ))))
          (setq start pos))
        (insert pr-line)
        (setq line-no (1+ line-no))
        (setq result (buffer-string))
        (message result)
        ))))

(defalias 'pretty-show-regexp 'pp-regexp)

;; Use: (pp-regexp "\\(?:\\([a-z]\\)\\([a-z0-9]\\)\\)")

(provide 'pp-regexp)
