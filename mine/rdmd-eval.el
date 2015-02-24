;;; rdmd-eval.el --- D Code evaluation through rdmd
;;; Author: Per Nordlöw
;;; Commentary:
;;; Code:

(defvar d-eval-expression-history nil "D Expression Evaluation History.")

(when (require 'desktop nil t)
  (add-to-list 'desktop-globals-to-save 'd-eval-expression-history t))

(defun d-eval-expression (arg)
  "Evaluate D Expression ARG using rdmd and print value in the echo area."
  (interactive (list
                (let ((def (when (region-active-p)
                             (string-strip (buffer-substring (region-beginning)
                                                             (region-end))))))
                  (read-string (format "D Eval%s: "
                                       (if def (format " (default %s)" (faze def 'string)) ""))
                               nil
                               'd-eval-expression-history
                               def))))

  (message (replace-regexp-in-string    ;strip ending whitespace
            "[[:space:]\n]*\\'" ""
            (shell-command-to-string (concat "rdmd --eval=\"" arg "\"")))))

(defun d-eval-expression-hook ()
  (let ((km d-mode-map))
    (define-key km [(meta ?:)] 'd-eval-expression)))

(add-hook 'd-mode-hook 'd-eval-expression-hook t)

(provide 'rdmd-eval)
