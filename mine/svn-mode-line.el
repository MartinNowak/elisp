;;; svn-mode-line.el --- Subversion mode-line Enhancements
;; Author: Per Nordlöw
;; See also: https://stackoverflow.com/questions/25316133/subversion-branch-in-mode-line

(defun vc-svn-mode-line-string (&optional file)
  (let ((file (or file
                  (buffer-file-name))))
    (let* ((tag (vc-svn-branch-or-trunk-tag file))
           (rev (vc-svn-working-revision file)))
      (format "SVN:%s@%s"
              (propertize tag
                          'face
                          (if (string-equal tag "trunk")
                              'error
                            'warning))
              (propertize rev
                          'face
                          'font-lock-constant-face)))))

(defun vc-fancy-mode-line-string (&optional file)
  (let ((file (or file
                  (buffer-file-name))))
    (if (eq (vc-backend file) 'SVN)
        (vc-svn-mode-line-string file)
      vc-mode)))

(setcdr (assq 'vc-mode mode-line-format)
        ;;'(vc-mode)
        '((:eval (vc-fancy-mode-line-string)))
        )

(defun vc-svn-branch-or-trunk-tag (&optional filename)
  (let* ((filename (or filename
                       (buffer-file-name)))
         (url (vc-svn-repository-hostname (if (file-directory-p filename)
                                              filename
                                            (file-name-directory
                                             filename)))))
    (when url
      (cond ((string-match-p "/trunk" url)
             "trunk")
            ((string-match "/branches/\\([^/]+\\)" url)
             (match-string 1 url))
            (t
             nil)))))
;; Use: (vc-svn-branch-or-trunk-tag)

(provide 'svn-mode-line)
