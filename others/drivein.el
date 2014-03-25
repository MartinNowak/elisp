;;; drivein.el
;;
;; This is free software
(require 'http-get)
(defun tv-get-drive-in-schedule (year month day)
  (interactive (list (read-from-minibuffer "Year: " (format-time-string "%Y"))
		     (read-from-minibuffer "Month: " (format-time-string "%m"))
		     (read-from-minibuffer "Day:" (format-time-string "%d"))))
  (let ((buf "*drive-in*")
	(url (concat "http://www.driveinclassics.ca/listings.asp?date="
		     (or month (format-time-string "%m"))
		     "-"
		     (or day (format-time-string "%d"))
		     "-"
		     (or year (format-time-string "%Y")))))
    (http-get url nil nil nil buf nil)
    (sit-for 15)
    (switch-to-buffer buf)
    (goto-char (point-min))
    (re-search-forward "<!--- Schedule Grid --->")
    (delete-region 1 (point))
    (re-search-forward "</th>")
    (delete-region 1 (point))
    (re-search-forward "</table>")
    (delete-region (point) (point-max))
    (perform-replace "<br>" "\n" nil nil nil nil nil (point-min)(point-max))
    (goto-char (point-min))    
    (perform-replace "<TR>" "\n" nil nil nil nil nil (point-min)(point-max))
    (goto-char (point-min))
    (while (re-search-forward "<[^>]+>" nil t nil)
      (delete-region (match-beginning 0)(match-end 0)))
    (goto-char (point-min))
    (end-of-line)
    (delete-region (point-min)(point))
    (perform-replace "" "" nil nil nil nil nil (point-min)(point-max))
    (goto-char (point-min))
    (while (re-search-forward "1?[0-9]:[0-9][0-9] [AP]M" nil t nil)
      (set-text-properties (match-beginning 0)(match-end 0) '(face font-lock-comment-face))
      (next-line 1)
      (beginning-of-line)
      (just-one-space)
      (set-text-properties (line-beginning-position)(line-end-position) '(face font-lock-keyword-face))
      (next-line 1)
      (beginning-of-line)
      (insert "\n")
      (fill-paragraph nil)
      (delete-backward-char 1))
    (goto-char (point-min))
    (insert (format "[%s %s %s]\n" day month year))))

;;; drivein.el ends here.