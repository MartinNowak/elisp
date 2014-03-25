;;; cc-clang.el --- Clang Support in CC-Mode.

(require 'icicles nil t)

(setq clang-command-name (or (executable-find "~/alt/bin/clang")
                             (executable-find "/usr/bin/clang")
                             (executable-find "clang")))

(defun cc-clang-call-process (prefix &rest args)
  (let ((buf (get-buffer-create "*clang-output*"))
        res)
    (with-current-buffer buf (erase-buffer))
    (setq res (if ac-clang-auto-save
                  (apply 'call-process ac-clang-executable nil buf nil args)
                (apply 'call-process-region (point-min) (point-max)
                       ac-clang-executable nil buf nil args)))
    (with-current-buffer buf
      (unless (eq 0 res)
        (cc-clang-handle-error res args))
      ;; Still try to get any useful input.
      (cc-clang-parse-output prefix))))

(defun cc-clang-complete (&optional buffer point)
  "Complete in BUFFER at POINT using Clang."
  (interactive)
  (let* ((buffer (or buffer (current-buffer)))
         (point (or point (point))))
    (with-current-buffer buffer
      (goto-char point)
      ;; ...
      )))

(defun cc-setup-clang ()
  "Setup Clang Completion Support in Clang."
  (local-set-key [(control return)] 'cc-clang-complete))
(add-hook 'c-mode-common-hook 'cc-setup-clang)

(provide 'cc-clang)
