;;; makefile-utils.el --- make Utilities.

(require 'cscan)
(require 'filedb)

(defun makefile-targets (filename &optional regexp)
  "Scan FILENAME for Make style targets matching REGEXP."
  (interactive (list (read-file-name-of-types "Makefile: " 'Makefile)))
  (let ((fn (expand-file-name filename))
        targets)
    (dolist (hit (cscan-file fn
                             (concat "^\\("
                                     (or regexp
                                         "[^[:space:]\n]*")
                                     "\\)"
                                     (rx (* space))
                                     ":")
                             nil t t nil t nil 'string))
      (unless (or (string-equal hit ".PHONY")
                  (string-equal (substring hit 0 1) "$"))
        (setq targets (cons hit targets))))
    targets))
;; Use: (makefile-targets "~/justcxx/GNUmakefile")
;; Use: (call-interactively 'makefile-targets)
;; Use: (makefile-targets "~/Work/phobos/Makefile")

(defun directory-makefile-target-of-buffer (dir &optional source-file)
  (mapcar (lambda (file)
            (makefile-targets file (concat (file-name-sans-extension
                                            (file-name-sans-directory source-file)) ".*")))
          (directory-files-of-types dir 'Makefile nil nil t)))
;; Use: (directory-files-of-types (expand-file-name "~/Work/MATLAB/EMD/EMDs/src") 'Makefile nil nil t)
;; Use: (directory-makefile-target-of-buffer (expand-file-name "~/Work/MATLAB/EMD/EMDs/src") "emdc.cpp")

(provide 'makefile-utils)
