;;; rename-dwim.el --- Renaming Enhancements.
;; Author: Per Nordlöw
;;
;; TODO: Add advice for `make-directory' and `rename-file'.
;; TODO: Specialize `rename-buffer-and-maybe-file' and
;; `delete-buffer-and-maybe-file' on `dired-mode' view.
;; TODO: VC-Variants
;; - Rename through VC.
;; - Rename through VC as *remove/delete* in <S_REPOS>... followed by *add* in repos <T_REPOS>.... Uses `vc-backend'
;; where VC may be better displayed as real name such SVN.

(require 'vc-hooks)
(require 'vc-roots)
(require 'filedb)
(require 'read-char-spec)
(require 'font-lock-extras)
(require 'power-utils)

;;; TODO: Somehow relate to fcache-advices?
;;; http://stackoverflow.com/questions/13492752/auto-updating-of-file-name-history-upon-renamings-deletions
(defun forget-file (file)
  (setq file-name-history (delete (abbreviate-file-name file) file-name-history)))
(defun remember-file (file &optional append)
  (add-to-list 'file-name-history (abbreviate-file-name file) append))
(defadvice rename-file (after rename-file-update-histories (file newname) activate)
  "Update file/directory histories upon rename of FILE."
  (when (member (abbreviate-file-name file) 'file-name-history)
    (forget-file file)
    (remember-file newname)))
(defadvice delete-file (after delete-file-update-histories (filename &optional trash) activate)
  "Update file/directory histories upon deletion of FILE."
  (forget-file filename))
(defadvice copy-file (after copy-file-update-histories (file newname) activate)
  "Update file/directory histories upon copy of FILE."
  (when (called-interactively-p 'any)
    (remember-file newname)))

(defun rename-file-dwim (old new)
  "Do What I Mean Rename File OLD to NEW."
  (let ((old-root (and (eq (vc-state old) 'up-to-date)
                       (file-under-vc-directory-p old)
                       ))
        (new-root (and (null (vc-state new))
                       (file-under-vc-directory-p new))))
    (if (and old-root
             new-root
             (string-equal (car old-root)
                           (car new-root)))
        (when (y-or-n-p (message "VC Rename file %s to %s through %s-root %s"
                                 (faze old 'file)
                                 (faze new 'file)
                                 (faze (cdr old-root) 'type)
                                 (faze (car old-root) 'dir)))
          (vc-rename-file old new))
      (rename-file old new 1)           ;one means to confirm overwrite
      (if (vc-backend old)
          (when (y-or-n-p (message "VC Remove file %s through %s-root %s" old
                                   (faze (cdr old-root) 'type)
                                   (faze (car old-root) 'dir)))
            (vc-delete-file old)))
      (if (vc-backend new)
          (when (y-or-n-p (message "VC Add file %s through %s-root %s" new
                                   (faze (cdr new-root) 'type)
                                   (faze (car new-root) 'dir)))
            (vc-register new))))))

;; TODO: Warn (when (and (downcase old) (downcase new))) are the same
;; and file system is case-insensitive.
(defun rename-file-everywhere (old new &optional prompt)
  "Do vc-rename-file() on OLD if OLD is under Version Control
otherwise default rename-file() on OLD."
  (when (or (not prompt)
            (y-or-n-p (message "Rename file %s to %s "
                               (faze old 'file)
                               (faze new 'file))))
    (rename-file-dwim old new)
    (let* ((bins (file-productions old))) ;corresponding byte-compiled file
      (dolist (bin bins)
        (let ((fbin (faze bin 'file)))
          (when (file-exists-p bin)
            (if (string-has-end new ".el")
                (progn ;this is safer since byte-compiled may contain reference to to original emacs-lisp file
                  (when (y-or-n-p (format "Delete corresponding Byte-Code file %s aswell?" fbin))
                    (delete-file bin))
                  (when (string-has-end new ".el")
                    (byte-compile-file new)))
              (let ((bc-new (concat (file-name-sans-extension new) "."
                                    (file-name-extension bin))))
                (case (read-char-spec (format "Rename/Delete/Skip/Quit corresponding Byte-Code/Object file %s"
                                              fbin)
                                      `((?r t ,(format "Rename %s to %s" fbin (faze bc-new 'file)))
                                        (?d nil ,(format "Delete %s" fbin))
                                        (?s nil ,(format "Leave %s unchanged" fbin))))
                  (?r (rename-file bin bc-new))
                  (?d (delete-file bin))
                  )
                ;; (when (y-or-n-p (format "Rename corresponding Byte-Code/Object file %s to %s?"
                ;;                         (faze bin 'file) (faze bc-new 'file)))
                ;;   (rename-file bin bc-new))
                )
              )))))))
;; (defadvice rename-file (after register-vc (file newname))
;;   (when (called-interactively-p 'any)
;;     (let ((file (file-name-nondirectory file))
;;           (newname (file-name-nondirectory newname)))
;;       )))
;; (ad-activate 'rename-file)

(defun delete-file-everywhere (filename &optional prompt)
  "Do vc-delete-file() on FILENAME if FILENAME is under Version Control
otherwise default delete-file() on OLD."
  (when (or (not prompt)
            (y-or-n-p (message "Delete file %s " (faze filename 'file))))
    (if (or (not (vc-backend filename)) ;if not under vc or
            (not (ignore-errors (vc-delete-file filename) t))) ;if vc-delete fails
        (when (file-exists-p filename)
          (delete-file filename)))
    (let ((bins (file-productions filename))) ;corresponding byte-compiled file
      (dolist (bin bins)
        (when (and (file-exists-p bin)
                   (y-or-n-p (format "Delete corresponding binary file %s aswell?"
                                     (faze bin 'file))))
          (delete-file bin))))))

;; Because Buffers are associated with file names and not files.
;; Changing the buffer name would break backup for instance, which (by
;; default) renames the file and then writes it again.
;; TODO: Merge with `rename-file-with-refs'
;; TODO: Add support renaming other file using `ff-find-other-file'.
(defun rename-buffer-and-maybe-file ()
  "Rename current buffer and if available its visiting file."
  (interactive)
  ;; (list (read-file-name
  ;;        "New name: " (file-name-directory filename) nil nil
  ;;        (file-name-nondirectory filename)))
  (let ((name (buffer-name))
        (filename (buffer-file-name))
        new-dir)
    (if filename
        (let ((newname
               (let ((icicle-default-in-prompt-format-function
                      (lambda (default) (format " (%s)" (faze default 'file)))))
                 (read-file-name "New file (or destination directory) name: "))))
          (when (file-directory-p newname)
            (setq new-dir newname
                  newname (expand-file-name
                           (file-name-nondirectory filename)
                           newname)))
          ;; we only have to bother that filename is unique
          (if (file-exists-p newname)
              (message "File %s already exists" (faze newname 'file))
            (rename-file-everywhere buffer-file-name newname) ;rename the file
            (if (get-buffer newname) ;we have to bother that buffer-name is unique aswell
                (message "Buffer %s already exists" (faze newname 'buffer))
              (rename-buffer newname)
              )
            (set-visited-file-name newname t t)
            (set-buffer-modified-p nil)
            (if new-dir
                (message "Moved %s into new directory %s"
                         (faze filename 'file)
                         (faze new-dir 'dir))
              (message "Renamed %s to %s"
                       (faze filename 'file)
                       (faze newname 'file)
                       ))
            ))
      (let ((newname (read-buffer "New buffer name: " (buffer-name))))
        (if (get-buffer newname) ;we have to bother that buffer-name is unique aswell
            (message "Buffer %s already exists" (faze newname 'buffer))
          (rename-buffer newname)
          )))
    ;; It's likely that the VC status at the new location is different from
    ;; the one at the old location.
    (vc-find-file-hook)))
(defalias 'rename-file-and-buffer 'rename-buffer-and-maybe-file)

;; TODO: Remove all references (in C/C++ #include-statements) similar to what
;; `delete-file-with-refs' by adding mode-local delete hooks.
;; TODO: Support deleting other file using `ff-find-other-file'.
(defun delete-buffer-and-maybe-file ()
  "Delete current buffer and if available its visiting file."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if filename
        (when (y-or-n-p (message "Kill buffer %s and delete its file %s "
                                 (faze name 'buffer)
                                 (faze filename 'file)))
          (delete-file-everywhere buffer-file-name t)
          (when (bufferp (get-buffer name))
            (kill-buffer name)))
      (when (bufferp (get-buffer name))
        (call-interactively 'kill-buffer name))))) ;revert to normal kill-buffer instead
(defalias 'delete-file-and-buffer 'delete-buffer-and-maybe-file)

(global-set-key [(control x) (control r)] 'rename-buffer-and-maybe-file) ;I newer use `set-goal-column'
(global-set-key [(control x) (control n)] 'find-file-read-only) ;I newer use `set-goal-column'
(global-set-key [(control x) (control d)] 'delete-buffer-and-maybe-file) ;I newer use `set-goal-column'

(define-key-after menu-bar-file-menu [rename-buffer-file]
  `(menu-item "Rename Buffer-File..." rename-buffer-and-maybe-file :help "Rename Buffer and its File if it exists")
  'write-file)
(define-key-after menu-bar-file-menu [delete-buffer-file]
  `(menu-item "Delete Buffer-File..." delete-buffer-and-maybe-file :help "Delete Buffer and its File if it exists")
  'rename-buffer-file)

(when (and (require 'cc-assist nil t)
           (fboundp 'update-c-c++-includes))

  (defadvice rename-file (after rename-file-update-c-c++-includes (file newname) activate)
    "Update C and C++ include statements upon rename of file."
    (when (called-interactively-p 'any) ;prevent save-file() triggering. TODO: Does this work!?
      (let ((file (file-name-nondirectory file))
            (newname (file-name-nondirectory newname)))
        (update-c-c++-includes file newname))))
  ;;(ad-activate 'rename-file)

  (defadvice dired-do-rename (after rename-update-c-includes activate)
    "Update C include statements upon rename of file."
    ;; TODO: Perform operation on all marked dired files and reuse rename-file() advice above.
    )
  ;;(ad-activate 'dired-do-rename))
  )

(provide 'rename-dwim)
