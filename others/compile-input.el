;;; compile-input.el

(defun compile-enable-input ()
  "Enable user input to *compilation* buffers.
To do so, add this function to compilation-mode-hook."

  (setq buffer-read-only nil)		;we first must make buffer changeable

  ;; Emulate comint-mode:
  (require 'comint)
  (set (make-local-variable 'comint-input-ring)
       (make-ring comint-input-ring-size))
  (set (make-local-variable 'comint-last-input-start)
       (make-marker))
  (set-marker comint-last-input-start (point-min))
  (set (make-local-variable 'comint-last-input-end)
       (make-marker))
  (set-marker comint-last-input-end (point-min))
  (set (make-local-variable 'comint-last-output-start)
       (make-marker))
  (set-marker comint-last-output-start (point-max))
  (set (make-local-variable 'comint-accum-marker)
       (make-marker))
  (set-marker comint-accum-marker nil)
  (add-hook (make-local-variable 'pre-command-hook)
	    'comint-preinput-scroll-to-bottom)
  ;; Move point to EOB on input:
  (set (make-local-variable 'comint-scroll-to-bottom-on-input)
       'this)
  ;; Restore useful bindings for input:
  (local-unset-key " ")			; was scroll-up
  (local-unset-key "\^?")		; was scroll-down
  ;; Add bindings to send input to compilation process:
  (local-set-key "\C-c\C-d" 'comint-send-eof)
  (local-set-key "\C-m" 'comint-send-input)
  ;; Enable input:
  (set (make-local-variable 'compile-disable-input) nil))

(add-hook 'compilation-mode-hook 'compile-enable-input)

(provide 'compile-input)
