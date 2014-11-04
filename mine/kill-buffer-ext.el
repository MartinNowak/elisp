;;; kill-buffer-ext.el --- Kill Buffers Extensions.
;; Author: Per Nordlöw

(fmakunbound 'kill-buffer-and-its-windows)

;; see: http://www.emacswiki.org/emacs/KillingBuffers#toc2
(defun kill-other-standard-buffers ()
  "Kill all other buffers that the current.
A standard buffer is a buffer whose name doesn't begin with a
space."
  (interactive)
  (mapc
   (lambda (buffer)
     (unless (eq (aref (buffer-name buffer) 0) ?\ ) ;unless it starts with a space
       (kill-buffer buffer)))
   (delq (current-buffer) (buffer-list)))
  (message "Killed all other standard buffers"))
(defalias 'kill-all-buffers-except-current 'kill-other-standard-buffers)
(global-set-key [(control x) (K)] 'kill-other-standard-buffers)

(defun kill-buffers-by-regexp (regex)
  "Kill all buffers whose name is matched by REGEXP."
  (interactive "sBuffer Name Regexp: ")
  (let ((killed-names))
    (dolist (buffer (buffer-list))
      (let ((name (buffer-name buffer))
            (file-name (buffer-file-name buffer)))
        (when (string-match regex name)
          (kill-buffer name)
          (setq killed-names (cons (faze name 'buffer)
                                   killed-names))
          )))
    (message "Killed buffers%s" (mapconcat 'identity killed-names ", "))))
(global-set-key [(control x) (meta k)] 'kill-buffers-by-regexp)

(when nil
  (defun kill-other-buffers-alt ()
    "Kill all buffers except current buffer."
    (interactive)
    (let ((current-buf (current-buffer)))
      (dolist (buffer (buffer-list))
        (set-buffer buffer)
        (unless (eq current-buf buffer)
          (kill-buffer buffer))))))

;; see: http://www.emacswiki.org/emacs/KillingBuffers#toc3
(defun kill-all-dired-buffers()
  "Kill all dired buffers."
  (interactive)
  (save-excursion
    (let((count 0))
      (dolist(buffer (buffer-list))
        (set-buffer buffer)
        (when (equal major-mode 'dired-mode)
          (setq count (1+ count))
          (kill-buffer buffer)))
      (message "Killed %i dired buffer(s)." count ))))

;; ---------------------------------------------------------------------------

;; TODO Use ediff instead.
(defun diff-buffer-with-associated-file ()
  "View the differences between BUFFER and its associated file.
This requires the external program \"diff\" to be in your `exec-path'.
Returns nil if no differences found, 't otherwise."
  (interactive)
  (let ((buf-filename buffer-file-name)
        (buffer (current-buffer)))
    (unless buf-filename
      (error "Buffer %s has no associated file" buffer))
    (let ((diff-buf (get-buffer-create
                     (concat "*Assoc file diff: "
                             (buffer-name)
                             "*"))))
      (with-current-buffer diff-buf
        (setq buffer-read-only nil)
        (erase-buffer))
      (let ((tempfile (make-temp-file "buffer-to-file-diff-")))
        (unwind-protect
            (progn
              (with-current-buffer buffer
                (write-region (point-min) (point-max) tempfile nil 'nomessage))
              (if (zerop
                   (apply #'call-process "diff" nil diff-buf nil
                          (append
                           (when (and (boundp 'ediff-custom-diff-options)
                                      (stringp ediff-custom-diff-options))
                             (list ediff-custom-diff-options))
                           (list buf-filename tempfile))))
                  (progn
                    (message "No differences found")
                    nil)
                (progn
                  (with-current-buffer diff-buf
                    (goto-char (point-min))
                    (if (fboundp 'diff-mode)
                        (diff-mode)
                      (fundamental-mode)))
                  (display-buffer diff-buf)
                  t)))
          (when (file-exists-p tempfile)
            (delete-file tempfile)))))))
;; tidy up diffs when closing the file
(defun kill-associated-diff-buf ()
  (let ((buf (get-buffer (concat "*Assoc file diff: "
                                 (buffer-name)
                                 "*"))))
    (when (bufferp buf)
      (kill-buffer buf))))
(add-hook 'kill-buffer-hook 'kill-associated-diff-buf)
;;(global-set-key (kbd "C-c d") 'diff-buffer-with-associated-file)

(defun de-context-kill (arg)
  "Kill buffer, taking gnuclient into account."
  (interactive "p")
  (when (and (buffer-modified-p)
             buffer-file-name
             (not (string-match "\\*.*\\*" (buffer-name)))
             ;; erc buffers will be automatically saved
             (not (eq major-mode 'erc-mode))
             (= 1 arg))
    (let ((differences 't))
      (when (file-exists-p buffer-file-name)
        (setq differences (diff-buffer-with-associated-file)))
      (error (if differences
                 "Buffer has unsaved changes"
               "Buffer has unsaved changes, but no differences wrt. the file"))))
  (if (and (boundp 'gnuserv-minor-mode)
           gnuserv-minor-mode)
      (server-edit)
    (set-buffer-modified-p nil)
    (kill-buffer (current-buffer))))
;;(global-set-key (kbd "C-x k") 'de-context-kill)

;; ---------------------------------------------------------------------------

(provide 'kill-buffer-ext)
