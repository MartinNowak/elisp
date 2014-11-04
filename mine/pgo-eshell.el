;;; pgo-eshell.el ---
;; Author: Per Nordlöw

;;(require 'eshell-auto nil t)
(when (require 'eshell nil t)
  (global-set-key [(control c) (s)] 'eshell)
  (when nil
    (when (require 'em-joc nil t)         ;eshell extensions
      ))
  )

(when nil
  (defun eshell-fix-aliases-list ()
    ;; remove alias entries containing --color flag
    (mapc (lambda (x)
            (setcdr x (list (replace-regexp-in-string
                             "[[:space:]]+--color=?[[:word:]]*" " "
                             (cadr x)))))
          eshell-command-aliases-list))
  ;; Use: (eshell-read-aliases-list)
  (add-hook 'eshell-alias-load-hook 'eshell-fix-aliases-list)
  )
;; TODO Doesn't currently work.
;;(setq eshell-aliases-file "~/.emacs.d/eshell/alias")

;;; EshellNavigation

;;; DeepakGoel: In eshell, if you do not like to use eshell-rebind
;;; (eg. me), then C-a takes you to beginning of line. It would be
;;; nice if it took you to ‘just after prompt’ instead. The ‘official’
;;; way to do that is probably to add fields to eshell (which i don’t
;;; quite know how). Here though, is my function that does that and
;;; more.. it makes C-a intelligent. (bol-maybe-general-my is general
;;; enough to be used by other funcitons.)

(when nil
  (add-hook 'eshell-mode-hook (lambda ()
                                 (local-set-key (kbd "C-a")
                                                'eshell-bol-maybe-my)))

 ;;;###autoload
  (defun bol-maybe-general-my (prompt &optional alt-bol-fcn)
    ""
    (interactive)
    (if (and (string-match (concat "^" (regexp-quote prompt)
                                   " *$")
                           (buffer-substring-no-properties
                            (line-beginning-position)
                            (point)))
             (not (bolp)))
        (beginning-of-line)
      (if alt-bol-fcn
          (funcall alt-bol-fcn)
        (beginning-of-line)
        (search-forward-regexp prompt))))

 ;;;###autoload
  (defun eshell-bol-maybe-my ()
    ""
    (interactive)
    (bol-maybe-general-my (funcall eshell-prompt-function)))

  ;; Note that C-c C-a already does this in eshell as well as other
  ;; modes with a prompt. It is a standard Emacs convention.

  ;; Or you could use the more simple eshell-bol that is already
  ;; defined.
  (defun my-eshell-maybe-bol ()
    (interactive)
    (let ((p (point)))
      (eshell-bol)
      (if (= p (point))
          (beginning-of-line))))
  )

(provide 'pgo-eshell)
