;;; file-use-region.el --- Use region when finding file.

(defun active-region-get ()
  "Get activate region if any."
  (when (region-active-p)
    (cons (region-beginning)
          (region-end))))
;; Use: (active-region-get)

(defun find-file-use-region (filename &optional wildcards)
  (interactive
   (let ((icicle-default-in-prompt-format-function (lambda (default) (format " (%s)" (faze default 'file)))))
     (find-file-read-args (if (region-active-p)
                              "Find file (possibly from region): "
                            "Find file: ")
                          (confirm-nonexistent-file-or-buffer))))
  (let* ((reg (active-region-get))
         (move-it (and reg              ;or existing regular but empty file
                       (not buffer-read-only)
                       (or (not (file-exists-p filename)) ;if either new file
                           (file-regular-p filename)      ;or regular file
                           ))))
    (when move-it
      (when (y-or-n-p (format "Move active region containing %s... from buffer %s to file %s?"
                              (faze (let ((rs (region-string)))
                                         (substring rs 0 (min 32 (length rs))))
                                       'string)
                              (faze (buffer-name (current-buffer)) 'buffer)
                              (faze filename 'file)))
        (kill-region (car reg) (cdr reg))))
    (find-file filename wildcards)
    (when move-it
      (yank)
      (message (format "Moved region from buffer %s to file %s"
                       (faze (buffer-name (current-buffer)) 'buffer)
                       (faze filename 'file))))))
(global-set-key [(control ?x) (control ?f)] 'find-file-use-region)

;; (defvar find-file-region nil
;;   "Activate region prior to call to find-file.")

;; ;;; TODO: Modify prompt
;; (defun find-file-log-region ()
;;   (setq find-file-region ))
;; (defadvice find-file (before log-active-region activate compile) (find-file-log-region))
;; (ad-deactivate 'find-file)

;; (defun region-to-file ()
;;   )
;; (add-hook 'find-file-hook 'region-to-file)

(provide 'file-use-region)
