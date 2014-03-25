;;; file-xattr.el --- File Extended Attributes.
;; Author: Per Nordlöw
;;; TODO: Use `set-file-extended-attributes' and `file-extended-attributes' when present.
;;; TODO: Extend to sets of filenames to parallelize shell command
;;; TODO: Parse attributes into lists of cons cells
;;; TODO: Write C versions using `[sg]etxattr', `l[sg]etxattr' `f[sg]etxattr'. Reuse `file-attributes'.

(provide 'file-xattr)

(defun file-set-extended-attribute (filename name value &optional no-dereference)
  "Set FILENAME's extended extended-attributeibute user.NAME to VALUE.
Return non-nil on success, nil otherwise."
  (let ((default-directory (or (file-name-directory filename)
                               default-directory))
        (local-filename (file-name-nondirectory filename)))
    (when (file-writable-p local-filename)
      (shell-command-to-string (concat "setfattr"
                                       " -n " "user." name
                                       " -v " value
                                       (when no-dereference " -h")
                                       " " local-filename)))))
(defalias 'file-set-xattr 'file-set-extended-attribute)
;; Use: (file-set-extended-attribute "~/.bashrc" "owner" "per")
;; Use: (file-get-extended-attribute "~/.bashrc" "owner")
;; Use: (file-set-extended-attribute "~/.bashrc" "owner" "perry")
;; Use: (file-set-extended-attribute "/etc/passwd" "owner" "per")

(defun file-get-extended-attribute (filename &optional name namespace no-dereference)
  "Get FILENAME's extended extended-attributeibute user.NAME.
If NAME is nil return all attributes in default .user namespace.
If NAMESPACE pattern is t all namespaces \"-\" are shown, if nil only
.user namespace is shown."
  (let ((default-directory (or (file-name-directory filename)
                               default-directory))
        (local-filename (file-name-nondirectory filename)))
    (when (file-readable-p local-filename)
      (let ((regexp (eval `(rx "user." ,name "=\"" (group (* any)) "\"")))
            (cmd (shell-command-to-string (concat "getfattr"
                                                  (cond ((eq namespace t) " -m -"))
                                                  (if name
                                                      (concat " -n " "user." name)
                                                    " -d")
                                                  (when no-dereference " -h")
                                                  " " local-filename))))
        ;; (message "regexp: %s" regexp)
        ;; (message "cmd: %s" cmd)
        (when (string-match regexp cmd)
          (substring cmd
                     (match-beginning 1)
                     (match-end 1)))))))
(defalias 'file-get-xattr 'file-get-extended-attribute)
;; Use: (file-get-extended-attribute "~/.bashrc" "owner")
;; Use: (file-get-extended-attribute "~/.bashrc" "ownerf")
;; Use: (file-get-extended-attribute "~/.bashrc")
;; Use: (file-get-extended-attribute "~/.bashrc" nil t)
;; Use: (file-get-extended-attribute "~/.bashrc" nil t t)
;; Use: (file-get-extended-attribute "~/.emacs.d" nil t)
;; Use: (file-get-extended-attribute "~/.emacs" nil t t)

;; Use: (file-set-extended-attribute "/data/skovde0705/beskrivning_passager.doc" "owner" "per")
;; Use: (file-get-extended-attribute "/data/skovde0705/beskrivning_passager.doc" "owner")
