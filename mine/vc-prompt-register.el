;;; vc-prompt-register.el --- Prompt to Register File in Version Control.
;; Author: Per Nordlöw

(require 'vc)
(require 'power-utils)
(require 'read-char-spec)
(require 'auto-permission)

(defconst prompt-vc-register-spec
  '((?r ?r "Register (Add) file in Version Control")
    (?i ?i "Ignore file in Version Control")
    (?q nil "Quit/Skip for now"))
  "`read-char-spec' SPECIFICATION.")
;; Use: (read-char-spec "Do on save" do-on-save-spec)

(defun prompt-vc-register-file (&optional file)
  "If FILE lies in a directory that is version controlled, then
prompt whether or not we should register it there."
  (unless file (setq file (buffer-file-name)))
  (let ((dirname (file-name-directory file))
        (basename (file-name-nondirectory file)))
    (when (and
           (not (and
                 (string-ends-with dirname ".git/")
                 (or
                  (string-equal basename
                                "git-rebase-todo"
                                )
                  (string-equal basename
                                "COMMIT_EDITMSG" ;don't check this for when Git commits files
                                ))))
           (file-under-vc-directory-p file))
      (case (vc-state file)
        ((unregistered nil)
         (case (read-char-spec (format (concat "Register or Ignore "
                                               (faze basename 'file)
                                               " in Version Controlled directory "
                                               (faze dirname 'dir)
                                               "? "))
                               prompt-vc-register-spec)
           (?r                          ;add
            (vc-register)
            )
           (?i                          ;ignore
            (cond ((eq (vc-backend-for-registration file) 'git)
                   (when (require 'git-emacs nil t)
                     (git-ignore file)))
                  (t
                   (message "TODO: Write and call `vc-ignore' and `vc-ignore-file'."))
                  ))
           (?q)
           ))))))
;; Use: (prompt-vc-register-file "~/cognia/.git/COMMIT_EDITMSG")
;; Use: (prompt-vc-register-file "~/cognia/vec2f.h")
;; Use: (prompt-vc-register-file "~/cognia/f.h")
;; Use: (prompt-vc-register-file "~/cognia/dummy.h")
(when (member (user-login-name) '("per" "pernord")) ;Not everyone wants this
  (add-hook 'after-save-hook 'prompt-vc-register-file t))
(add-hook 'after-save-hook 'query-execution-permission-on-script-buffer-file t)

(provide 'vc-prompt-register)
