;;; dabbrev-substring.el --- Substring Dabbrev Expansion.

(defvar dabbrev-substring-match-region nil
  "Match region.")

(defun dabbrev-substring-search (pattern &optional reverse limit syntax-context)
  "Expand dabbrev substring. See:
http://www.emacswiki.org/cgi-bin/wiki/HippieExpand#toc5"
  (let ((result ())
        (regpat (cond ((not hippie-expand-dabbrev-as-symbol)
                       (concat (regexp-quote pattern) W*))
                      ;; ((eq (char-syntax (aref pattern 0)) ?_)
                      ;;  (concat (regexp-quote pattern)
                      ;;          "\\(\\sw\\|\\s_\\)*"))
                      (t
                       (concat "\\(?:"
                               Y<
                               "\\(" "\\(?:\\sw\\|\\s_\\)+" "\\)"
                               "\\(" (regexp-quote pattern) "\\)"
                               "\\(" "\\(?:\\sw\\|\\s_\\)*" "\\)"
                               Y>
                               "\\)"

                               "\\|"

                               "\\(?:"
                               Y<
                               "\\(" "\\(?:\\sw\\|\\s_\\)*" "\\)"
                               "\\(" (regexp-quote pattern) "\\)"
                               "\\(" "\\(?:\\sw\\|\\s_\\)+" "\\)"
                               Y>
                               "\\)"

                               )))))
    (while (and (not result)
                (if reverse
                    (re-search-backward regpat limit t)
                  (re-search-forward regpat limit t)))
      (setq result (buffer-substring-no-properties (save-excursion
                                                     (goto-char (match-beginning 0))
                                                     ;;(skip-syntax-backward "w_")
                                                     (point))
                                                   (match-end 0)))

      (if (he-string-member result he-tried-table t)
          (setq result nil)))       ; ignore if bad prefix or already in table

    (when nil
      (when result
        (let* ((p (point))
               (end3 (match-end 3))
               (beg2 (match-end 2))
               (end2 (match-end 2))
               (dummy (message "%s %s %s" end3 beg2 end2))
               (beg (- end3 beg2))    ;begin offset from point
               (end (- end3 end2)))   ;end offset from point
          (setq dabbrev-substring-match-region (cons beg end))
          (hictx-generic (- p beg) (- p end) nil 'match 3))))

    result))
;; Use: (dabbrev-substring-search "he-dabbrev")

(defun try-expand-dabbrev-substring-visible (old)
  "Like `try-expand-dabbrev' but for visible part of buffer."
  (interactive "P")
  (let ((old-fun (symbol-function 'he-dabbrev-search)))
    (fset 'he-dabbrev-search (symbol-function 'dabbrev-substring-search))
    (unwind-protect (try-expand-dabbrev-visible old)
      (fset 'he-dabbrev-search old-fun))))

(defun try-expand-dabbrev-substring (old)
  "Like `try-expand-dabbrev' but for substring match."
  (interactive "P")
  (let ((old-fun (symbol-function 'he-dabbrev-search)))
    (fset 'he-dabbrev-search (symbol-function 'dabbrev-substring-search))
    (unwind-protect (try-expand-dabbrev old)
      (fset 'he-dabbrev-search old-fun))))

(defun try-expand-dabbrev-substring-all-buffers (old)
  "Like `try-expand-dabbrev-all-buffers' but for substring match."
  (interactive "P")
  (let ((old-fun (symbol-function 'he-dabbrev-search)))
    (fset 'he-dabbrev-search (symbol-function 'dabbrev-substring-search))
    (unwind-protect (try-expand-dabbrev-all-buffers old)
      (fset 'he-dabbrev-search old-fun))))

(provide 'dabbrev-substring)
