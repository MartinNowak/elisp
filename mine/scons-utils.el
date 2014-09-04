;;; scons-utils.el --- scons Utilities.
;; Author: Per Nordlöw

(require 'cscan)
(require 'filedb)

(defun sconstruct-targets (filename &optional regexp case-fold)
  "Scan FILENAME for scons style (SConstruct) targets matching REGEXP."
  (interactive (list (read-file-name-of-types "SConstruct: " 'SConstruct)))
  (let ((fn (expand-file-name filename))
        targets)
    (dolist (hit (cscan-file fn
                             (rx symbol-start
                                 (| "Program"
                                    "LibraryBuilder"
                                    "StaticLibrary"
                                    "SharedLibrary")
                                 (* space)
                                 "("
                                 (* space)
                                 (| "'" "\"")
                                 (group (+? any))
                                 (| "'" "\"")
                                 )
                             nil t case-fold nil t nil 'string))
      (setq targets (cons hit targets)))
    targets))
;; Use: (sconstruct-targets "~/justcxx/SConstruct")
;; Use: (call-interactively 'sconstruct-targets)

(defun directory-sconstruct-target-of-buffer (dir &optional source-file)
  (mapcar (lambda (file)
            (sconstruct-targets file (concat (file-name-sans-extension
                                             (file-name-sans-directory source-file)) ".*")))
          (directory-files-of-types dir 'SConstruct nil nil t)))
;; Use: (directory-files-of-types (expand-file-name "~/Work/MATLAB/EMD/EMDs/src") 'SConstruct nil nil t)
;; Use: (directory-sconstruct-target-of-buffer (expand-file-name "~/Work/MATLAB/EMD/EMDs/src") "emdc.cpp")

(provide 'scons-utils)
