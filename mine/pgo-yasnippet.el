;;; pgo-yasnippet.el --- Setup YASnippet from http://code.google.com/p/yasnippet/

;; Note: Use 'yasnippet or 'yasnippet-bundle
(when (eload 'yasnippet)
  (yas/initialize)

  ;; (add-to-list 'yas/extra-mode-hooks 'ruby-mode-hook)
  ;; (delete 'python-mode-hook yas/extra-mode-hooks)

  ;; Note: This takes some time.
  (message "Loading yasnippet snippets...")
  (yas/load-directory (elsub "yasnippet/snippets"))

  ;; (setq yas/trigger-key (kbd "M-§"))
  ;; (setq yas/next-field-key (kbd "M-§"))
  ;; (setq yas/previous-field-key (kbd "M-½"))
  (define-key yas/keymap [(meta p)] 'yas/prev-field)
  (define-key yas/keymap [(meta n)] 'yas/next-field)
  ;;(global-set-key [(meta shift p)] 'yas/first-field-group)
  ;;(global-set-key [(meta shift n)] 'yas/last-field-group)
  ;;(global-set-key [(left)] 'yas/prev-field-group)
  ;;(global-set-key [(right)] 'yas/next-field-group)

  ;; Usage:
  ;; You've just entered a function name but forgot its arguments (cursor is on ^):
  ;; (push ^)
  ;; then running lisp-snippet-insert will expand the snippet:
  ;; (push ${1:x} {2:place})
  (when (require 'lisp-snippet-insert nil t)
    )

  ;; Note: Compare with `yas/hippie-try-expand'.
  (defun try-expand-yas (&optional bogus)
    (interactive)
    (let ((local-condition (yas/template-condition-predicate
                            yas/buffer-local-condition)))
      (if local-condition
          (let ((yas/require-template-condition
                 (if (and (consp local-condition)
                          (eq 'require-snippet-condition (car local-condition))
                          (symbolp (cdr local-condition)))
                     (cdr local-condition)
                   nil)))
            (multiple-value-bind (key start end) (yas/current-key)
              (let ((templates (yas/snippet-table-fetch (yas/current-snippet-table)
                                                        key)))
                (if templates
                    (let ((template (if (null (cdr templates)) ; only 1
                                        template
                                      (yas/template-content (cdar
                                                             templates))
                                      (yas/popup-for-template
                                       templates))))
                      (when template
                        (yas/expand-snippet start end template))))))))))

  (when (require 'yas-jit nil t)
    )
  )

;; No more Yasnippet pop-up menus
;; http://www.shellarchive.co.uk/index.html#%20No%20more%20Yasnippet%20pop-up%20menus
;;'(yas/x-prompt yas/dropdown-prompt yas/completing-prompt yas/ido-prompt yas/no-prompt)
(setq yas/prompt-functions '(yas/completing-prompt))

(provide 'pgo-yasnippet)
