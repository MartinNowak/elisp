;;; pgo-octave.el --- Setup Octave.
;; Author: Per Nordlöw

(require 'power-utils)
(require 'octave-patterns)

(autoload 'octave-mode "octave-mod"
  "Major mode for editing and running Octave code." t)

(add-to-list 'auto-mode-alist '("\\.octave\\'" . octave-mode))
(add-to-list 'auto-mode-alist '(".*[oO]ctave.*/.*\\.m\\'" . octave-mode))

(add-hook 'octave-mode-hook
          (lambda ()
             (local-set-key [(meta return)] 'octave-send-line) ;eval
             (local-set-key [(control meta return)] 'octave-send-block) ;eval

             ;; make navigation similar to emacs-lisp-mode
             (local-set-key [(control meta left)] 'backward-sentence)
             (local-set-key [(control meta right)] 'forward-sentence)

             (abbrev-mode 1)
             ;;(turn-on-auto-fill)
             ;;(if (eq window-system 'x) (font-lock-mode t))
             ))

(defalias 'octave 'run-octave)

(add-hook 'inferior-octave-mode-hook
          (lambda ()
             (setq info-lookup-mode 'octave-mode) ;Tell `info-look' what mode to use.
             (define-key inferior-octave-mode-map [up] 'comint-previous-input)
             (define-key inferior-octave-mode-map [down] 'comint-next-input)))

(global-set-key [(control c) (O)] 'run-octave)

(provide 'pgo-octave)
