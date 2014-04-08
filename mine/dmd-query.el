;;; dmd-query.el --- Query Information at point using DMD.

(require 'faze)
(require 'relangs)

(defgroup dmd-query nil
  "Query Context using -query flag to DMD."
  :group 'tools)

(defun dmd-query-message ()
  (when (eq major-mode 'd-mode)
    (let* ((str (shell-command-to-string (format "dmd -query=%s:%s %s"
                                                 (current-line)
                                                 (1+ (current-column))
                                                 (buffer-file-name))))
           (off (if (string-has-beginning str "DMD v2")
                    (1+ (string-find-string "\n" str))
                  0))
           )
      (when (< off (length str))
        (message (substring (string-strip str) off))))))

(defvar dmd-query-last nil "Last DMD query made.")

(defcustom dmd-query-timeout 0.5
  "Idle time before DMD query is made."
  :group 'dmd-query)

(defun dmd-query-spawn-message ()
  (when (and dmd-query-last
             (timerp dmd-query-last))
    (cancel-timer dmd-query-last))
  (setq dmd-query-last
        (run-with-idle-timer 0.5 nil 'dmd-query-message)))

(defun activate-dmd-query-mode ()
  (add-hook 'post-command-hook 'dmd-query-spawn-message t))
(defun dectivate-dmd-query-mode ()
  (remove-hook 'post-command-hook 'dmd-query-spawn-message t))

(add-hook 'd-mode-hook 'activate-dmd-query-mode t)

(provide 'dmd-query)
