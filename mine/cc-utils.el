;;; cc-utils.el --- Small cc-mode utilites.
;; Author: Per Nordlöw <per.nordlow@gmail.com>

(require 'semantic)

(defvar cc-derived-modes
  '(c-mode c++-mode objc-mode java-mode csharp-mode d-mode)
  "List of C-like modes.")
(defalias 'cc-like-modes 'cc-derived-modes)

(defun cc-derived-mode-p (&optional mode)
  "Return non-nil if MODE is a c-like mode, meaning member of `cc-derived-modes'.
MODE defaults to `major-mode'."
  (if mode
      (when (memq mode cc-derived-modes) t) ;TODO Get this list from cc-mode sources instead.
    c-buffer-is-cc-mode))
;; Use: (cc-derived-mode-p 'c-mode)
;; Use: (cc-derived-mode-p)

;; TODO Use `semantic-current-tag', semantic/ctxt semantic-ctxt-current-...
(defun c-beginning-of-topmost-intro-p ()
  (interactive)
  "Return t if point is at the beginning of a definition."
  (delq nil (mapcar
             (lambda (elt)
               (eq (car elt) 'topmost-intro))
             (c-guess-basic-syntax)))
  ;; if standing on an empty line
  ;; (or (and (looking-back (rx bol))
  ;;          (looking-at "[^[:space:]]"))
  ;;     (and (looking-back (rx bol (* space)))
  ;;          (looking-forward (rx (* space) eol))))
  )

(provide 'cc-utils)
