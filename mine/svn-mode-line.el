;;; svn-mode-line.el --- Subversion mode-line Enhancements
;; Author: Per Nordlöw
;; See also: https://stackoverflow.com/questions/25316133/subversion-branch-in-mode-line

(defun lunaryorn-vc-mode-line ()
  (let ((backend (vc-backend (buffer-file-name))))
    (if (eq backend 'SVN)
        (let ((url (vc-svn-repository-hostname (buffer-file-name))))
          (cond
           ((string-match-p "/trunk/" url) "SVN-trunk")
           ((string-match "/branches/\\([^/]+\\)/" url)
            (concat "SVN-" (match-string 1 url)))
           (t vc-mode)))
      ;; Use default mode text for other backends
      vc-mode)))
;; Use: (lunaryorn-vc-mode-line)

(when nil
  (setq-default mode-line-format
                '(…
                  (vc-mode (" " :eval (lunaryorn-vc-mode-line)))
                  …)))

(provide 'svn-mode-line)
