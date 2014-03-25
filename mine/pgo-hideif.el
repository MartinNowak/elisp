;; hideif.el
;; See ~/elisp/hideif.patch

(when (eload 'hideif)               ; hides selected code within ifdef

  (defface hide-ifdef-shadow-face '((t (:inherit shadow)))
    "Face for shadowing ifdef blocks."
    :group 'hide-ifdef)

  (defun hide-ifdef-region-internal (start end)
    (remove-overlays start end 'face 'hide-ifdef-shadow-face)
    (let ((o (make-overlay start end)))
      (overlay-put o 'face 'hide-ifdef-shadow-face)))

  (defun hif-show-ifdef-region (start end)
    "Everything between START and END is made visible."
    (remove-overlays start end 'face 'pnw/hide-ifdef-region-face))

  ;; NOTE: Deactivated because it does not dynamically update when I
  ;; change #if 0 statments to say #if 1.
  (if 0
      (add-hook 'hide-ifdef-mode-hook
                (lambda ()
                  (unless hide-ifdef-define-alist
                    (setq hide-ifdef-define-alist
                          '((list1 0)
                            (list2 DEBUG_CHECK_ALL))))
                  (hide-ifdef-use-define-alist 'list1))) ; use list2 by default
    )

  ;; (setq hide-ifdef-initially t)
  )

(provide 'pgo-hideif)
