;;; really-hungry.el --- Really Hungry Mode.
;; Author: Per Nordlöw

(require 'cc-cmds)

(defun really-hungry-delete-backward ()
  (interactive)
  (if (and (boundp 'paredit-mode)
           paredit-mode)
      (paredit-backward-delete)
    (if (use-region-p)
        (delete-forward-char 1)         ;@see: Emacs 24.1 `delete-active-region'
      (c-hungry-delete-backwards))))

(defun really-hungry-delete-forward ()
  (interactive)
  (if (and (boundp 'paredit-mode)
           paredit-mode)
      (paredit-forward-delete)
    (if (use-region-p)
        (backward-delete-char-untabify 1) ;@see: Emacs 24.1 `delete-active-region'
      (c-hungry-delete-forward))))

(define-minor-mode really-hungry-mode
  "Toggle Hungry mode.
     With no argument, this command toggles the mode.
     Non-null prefix argument turns on the mode.
     Null prefix argument turns off the mode.

     When Hungry mode is enabled, the control delete key
     gobbles all preceding whitespace except the last.
     See the command \\[hungry-electric-delete]."
  ;; The initial value.
  nil
  ;; The indicator for the mode line.
  " Hy"
  ;; The minor mode bindings.
  '(([backspace]. really-hungry-delete-backward) ;backspace
    ([delete] . really-hungry-delete-forward)    ;delete
    )
  (require 'cc-cmds)         ;provides the functions used
  )
(defalias 'hungry-mode 'really-hungry-mode)
(defalias 'toggle-really-hungry-mode 'really-hungry-mode)
(defalias 'toggle-hungry-mode 'really-hungry-mode)

(defun turn-on-really-hungry-mode ()
  (really-hungry-mode 1))
(defun turn-off-really-hungry-mode ()
  (really-hungry-mode -1))
(defun turn-on-turn-on-really-hungry-mode ()
  (really-hungry-mode 1))

;; Use in all programming modes.
(progn
  (add-hook 'prog-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'lisp-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'emacs-lisp-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'octave-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'python-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'scons-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'bjam-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'sh-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'csharp-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'matlab-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'perl-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'scheme-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'html-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'org-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'makefile-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'autoconf-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'tex-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'latex-mode-hook 'turn-on-really-hungry-mode)
  (add-hook 'ada-mode-hook 'turn-on-really-hungry-mode)
  )

(provide 'really-hungry)
