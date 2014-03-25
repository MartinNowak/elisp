;;; expand-alias.el --- Expand Emacs Lisp Aliases upon use.

(defun expand-alias (&optional beg end length)
  (interactive)
  (when (and (at-syntax-code-p)
             (not (memq this-command '(undo
                                       undo-tree-undo undo-tree-visualize-undo
                                       undo-tree-redo undo-tree-visualize-redo
                                       ))))
    (let* ((str (ignore-errors (and (require 'semantic-ctxt nil t)
                                    (semantic-ctxt-current-symbol))))
           (str (cond ((listp str)     ;if list
                       (car str))      ;pick first in list
                      ((stringp str)   ;if string
                       str)))          ;string itself
           (sym (intern-soft str))
           )
      (when (and sym (functionp sym))   ;if symbol is a non-nil function
        (let* ((sym-fun (symbol-function sym)))
          (when (symbolp sym-fun)
            (let* ((bounds (caddr (semantic-ctxt-current-symbol-and-bounds))))
              (when bounds
                (kill-region (car bounds) (cdr bounds))
                (insert (symbol-name sym-fun))
                (when (require 'hictx nil t)
                  (hictx-sexp-bfpt))
                (message "Replaced alias %s with its function %s"
                         (faze str 'function-alias)
                         (faze (symbol-name sym-fun) 'function))))
            )))
      )))

(add-hook 'emacs-lisp-mode-hook (lambda () (add-hook 'after-change-functions 'expand-alias t t)) t)

(provide 'expand-alias)
