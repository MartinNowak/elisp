;;; move-line-region.el --- Move lines and/or regions.
;; Author: Per Nordlöw (per.nordlow@gmail.com)

;;; See: http://www.emacswiki.org/emacs-en/MoveLine
;;; See: http://www.emacswiki.org/emacs-en/MoveRegion
;;; See: http://www.emacswiki.org/emacs-en/MoveLineRegion

(defun move-line (n)
  "Move the current line up or down by N lines."
  (interactive "p")
  (let ((col (current-column)))
    (beginning-of-line)
    (let ((start (point)))
      (end-of-line)
      (forward-char)
      (let* ((end (point))
             (line-text (delete-and-extract-region start end)))
        (forward-line n)
        (insert line-text)
        ;; restore point to original column in moved line
        (forward-line -1)
        (forward-char col)))))

(defun move-line-up (n)
  "Move the current line up by N lines."
  (interactive "p")
  (move-line (if (null n) -1 (- n))))

(defun move-line-down (n)
  "Move the current line down by N lines."
  (interactive "p")
  (move-line (if (null n) 1 n)))

(when nil
  (defun move-line-up ()
    (interactive)
    (transpose-lines 1)
    (forward-line -2))
  (defun move-line-down ()
    (interactive)
    (forward-line 1)
    (transpose-lines 1)
    (forward-line -1)))

(defun move-region (start end n)
  "Move the current region up or down by N lines."
  (interactive "r\np")
  (let ((line-text (delete-and-extract-region start end)))
    (forward-line n)
    (let ((start (point)))
      (insert line-text)
      (setq deactivate-mark nil)
      (set-mark start))))

(defun move-region-up (start end n)
  "Move the current line up by N lines."
  (interactive "r\np")
  (move-region start end (if (null n) -1 (- n))))

(defun move-region-down (start end n)
  "Move the current line down by N lines."
  (interactive "r\np")
  (move-region start end (if (null n) 1 n)))

(defun move-line-region-up (start end n)
  "Move line or region up."
  (interactive "r\np")
  (if (region-active-p) (move-region-up start end n) (move-line-up n)))

(defun move-line-region-down (start end n)
  "Move line or region down."
  (interactive "r\np")
  (if (region-active-p) (move-region-down start end n) (move-line-down n)))

(defun move-line-region-setup-keybindings ()
  "Setup keybindings for move-line-region."
  (interactive)
  (global-set-key (kbd "M-P") 'move-line-region-up)
  (global-set-key (kbd "M-N") 'move-line-region-down)
  ;; (global-set-key (kbd "M-<up>") 'move-line-up)
  ;; (global-set-key (kbd "M-<down>") 'move-line-down)
  ;; (global-set-key (kbd "M-<up>") 'move-region-up)
  ;; (global-set-key (kbd "M-<down>") 'move-region-down)
  )

(defun move-line-region-activate-hictx-advice ()
  (when (require 'hictx nil t)
    (defadvice move-line-up (after ctx-flash-move-line-up activate compile) (when (called-interactively-p 'any) (hictx-line)))
    (defadvice move-line-down (after ctx-flash-move-line-down activate compile) (when (called-interactively-p 'any) (hictx-line)))
    (defadvice move-region-up (after ctx-flash-move-region-up activate compile) (when (called-interactively-p 'any) (hictx-line)))
    (defadvice move-region-down (after ctx-flash-move-region-down activate compile) (when (called-interactively-p 'any) (hictx-line)))
    (defadvice move-line-region-up (after ctx-flash-move-line-region-up activate compile) (when (called-interactively-p 'any) (hictx-line)))
    (defadvice move-line-region-down (after ctx-flash-move-line-region-down activate compile) (when (called-interactively-p 'any) (hictx-line)))
    )
  )

(provide 'move-line-region)
