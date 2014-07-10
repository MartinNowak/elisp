;;; trashcans.el --- Trashcans
;; Author: Per Nordlöw

(require 'trash-settings nil t)         ;TODO: integrate with `trash-settings'

(defvar local-trashcans nil
  "List of directories that contain local trashcans.")

(setq-default delete-by-moving-to-trash t
              trash-directory nil ;; "~/.emacs.d/trash"
              )
(defun log-trash (filename)
  (add-to-list 'local-trashcans
               (expand-file-name
                ".trash" (file-name-directory filename)))
  )
(defadvice move-file-to-trash (after log-trash (filename))
  (log-trash filename))
(ad-activate 'move-file-to-trash)

;;; TODO:
;; Trashes:
;; /a/.trash: Emptying [FILE...]...
;; /b/.trash: Trashing [FILE...]...
(defun list-local-trashcans ()
  "List all local trashcans."
  (interactive)
  (if local-trashcans
      (let ((buffer (get-buffer-create "*Trashcans*")))
        (with-current-buffer buffer
          (setq buffer-read-only nil)
          (erase-buffer)
          (mapc (lambda (can) (insert (faze can 'dir) "\n"))
                local-trashcans)
          (display-buffer buffer)
          (bob)
          (setq buffer-read-only t)))
    (message "No trashcans created yet")))
(global-set-key [(control x) (?T)] 'list-local-trashcans)

(defun empty-all-local-trashcans ()
  (setq local-trashcans
        (delq nil
              (mapcar (lambda (dir)
                        (when (file-directory-p dir)
                          (let ((subs (directory-files dir nil directory-files-no-dot-files-regexp t)))
                            (if (y-or-n-p (format "Empty trash at %s containing %s"
                                                  (faze dir 'dir)
                                                  (faze subs 'file)))
                                (progn (call-process-discard-output "rm" "-rf" dir)
                                       nil)
                              dir))))
                      local-trashcans))))
(defun empty-local-trashcans ()
  "Empty all local trashcans."
  (interactive)
  (if local-trashcans
      (empty-all-local-trashcans)
    (message "No trashcans need to be emptied")))

(global-set-key [(control x) (?E)] 'empty-local-trashcans)

(when (require 'desktop nil t)
  (add-to-list 'desktop-globals-to-save 'local-trashcans t))

(provide 'trashcans)
