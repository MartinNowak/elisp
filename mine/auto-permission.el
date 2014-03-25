;;; file-utils.el --- Auto Query/set File Permissions.

(require 'file-utils)
(require 'filedb)
(require 'directory-has)

;; This is like `executable-make-buffer-file-executable-if-script-p' but with a
;; more general checking if a file is a script (`file-script-code-p').
(defun query-execution-permission-on-script-buffer-file (&optional filename)
  "Query for Setting Execution Permission on buffer-file-name."
  (interactive)
  (let ((filename (or filename (buffer-file-name)))) ;default filename to buffer name
    (when (and (not (file-under-directory-p filename "/tmp")) ;not temporary file
               (not (file-executable-p filename)) ;not (already) executable
               (file-script-code-p filename))     ;and script
      (when (y-or-n-p
             (format "Set execution permission on file %s (seems to be a Script) " filename))
        (file-make-executable filename)
        (when (and (eq (vc-backend (expand-file-name filename))
                       'SVN)
                   (y-or-n-p
                    (format "Set Subversion (svn) execution property on file %s " filename)))
          ;; \see http://stackoverflow.com/questions/5757293/proper-way-to-add-svnexecutable
          (start-process "emacs-svn-set-exec"
                         nil
                         "svn" "propset" "svn:executable"
                         filename))))))
;; Use: (query-execution-permission-on-script-buffer-file "~/bin/setup_all")
;; Use: (query-execution-permission-on-script-buffer-file "/tmp/foo.sh")

(provide 'auto-permission)
