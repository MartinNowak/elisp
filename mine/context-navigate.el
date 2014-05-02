;;; context-navigate.el --- Navigate in Contexts
;; Author: Per Nordlöw

(defun goto-matching-paren (arg)
  "Go to the matching parenthesis if on parenthesis otherwise insert %."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
        ((looking-at "\\s\)") (backward-list 1) (backward-list 1))
        (t (self-insert-command (or arg 1)))))

(defalias 'goto-point 'goto-char)

(global-set-key [(meta g) (meta c)] 'goto-char)
(global-set-key [(meta g) (meta l)] 'goto-line)

(defun display-byte-offset-at-point ()
  "Show Buffer Byte Offset of point.
See https://unix.stackexchange.com/questions/39786/in-emacs-or-other-editor-how-to-display-the-byte-offset-of-the-cursor"
  (interactive)
  (message "Buffer Byte Offset: %s" (position-bytes (point))))
(defalias 'show-byte-offset-at-point 'display-byte-offset-at-point)
(defalias 'byte-offset-at-point 'display-byte-offset-at-point)

;; Note: Replaced by goto-chg.el
;; Set point to the position of the last change.
;; Note: See also session-jump-to-last-change().
;; (load-file-if-exist (elsub "goto-last-change.elc")
;; (defalias 'jump-to-last-change 'goto-last-change)

;;; goto-chg.el --- goto last change
(when (require 'goto-chg nil t)
  ;;(global-set-key "\C-x\C-\\" 'goto-last-change)
  ;;(global-set-key "\C-x\C-S-\\" 'goto-last-change-reverse)
  (global-set-key [(meta g) (meta z)] 'goto-last-change)
  (global-set-key [(meta g) (meta shift z)] 'goto-last-change-reverse)
  )

(provide 'context-navigate)
