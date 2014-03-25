;;; case-dwim.el --- Casing Do What I Mean.
;; Author: Per Nordlöw

(require 'case-utils)

(defun upcase-dwim ()
  (interactive)
  (if (region-markedp) (upcase-region (region-beginning) (region-end)) (upcase-word 1)))
(defun downcase-dwim ()
  (interactive)
  (if (region-markedp) (downcase-region (region-beginning) (region-end)) (downcase-word 1)))
(defun capitalize-dwim ()
  (interactive)
  (if (region-markedp)
      (save-excursion
        (let ((beg (region-beginning))
              (end (region-end)))
          (goto-char beg)
          (while (< (point) end)
            (capitalize-word 1))))
    (capitalize-word 1)))
(global-set-key (kbd "M-u")       'upcase-dwim)
(global-set-key (kbd "M-l")       'downcase-dwim)
(global-set-key (kbd "M-c")       'capitalize-dwim)

(provide 'case-dwim)
