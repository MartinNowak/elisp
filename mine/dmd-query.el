;;; dmd-query.el --- Query Information at point using DMD.

(require 'faze)
(require 'relangs)

(defgroup dmd-query nil
  "Query Context using -query flag to DMD."
  :group 'tools)

(defvar dmd-query-buffer-name " *dmd-query*")

(defun dmd-query-completed (process change)
  (when (string-equal change "finished\n") ;success
    (with-current-buffer dmd-query-buffer-name
      (let* ((str (buffer-substring-no-properties (point-min)
                                                  (point-max)))
             (off (if (string-has-beginning str "DMD v") ;skip DMD devel build tag
                      (1+ (string-find-string "\n" str))
                    0)))
        (when (< off (length str))
          (let* ((fields (split-string
                          (substring (string-strip str) off)
                          "\t"))
                 (description (first fields))
                 (value (second fields))
                 (type (car (last fields))) ;last character
                 (face (cond ((string-equal type "K") 'font-lock-keyword-face)
                             ((string-equal type "S") 'font-lock-string-face)
                             ((string-equal type "N") 'font-lock-number-face)
                             ((string-equal type "T") 'font-lock-type-face)
                             (t 'default)))
                 )
            (message "%s: %s"
                     (propertize description 'face font-lock-comment-face)
                     (propertize value 'face face)
                     ;; (propertize  'face face)
                     ))))))
  ;; cleanup
  (when dmd-query-process
    (delete-process dmd-query-process)
    (setq dmd-query-process nil))
  (when (get-buffer dmd-query-buffer-name)
    (kill-buffer dmd-query-buffer-name))
  )

(defvar dmd-query-process nil "Value of last process started")

(defun dmd-query-message-helper ()
  "Show DMD Lex Message."

  ;; cleanup last if any
  (when dmd-query-process
    (delete-process dmd-query-process)
    (setq dmd-query-process nil))
  (when (get-buffer dmd-query-buffer-name)
    (kill-buffer dmd-query-buffer-name))

  (set-process-sentinel
   (setq dmd-query-process
         (start-process "dmd-query"
                        dmd-query-buffer-name
                        "dmd"
                        (format "-query=%s:%s"
                                (current-line)
                                (1+ (current-column)))
                        (buffer-file-name)))
   'dmd-query-completed))

(defun dmd-query-message ()
  (when (eq major-mode 'd-mode)
    (dmd-query-message-helper)))

(defvar dmd-query-timer nil "Last DMD query made.")

(defcustom dmd-query-timeout 0.15
  "Idle time before DMD query is made."
  :group 'dmd-query)

(defun dmd-query-spawn-message ()
  (when (and dmd-query-timer
             (timerp dmd-query-timer))
    (cancel-timer dmd-query-timer))
  (setq dmd-query-timer
        (run-with-idle-timer dmd-query-timeout nil 'dmd-query-message)))

(defun activate-dmd-query-mode ()
  (add-hook 'post-command-hook 'dmd-query-spawn-message t))
(defun dectivate-dmd-query-mode ()
  (remove-hook 'post-command-hook 'dmd-query-spawn-message t))

(add-hook 'd-mode-hook 'activate-dmd-query-mode t)

(provide 'dmd-query)
