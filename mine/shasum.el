;;; shasum.el --- Calculating SHA-checksums using extensions programs.

;; Generate a set of functions for calculating SHA Checksums using external programs.
(dolist (variant '("1" "224" "256" "384" "512")) ;SHA-variants
  (let ((cmd (concat "sha" variant "sum")))
    (when (executable-find cmd)
      (let ((fn (intern (concat "file-" cmd)))
            (fno (intern (concat "object-" cmd)))
            (fn-short (intern cmd)))
        (when (fboundp 'secure-hash)
          (eval `(defun ,fno (object &optional start end binary)
                   ,(concat "Return SHA-" (upcase variant) " hash of OBJECT, a buffer or string.")
                   (interactive "fObject to checksum: ")
                   (secure-hash (symbol-name ,fn) object start end binary)
                   ))
          )
        (eval `(defun ,fn (file)
                 ,(concat "Return FILE's " "SHA-" (upcase variant) " checksum (hash).")
                 (interactive "fFile to checksum: ")
                 (shell-command (concat ,cmd " " file)) ;TODO Use `start-process' instead.
                 ))
        (eval `(defalias ',fn-short ',fn))
        ))))

(provide 'shasum)
