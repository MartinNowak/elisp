;;; path-utils.el --- Path operations.

(defun append-to-load-path (dir)
  "Append DIR to the list variable 'load-path only if it exist."
  (if (file-directory-p dir)
      (add-to-list 'load-path (directory-file-name dir) t)
    (warn "Load-path %s does not exist" dir)))

(defun prepend-to-load-path (dir)
  "Prepend DIR to the list variable 'load-path only if it exist."
  (if (file-directory-p dir)
      (add-to-list 'load-path (directory-file-name dir) nil)
    (warn "Load-path %s does not exist" dir)))

(defun append-to-exec-path (dir)
  "Append DIR to the list variable 'exec-path only if it exist."
  (if (file-directory-p dir)
    (add-to-list 'exec-path (directory-file-name dir) t)
    (warn "Exec-path %s does not exist" dir)))
;; Use: (delete (elsub "mine") load-path)

(defun prepend-to-exec-path (dir &optional move)
  "Prepend DIR to the list variable 'exec-path only if it exist."
  (when move
    (setq exec-path (remove dir exec-path)))
  (if (file-directory-p dir)
      (add-to-list 'exec-path (directory-file-name dir) nil)
    (warn "Exec-path %s does not exist" dir)))

(defun add-to-PATH (path-element &optional path-variable)
  "Add the specified path element to the Emacs PATH variable."
  (interactive "DEnter directory to be added to path: ")
  (let ((var (or path-variable "PATH")))
    (when (file-directory-p path-element)
      (setenv var
              (concat (expand-file-name path-element)
                      path-separator (getenv var))))))

(defun trim-string (string &optional chars)
  "Remove white spaces in beginning and ending of STRING.
White space here is any of: space, tab, emacs newline (line feed, ASCII 10)."
  (replace-regexp-in-string "\\`[[:space:]]*"
                            "" (replace-regexp-in-string "[[:space:]]*\\'" "" string)))
;;; Use: (trim-string "   /a/b:/c  ")
(defalias 'trim 'trim-string)
;;; Use: (trim "   /a/b:/c  ")
(defun uniquify-environment-path-string (env-string &optional separator)
  "Remove duplicates from ENVIRONMENT-STRING.
SEPARATOR default \":\""
  (when env-string
    (let ((separator (or separator ":")))
      (mapconcat 'identity
                 (delete ""
                         (delete-dups
                          (mapcar
                           'trim-string
                           (split-string env-string separator)))) separator))))
;; Use: (uniquify-environment-path-string " /a : /b : c : ")
(eval-when-compile
  (when (require 'elk-test nil t)
    (assert-equal "/x:/y:/z"
                  (uniquify-environment-path-string
                   "   :  /x  :  /y :  /x : /y : /z  : "))))
(defun uniquify-environment-variable (env-var)
  (let ((value (getenv env-var)))
    (when value
      (setenv env-var (uniquify-environment-path-string (getenv env-var))))))
;; (uniquify-environment-variable "PYTHONPATH")
;; (getenv "PYTHONPATH")
;; (getenv "PATH") (uniquify-environment-variable "PATH")

(provide 'path-utils)
