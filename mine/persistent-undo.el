;;; persistent-undo.el --- Persistent Undo.
;; TODO Merge with undohist.el
;; TODO Store along with file-checksum to prevent errors.

(defvar handling-undo-saving nil)

(defun buffer-undo-symbol ()
  "Undo Symbol to save and load."
  (if (and (boundp 'undo-tree-mode)
           undo-tree-mode
           (boundp 'buffer-undo-tree))
      'buffer-undo-tree
    'buffer-undo-list))

(defun save-undo-filename (filename undo-symbol)
  "Given a filename FILENAME return the file name in which to save its undo list."
  (let ((undofile (concat "."
                          (file-name-nondirectory filename)
                          "."
                          (if (eq undo-symbol 'buffer-undo-tree)
                              "undo-tree"
                            "undo-list")))
        (dir (or (expand-file-name ".undos")
                 (file-name-directory filename))))
    (make-directory dir t)
    (expand-file-name undofile dir)))
;; (save-undo-filename buffer-file-name (buffer-undo-symbol))

(defun save-undo ()
  "Save the undo list to a file."
  (interactive)
  (let* ((sym (buffer-undo-symbol))
         (val (symbol-value sym)))
    (when val                           ;only non-empty undo history
      (let* ((filename (save-undo-filename buffer-file-name sym))
             (buffer (find-file-noselect filename)))
        (with-current-buffer buffer
          (setq buffer-read-only nil)
          (erase-buffer)
          (let (print-level
                print-length)
            (print val buffer))
          (let ((write-file-functions (remove 'save-undo write-file-functions))) ;skip saving undo on undo
            (save-buffer))
          )
        (kill-buffer buffer)
        nil))))

(defun load-undo ()
  "Load the undo list if present."
  (when (and (not handling-undo-saving)
             (null buffer-undo-list)
             )
    (let* ((sym (buffer-undo-symbol))
           (filename (save-undo-filename buffer-file-name sym)))
      (when (file-exists-p filename)
        (let* ((handling-undo-saving t)
               (buffer (find-file-noselect filename))
               (val (read buffer))
               (kill-buffer buffer))
          (set sym val)
          (message "Loaded undo from file %s" (faze filename 'file)))))))

;;; TODO Remove bug generating error: save-undo: Apparently circular structure being printed
;; (add-hook 'write-file-functions 'save-undo)
;;(add-hook 'after-save-hook 'save-undo t)
;;(add-hook 'write-file-functions 'save-undo t)
;; (add-hook 'find-file-hook 'load-undo t)
;; (remove-hook 'find-file-hook 'load-undo)

(provide 'persistent-undo)
