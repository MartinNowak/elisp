;;; vc-mode-line.el --- VC mode-line Enhancements
;;; Author: Per Nordlöw
;;; See also: https://stackoverflow.com/questions/25316133/subversion-branch-in-mode-line
;;; Commentary:
;;; Code:

(defun file-changed (file))

(defun vc-backend-cached (file)
  "Cached version of `vc-backend' on FILE."
  ;; TODO: Detect changes using `file-notify-add-watch' ...
  (let ((watch (file-notify-add-watch file 'change 'file-changed)))
    (vc-backend file)))

(defun vc-svn-mode-line-string (&optional file)
  "Get Fancy SVN `mode-line-string' from FILE."
  (let ((file (or file
                  (buffer-file-name))))
    (let* ((tag (vc-svn-branch-or-trunk-tag file))
           (rev (vc-svn-working-revision file)))
      (format "%s:%s@%s"
              "SVN"
              tag
              (propertize rev 'face 'font-lock-constant-face)))))

(defun vc-fancy-mode-line-string (&optional file)
  "Get Fancy `mode-line-string' from FILE."
  (let ((file (or file
                  (buffer-file-name))))
    (if (eq (vc-backend file) 'SVN)
        (vc-svn-mode-line-string file)
      vc-mode)))

(setcdr (assq 'vc-mode mode-line-format)
        '(vc-mode)
        ;; TODO: Disabled until we have a implemented `vc-backend-cached'
        ;; '((:eval (vc-fancy-mode-line-string))) ;TODO: Use vc-mode
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
             (propertize "trunk" 'face 'error))
            ((string-match "/branches/\\([^/]+\\)" url)
             (propertize (match-string 1 url) 'face 'warning))
            (t
             nil)))))
;; Use: (vc-svn-branch-or-trunk-tag)

(provide 'vc-mode-line)
;;; vc-mode-line.el ends here
