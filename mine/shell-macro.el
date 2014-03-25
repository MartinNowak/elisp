;;; -*- lexical-binding: t; -*-
(require 'cl)

;;; See: http://nullprogram.com/blog/2012/09/21/
(defun make-shell-macro (program)
  (fset program
        (cons 'macro
              (lambda (&rest args)
                `(with-temp-buffer
                   (funcall #'call-process
                            ,(symbol-name program) nil t nil
                            ,@(mapcar #'prin1-to-string args))
                   (buffer-string))))))
(defun generate-all-shell-macros ()
  (let ((path (mapcan
               (lambda (dir)
                 (when (file-directory-p dir)
                   (directory-files dir)))
               (parse-colon-path (getenv "PATH")))))
    (dolist (program (remove-if (lambda (f) (member f '("." ".."))) path))
      (let ((symbol (intern program)))
        (unless (fboundp symbol)
          (make-shell-macro symbol))))))
;; Use: (generate-all-shell-macros)

(provide 'shell-macro)
