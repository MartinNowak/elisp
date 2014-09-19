;;; vc-mode-line.el --- VC mode-line Enhancements
;;; Author: Per Nordlöw
;;; See also: https://stackoverflow.com/questions/25316133/subversion-branch-in-mode-line
;;; Commentary:
;;; Code:

(defun vc-svn-mode-line-string (&optional file)
  "Get Fancy SVN `mode-line-string' from FILE.
Maybe need to restart Emacs to make this be activated."
  (let* ((file (or file (buffer-file-name)))
         (tag (vc-svn-branch-or-trunk-tag file))
         (rev (vc-svn-working-revision file)))
    (format "%s:%s@%s" "SVN" tag (propertize rev 'face 'font-lock-constant-face))))

(defun vc-svn-branch-or-trunk-tag (&optional filename)
  (let* ((filename (or filename
                       (buffer-file-name)))
         (url (vc-svn-repository-hostname (if (file-directory-p filename)
                                              filename
                                            (file-name-directory
                                             filename)))))
    (when url
      (cond ((string-match-p "/trunk" url)
             (propertize "trunk"
                         'face 'error))
            ((string-match "/branches/\\([^/]+\\)" url)
             (propertize (match-string 1 url)
                         'face 'warning))
            (t
             (propertize (car (last (split-string url "/")))
                         'face 'error))))))
;; Use: (vc-svn-branch-or-trunk-tag)

;; OBS: Disabled because it suffices to define `vc-svn-mode-line-string' to make this work.
;; (defun vc-fancy-mode-line-string (&optional file)
;;   "Get Fancy `mode-line-string' from FILE."
;;   (let ((file (or file
;;                   (buffer-file-name))))
;;     (if (eq (vc-backend file) 'SVN)
;;         (vc-svn-mode-line-string file)
;;       vc-mode)))
;; (setcdr (assq 'vc-mode mode-line-format) '(vc-mode))

(provide 'vc-mode-line)
;;; vc-mode-line.el ends here
