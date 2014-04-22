;; Version Control (VC) ediff-revision automation
;; See: http://groups.google.se/group/gnu.emacs.help/browse_thread/thread/a9f811fbdcbe809a

(require 'power-utils)
(require 'faze)

;; (defun ediff-vc-hide-rev1buf ()
;;   (delete-window (get-buffer-window rev1buf)))
;; (add-hook ediff-quit-hook 'ediff-vc-hide-rev1buf)

(defun vc-ediff-current-buffer-with-head ()
  "Compare current buffer with its Version Control HEAD."
  (interactive)
  (let ((file buffer-file-name))
    (if (not file)
        (message "Buffer has no file to diff")
      (when (and (require 'ediff nil t)
                 (require 'vc nil t))
        (if (vc-up-to-date-p file)
            (message "No changes to %s since last commit" (faze file 'file))
          (vc-buffer-sync)
          (ediff-load-version-control)
          (if (vc-backend file)
              (ediff-vc-internal "" "") ;;TODO: Delete old buffer
            (message "File %s is not under version control" (faze file 'file))
            (ding)))
        ;; TODO: Set buffer background of head version to some passive color
        ;; (darkgrey for dark backgrounds).
        ))))
(defalias 'ediff-current-buffer-with-vc-head 'vc-ediff-current-buffer-with-head)
(defalias 'ediff-vc-head 'vc-ediff-current-buffer-with-head)

(define-key vc-prefix-map [?e] 'vc-ediff-current-buffer-with-head)
(fset 'vc-prefix-map vc-prefix-map)
;; (define-key vc-dir-mode-map [?E] 'vc-ediff-current-buffer-with-head)

(define-key vc-menu-map [vc-ediff-current-buffer-with-head]
  `(menu-item ,(purecopy "Ediff with head") vc-ediff-current-buffer-with-head
              :help ,(purecopy "Ediff buffer with its header version (if its differ")))
(fset 'vc-menu-map vc-menu-map)

(provide 'vc-ediff-head)
